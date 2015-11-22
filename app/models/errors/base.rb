module Errors
  class Base < StandardError
    attr_reader :message

    def initialize(message)
      @message = message.dup
    end
  end
end
