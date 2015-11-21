class UrlsController < ApplicationController
  def show
    slug = params.require(:slug).to_s.strip
    @url = repository.find(slug)

    @url ? head(status: 301, location: @url.target_url) : head(:not_found)
  end

  private

  def repository
    @repository ||= Urls::Repository.new
  end
end
