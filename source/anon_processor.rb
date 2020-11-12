# frozen_string_literal: true

module AnonProcessor
  IGNORED_TABLES = %w[ar_internal_metadata pg_search_documents schema_migrations].freeze
  PERMITED_TYPES = %w[text integer string decimal].freeze
  DUMP_COMMAND = { static: 'pg_dump', dynamic: 'pg_dump_anon' }.freeze
  SETTING_FILE = 'config/obfuscation.yml'

  # process with password
  def assign_password
    password = ENV.fetch('DUMP_PASSWORD') || SecureRandom.hex(8)
    logger_info "PASSWORD: #{password}"
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.record_timestamps = false
      User.find_each do |user|
        user.assign_attributes(password: password)
        user.skip_confirmation_notification!
        user.save(validate: false)
        user.confirm
      end
      ActiveRecord::Base.record_timestamps = true
    end
  end

  # process with dump
  def create_dump(type, filename)
    return unless DUMP_COMMAND.key?(type)

    exclude_dependencies = "-N mask"
    has_db_url = ENV.include? "BACKUP_DATABASE_URL"
    backup_db = has_db_url ? "-d #{ENV.fetch('BACKUP_DATABASE_URL')}" : ""
    cmd = "#{DUMP_COMMAND[type]} --file=#{filename} #{exclude_dependencies} #{backup_db}"
    system(cmd)
  end

  def restore_form_bucket
    return if Rails.env.production?

    filename = download_dump
    return if File.size(filename).zero?

    # Trunc tables before installing new ones.
    Anon::Cleaner.new.call
    restore_from_file(filename)
    filename
  end

  def restore_from_file(filename)
    return if Rails.env.production?

    db = ENV.fetch('POSTGRESQL_DATABASE')
    user = ENV.fetch('POSTGRESQL_USERNAME')
    password = ENV.fetch('POSTGRESQL_PASSWORD')
    host = ENV.fetch('POSTGRESQL_ADDRESS')
    cmd = "PGPASSWORD=#{password}; psql -d #{db} -U #{user} -h #{host} -f #{filename}"
    system(cmd)
    # Postgres extension bug, can fail to restore from first try.
    system(cmd)
  end

  def remove_dumps(filearray)
    filearray.each do |filename|
      File.delete(filename)
    end
  end

  # process with models
  # Create Postgres anonymizer plugin rules in the database comments.
  def load_comments(rules_type)
    file = YAML.load_file(SETTING_FILE)
    functions = Anon::Functions.new.call('create')
    rules = Anon::Rules.new.call(file['tables'], rules_type)

    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    ActiveRecord::Base.connection.execute(functions)
    ActiveRecord::Base.connection.execute(rules)
  end

  def remove_extention
    file = YAML.load_file(SETTING_FILE)
    rules = Anon::Rules.new.call(file['tables'], 'drop')
    functions = Anon::Functions.new.call('drop')

    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    ActiveRecord::Base.connection.execute(rules)
    ActiveRecord::Base.connection.execute(functions)
  end

  def check_models
    model_data = load_from_models
    file_data = YAML.load_file(SETTING_FILE)
    errors = Anon::Checker.new(model_data['tables'], file_data['tables']).call
    logger_info errors
  end

  # process settings
  def generate_setting
    model_data = load_from_models
    file_data = File.exist?(SETTING_FILE) ? YAML.load_file(SETTING_FILE) : {}
    data = Anon::Settings.new(file_data['tables'], model_data['tables']).call
    File.open(SETTING_FILE, 'w') { |file| YAML.dump(data, file) }
  end

  # process with s3
  def upload_dump(filename)
    Anon::Storage.new.upload(filename)
  end

  def download_dump
    Anon::Storage.new.download
  end

  private

  def load_from_models
    result = { 'tables' => {} }
    tables = ActiveRecord::Base.connection.tables.sort
    (tables - IGNORED_TABLES).each do |table_name|
      data = { table_name.to_s => {} }
      ActiveRecord::Base.connection.columns(table_name).each do |c|
        if PERMITED_TYPES.include?(c.type.to_s) && !id?(c.name.to_s)
          data[table_name][c.name.to_s] = { 'functions' => '', 'ignore' => false }
        end
      end
      result['tables'].merge!(data) unless data[table_name.to_s].empty?
    end
    result
  end

  def id?(field)
    field == 'id' || field.split('_').include?('id')
  end

  def logger_info(text)
    Rails.logger.info text
  end
end
