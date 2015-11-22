module Errors
  class Base < StandardError
    attr_reader :message

    def initialize(message = nil)
      @message = message
    end
  end
end
