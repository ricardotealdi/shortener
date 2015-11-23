module Urls
  class Repository
    SHORTENER_PREFIX = 'shortener:url'.freeze
    SLUG_COUNTER_KEY = "#{SHORTENER_PREFIX}:nextslug".freeze
    URL_PREFIX = "#{SHORTENER_PREFIX}:%s".freeze
    TARGET_URL_KEY = "#{URL_PREFIX}:target_url".freeze
    RADIX = 16

    ##
    # Class initialization
    #
    # params:
    #   connection_pool - It's the redis connection pool. It needs to be a
    #                     connection pool instead of a normal connection,
    #                     because it's using a multi-thread app server
    #                     (puma), in other words, it's important not to share
    #                     connections between threads. The number of connections
    #                     in the pool should be the same or bigger than the
    #                     number of spawned threads of the app server, because
    #                     if you try to use more connections than are available,
    #                     the connection pool will block and wait for an
    #                     available connection from the pool and it may cause
    #                     queuing of some HTTP requests.
    #
    def initialize(
      connection_pool: Rails.configuration.redis_pool
    )
      @connection_pool = connection_pool
    end

    ##
    # Finds a target url
    #
    # params:
    #   slug - It's the "id" of the target url
    #
    # @return Url
    #
    def find(slug)
      target_url = fetch_target_url(slug)

      fail(Errors::SlugNotFound, slug) unless target_url

      to_url(slug, target_url)
    end

    ##
    # Saves a new shortened url
    #
    # params:
    #   target_url - Required. This is the target url.
    #   slug - It's the "id" of the target url
    #          (or the short version of target url).
    #          If provided, it will be used, otherwise it will be generated
    #          as an hex number based on the counter 'shortener:nextslug'
    #
    # @return Url
    #
    def save(target_url:, slug: nil)
      slug = slug.blank? ? next_slug : slug.parameterize

      unless save_target_url(slug, target_url)
        fail(Errors::SlugAlreadyTaken, slug)
      end

      to_url(slug, target_url)
    end

    private

    attr_reader :connection_pool

    def to_hex(slug)
      slug.to_s.unpack('H*').first
    end

    def to_url(slug, target_url)
      Url.new(slug, target_url)
    end

    def next_slug
      redis_connection(&method(:fetch_next_slug))
    end

    def fetch_target_url(slug)
      redis_connection do |redis|
        redis.get(target_url_key(slug))
      end
    end

    def fetch_next_slug(redis)
      slug = nil
      increment = 0

      loop do
        increment += 1

        fail(Errors::MaxAttemptToFindSlug, increment) if increment > 10

        slug = redis.incrby(SLUG_COUNTER_KEY, increment).to_s(RADIX)
        break unless redis.exists(target_url_key(slug))
      end

      slug
    end

    def save_target_url(slug, target_url)
      redis_connection do |redis|
        redis.setnx(target_url_key(slug), target_url)
      end
    end

    def target_url_key(slug)
      format(TARGET_URL_KEY, to_hex(slug))
    end

    def redis_connection(&block)
      connection_pool.with(&block)
    end
  end
end
