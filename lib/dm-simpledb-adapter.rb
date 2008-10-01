
module DataMapper
  module Adapters
    class SimpledbAdapter < AbstractAdapter
      def initialize(name, uri_or_options)
        super

        @aws_access_key = uri_or_options[:aws_access_key]
        @aws_secret_key = uri_or_options[:aws_secret_key]
        @http = Resourceful::HttpAccessor.new(:cache_manager => Resourceful::InMemoryCacheManager.new,
                                              :logger => Resourceful::StdOutLogger.new)
      end
    end
  end
end

