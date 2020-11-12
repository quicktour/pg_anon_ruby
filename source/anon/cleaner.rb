# frozen_string_literal: true

module Anon
  class Cleaner
    def call
      query = collect_query.join("\n")
      ActiveRecord::Base.connection.execute build_transaction(query)
    end

    private

    def collect_query
      ActiveRecord::Base.connection.tables.map { |table| "TRUNCATE TABLE #{table} CASCADE;" }
    end

    def build_transaction(query)
      <<-SQL
        #{query}
      SQL
    end
  end
end
