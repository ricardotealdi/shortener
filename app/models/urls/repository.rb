module Urls
  class Repository
    SHORTENER_PREFIX = 'shortener:%s:url'.freeze
    SLUG_COUNTER_KEY = "#{SHORTENER_PREFIX}:nextslug".freeze
    URL_PREFIX = "#{SHORTENER_PREFIX}:%s".freeze
    TARGET_URL_KEY = "#{URL_PREFIX}:target_url".freeze
    RADIX = 35

    def initialize(
      connection_pool: Rails.configuration.redis_pool, env: Rails.env
    )
      @connection_pool = connection_pool
      @env = env
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

    attr_reader :connection_pool, :env

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
          slug = redis.incrby(slug_counter_key, increment).to_s(RADIX)
        end while redis.exists(target_url_key(slug))

        slug
      end
    end

    def save_target_url(slug, target_url)
      redis_connection do |redis|
        redis.setnx(target_url_key(slug), target_url)
      end
    end

    def slug_counter_key
      SLUG_COUNTER_KEY % env
    end

    def target_url_key(slug)
      TARGET_URL_KEY % [env, to_hex(slug)]
    end

    def redis_connection(&block)
      connection_pool.with(&block)
    end
  end
end
