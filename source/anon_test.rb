# frozen_string_literal: true

# FIXME: Replase table name and field to global obfuscation config
module AnonTest
  def create_test_table
    query = <<-SQL
      CREATE TABLE IF NOT EXISTS test_table_for_remove (
        name varchar(255),
        description varchar(255)
      );
    SQL

    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    ActiveRecord::Base.connection.execute(query)
  end

  def remove_field
    query = <<-SQL
      ALTER TABLE test_table_for_remove DROP COLUMN IF EXISTS description;
    SQL

    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    ActiveRecord::Base.connection.execute(query)
  end

  def remove_table
    query = <<-SQL
      DROP TABLE IF EXISTS test_table_for_remove;
    SQL

    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    ActiveRecord::Base.connection.execute(query)
  end
end
