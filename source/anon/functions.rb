# frozen_string_literal: true

module Anon
  class Functions
    FUNCTIONS_LIST = %i[divide_value_int divide_value_numeric fake_url_generator].freeze

    def call(method_type)
      send(method_type.to_sym)
    end

    private

    def create
      FUNCTIONS_LIST.map do |function|
        send(function.to_sym)
      end.join("\n")
    end

    def drop
      FUNCTIONS_LIST.map do |function|
        <<-SQL
          DROP FUNCTION IF EXISTS #{function};
        SQL
      end.join("\n")
    end

    def divide_value_int
      <<~SQL
        CREATE OR REPLACE FUNCTION divide_value_int(divisible integer, divisor integer)
        RETURNS integer
        VOLATILE
        AS $quotient$
        declare
          quotient integer;
        BEGIN
          SELECT CASE
            WHEN divisible > 0 THEN divisible / divisor
            ELSE 0 END into quotient;
          RETURN quotient;
        END
        $quotient$ LANGUAGE plpgsql;
      SQL
    end

    def divide_value_numeric
      <<~SQL
        CREATE OR REPLACE FUNCTION divide_value_numeric(divisible numeric, divisor numeric)
        RETURNS numeric
        VOLATILE
        AS $quotient$
        declare
          quotient numeric;
        BEGIN
          SELECT CASE
            WHEN divisible > 0 THEN divisible / divisor
            ELSE 0 END into quotient;
          RETURN quotient;
        END
        $quotient$ LANGUAGE plpgsql;
      SQL
    end

    def fake_url_generator
      <<~SQL
        CREATE OR REPLACE FUNCTION fake_url_generator()
        RETURNS text
        VOLATILE
        AS $fake_url$
        declare
          fake_url text;
        BEGIN
        SELECT concat_ws('.', url_name, domain_name) into fake_url
        FROM
        (
          SELECT string_agg(x,'')
          FROM (
            SELECT start_arr[ 1 + ( (random() * 25)::int) % 16 ]
            FROM
            (
              select '{co,ge,for,so,gim,se,co,ge,ca,fra,gec,ge,ga,fro,gip}'::text[] as start_arr
            ) syllarr,
            generate_series(1, 3)
          ) AS comp3syl(x)
        ) AS comp_url_name(url_name),
        (
          SELECT x[ 1 + ( (random() * 25)::int) % 14 ]
          FROM (
            select '{com,ro,ru,edu,gbp,ua,us,pl,blv,local,su,uk,org,lv,ml}'::text[]
        	) AS z2(x)
        ) AS comp_domain_name(domain_name);
        RETURN fake_url;
        END
        $fake_url$ LANGUAGE plpgsql;
      SQL
    end
  end
end
