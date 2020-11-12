# frozen_string_literal: true

require 'aws-sdk-s3'

module Anon
  class Storage
    attr_reader :bucket, :client

    def initialize
      @bucket = ENV.fetch('OBFUSCATION_BUCKET_NAME')
      @client = Aws::S3::Client.new(
        endpoint:          ENV.fetch('OBFUSCATION_ENDPOINT'),
        access_key_id:     ENV.fetch('AWS_ACCESS_KEY'),
        secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
        force_path_style:  true,
        region:            ENV.fetch('OBFUSCATION_REGION')
      )
    end

    def upload(filename)
      client.put_object(
        body:   File.open(filename),
        bucket: bucket,
        key:    File.basename(filename)
      )
    end

    def download
      filepath = "tmp/#{latest_key.key}"

      client.get_object(
        response_target: filepath,
        bucket:          bucket,
        key:             latest_key.key
      )
      filepath
    end

    private

    def latest_key
      @latest_key ||= client.list_objects_v2(
        bucket: bucket
      ).map(&:contents).flatten.last
    end
  end
end
