module Urls
  class Repository
    def initialize(connection_pool = Rails.configuration.redis_pool)
      @connection_pool = connection_pool
    end

    def find(slug)
      target_url = fetch_target_url(slug)
      target_url && to_url(slug, target_url)
    end

    def save(url)
      url.slug = next_slug if url.slug.blank?

      save_target_url(url.slug, url.target_url)
    end

    private

    SHORTENER_PREFIX = 'shortener:url'.freeze
    SLUG_COUNTER_KEY = "#{SHORTENER_PREFIX}:nextslug".freeze
    URL_PREFIX = "#{SHORTENER_PREFIX}:%s".freeze
    TARGET_URL_KEY = "#{URL_PREFIX}:target_url".freeze
    RADIX = 35

    attr_reader :connection_pool

    def to_hex(slug)
      slug.to_s.unpack('H*').first
    end

    def to_url(slug, target_url)
      Url.new(slug, target_url)
    end

    def fetch_target_url(slug)
      redis_connection do |redis|
        redis.get(target_url_key(slug))
      end
    end

    def next_slug
      redis_connection do |redis|
        increment = 0
        begin
          increment += 1
          slug = redis.incrby(SLUG_COUNTER_KEY, increment).to_s(RADIX)
        end while redis.exists(target_url_key(slug))

        slug
      end
    end

    def save_target_url(slug, target_url)
      redis_connection do |redis|
        redis.setnx(target_url_key(slug), target_url)
      end
    end

    def target_url_key(slug)
      TARGET_URL_KEY % to_hex(slug)
    end

    def redis_connection(&block)
      connection_pool.with(&block)
    end
  end
end
