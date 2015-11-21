Rails.configuration.redis_pool = ConnectionPool.new(size: 16, timeout: 5) do
  Redis.new(
    url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'),
    logger: Rails.logger
  )
end
