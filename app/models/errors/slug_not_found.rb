module Errors
  class SlugNotFound < Base
    def message
      "Slug has not been found: \"#{super}\""
    end
  end
end
