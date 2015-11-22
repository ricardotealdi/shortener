module Errors
  class MaxAttemptToFindSlug < Base
    def message
      "Max attempts reached to find available slug: #{super}"
    end
  end
end
