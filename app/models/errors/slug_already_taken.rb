module Errors
  class SlugAlreadyTaken < Base
    def message
      "Slug has already been taken: \"#{super}\""
    end
  end
end
