module Errors
  class InvalidUrl < Base
    def message
      "Invalid target url: \"#{super}\""
    end
  end
end
