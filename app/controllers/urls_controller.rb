class UrlsController < ApplicationController
  def show
    slug = params.require(:slug).to_s.strip

    url = repository.find(slug)

    head(status: 301, location: url.target_url)
  end

  def create
    @url = repository.save(**create_params)

    render(json: resource, status: 201, location: slug_location)
  end

  private

  def repository
    @repository ||= Urls::Repository.new
  end

  def resource
    @url.as_json.merge(self: slug_location)
  end

  def slug_location
    @slug_url ||= slug_url(@url.slug)
  end

  def create_params
    params.permit(:target_url, :slug).each_with_object({}) do |(key, val), hash|
      hash[key.to_sym] = val.to_s.chomp
    end
  end
end
