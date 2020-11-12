# frozen_string_literal: true

module Anon
  class Rules
    def call(tables, method_type)
      return '' if tables.empty? || method_type.nil?

      query = tables.map do |table_name, fields|
        fields.map do |field_name, rules|
          next if rules['functions'].empty? || rules['ignore']

          method_name = "#{method_type}_comment"
          if method_type == 'drop'
            send(method_name.to_sym, "#{table_name}.#{field_name}")
          else
            send(method_name.to_sym, "#{table_name}.#{field_name}", rules['functions'])
          end
        end.compact.join("\n")
      end.delete_if(&:empty?).compact.join("\n")
      send("#{method_type}_query", query)
    end

    private

    # Obfuscation comments
    def static_comment(field, function)
      <<-SQL
        COMMENT ON COLUMN  #{field}
        IS 'MASKED WITH FUNCTION #{function} ';
      SQL
    end

    def dynamic_comment(field, function)
      <<-SQL
        SECURITY LABEL FOR anon ON COLUMN  #{field}
        IS 'MASKED WITH FUNCTION #{function} ';
      SQL
    end

    def test_comment(field, function)
      <<-SQL
        SECURITY LABEL FOR anon ON COLUMN  #{field}
        IS 'MASKED WITH FUNCTION #{function} ';
      SQL
    end

    def drop_comment(field)
      <<-SQL
        SECURITY LABEL FOR anon ON COLUMN  #{field} IS NULL;
      SQL
    end

    # Obfuscations queries
    def dynamic_query(query)
      <<-SQL
        CREATE EXTENSION IF NOT EXISTS anon CASCADE;
        SELECT anon.start_dynamic_masking();

        #{query}
      SQL
    end

    def static_query(query)
      <<-SQL
        CREATE EXTENSION IF NOT EXISTS anon CASCADE;
        SELECT anon.init();

        #{query}

        SELECT anon.anonymize_database();
      SQL
    end

    def drop_query(query)
      <<-SQL
        #{query}

        DROP EXTENSION IF EXISTS anon CASCADE;
        DROP SCHEMA mask CASCADE;
      SQL
    end

    # FIXME:  Table name and field to global obfuscation config
    def test_query(query)
      test_query = <<-SQL
        SECURITY LABEL FOR anon ON COLUMN  test_table_for_remove.name
        IS 'MASKED WITH FUNCTION anon.lorem_ipsum() ';

        SECURITY LABEL FOR anon ON COLUMN  test_table_for_remove.description
        IS 'MASKED WITH FUNCTION anon.lorem_ipsum() ';
      SQL
      [dynamic_query(query), test_query].join("\n")
    end
  end
end
