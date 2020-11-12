# frozen_string_literal: true

module Anon
  class Checker
    def initialize(model_tables, setting_tables)
      @model_tables = model_tables
      @setting_tables = setting_tables
    end

    def call
      build_error_response({ tables:    check_tables_errors,
                             fields:    check_fields_errors,
                             functions: check_functions_errors })
    end

    private

    def check_tables_errors
      @model_tables.map do |table, _|
        "Table #{table} did not exist in settings" unless @setting_tables.include?(table)
      end.compact
    end

    def check_fields_errors
      @model_tables.map do |table, _|
        next unless @setting_tables[table]

        (@model_tables[table].keys - @setting_tables[table].keys).map do |field|
          "Field #{field} of table #{table} did not presented in settings"
        end
      end.flatten!.compact
    end

    def check_functions_errors
      @setting_tables.map do |table, fields|
        fields.map do |field, value|
          "Field #{field} of table #{table} no function presented" if function_empty?(value)
        end
      end.flatten!.compact
    end

    def build_error_response(errors_hash)
      result = {}
      errors_hash.each do |key, value|
        result[key] = value unless value.empty?
      end
      log_result result
    end

    def function_empty?(field)
      field['functions'].empty? && !field['ignore']
    end

    def log_result(result)
      error_text = result.map do |k, v|
        [
          "\n#{k.to_s.capitalize}",
          '--------------------',
          v.join("\n").to_s
        ]
      end.join("\n\n")

      error_text = 'All clear no errors was found' if result.empty?
      "\n #{error_text} \n\n"
    end
  end
end
