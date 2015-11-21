module Urls
  class Repository
    def initialize(connection_pool = Rails.configuration.redis_pool)
      @connection_pool = connection_pool
    end

    def find(slug)
      return nil unless target_url = fetch_target_url(slug)

      to_url(slug, target_url)
    end

    private

    attr_reader :connection_pool

    def to_hex(slug)
      slug.unpack('H*').first
    end

    def to_url(slug, target_url)
      Url.new(slug, target_url)
    end

    def fetch_target_url(slug)
      redis_connection { |redis| redis.get("url:#{to_hex(slug)}:target_url") }
    end

    def redis_connection(&block)
      connection_pool.with(&block)
    end
  end
end
