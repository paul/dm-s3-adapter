require 'libxml'

require 'dm-serializer'
require 'pp'

require File.dirname(__FILE__) + "/dm-simpledb-adapter/aws_authenticator"

module DataMapper
  module Adapters
    class SimpledbAdapter < AbstractAdapter
      def initialize(name, uri_or_options)
        super

        @aws_access_key = uri_or_options[:aws_access_key]
        @aws_secret_key = uri_or_options[:aws_secret_key]
        @aws_bucket     = uri_or_options[:aws_bucket]
        @aws_uri        = "http://#{@aws_bucket}.s3.amazonaws.com/"

        @http = Resourceful::HttpAccessor.new(:cache_manager => Resourceful::InMemoryCacheManager.new,
                                              :logger => Resourceful::StdOutLogger.new)
        @http.auth_manager.add_auth_handler(AwsAuthenticator.new(@aws_access_key, @aws_secret_key, @aws_bucket))
        @resources = {}

        create_bucket unless bucket_exists?
      end

      def create(resources)
        resources.each do |resource|
          repository = resource.repository
          model      = resource.model
          attributes = resource.dirty_attributes

          identity_field = model.key(repository.name).detect { |p| p.key? }

          path = "#{model.to_s.pluralize}/#{attributes[identity_field]}"

          @resources[path] ||= @http.resource(@aws_uri + path)

          puts resource.to_json

          resp = @resources[path].put(resource.to_json, 
                                      :content_type => 'application/json')

          pp resp
        end
      end

      def read_one(query)
        pp query

      end

      def list_buckets 
        resp = @http.resource('http://s3.amazonaws.com/').get
        doc = LibXML::XML::Parser.string(resp.body).parse
      end

      def bucket_exists?
        begin
          @http.resource(@aws_uri).head
          return true
        rescue Resourceful::UnsuccessfulHttpRequestError => e
          if e.http_response.code == 404
            return false
          else
            raise e
          end
        end
      end

      def create_bucket
        resp = @http.resource(@aws_uri).put("", :content_type => 'application/xml')
      end

    end
  end
end

