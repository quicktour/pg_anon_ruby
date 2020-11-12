# frozen_string_literal: true

module Anon
  class Settings
    def initialize(file_data, model_data)
      @file_data = file_data
      @model_data = model_data
    end

    def call
      serialize generated_settings_data
    end

    private

    attr_accessor :file_data, :model_data

    def generated_settings_data
      model_data.each_with_object({}) do |(k, v), hash|
        result = file_data[k].nil? ? v : v.merge(file_data[k])
        hash[k] = result
      end
    end

    def serialize(result)
      { 'tables' => result }
    end
  end
end
