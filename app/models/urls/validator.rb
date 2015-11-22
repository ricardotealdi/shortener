module Urls
  class Validator
    def initialize(target_url: nil, **_params)
      @target_url = target_url.to_s.dup.freeze
    end

    def validate
      fail(Errors::InvalidUrl, target_url) if invalid_url?

      true
    end

    private

    attr_reader :target_url

    def invalid_url?
      !valid_url?
    end

    def valid_url?
      target_url =~ /^#{URI.regexp(%w(http https))}$/
    end
  end
end
