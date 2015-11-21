class UrlsController < ApplicationController
  def show
    slug = params.require(:slug).to_s.strip
    @url = repository.find(slug)

    @url ? head(status: 301, location: @url.target_url) : head(:not_found)
  end

  def create
    @url = repository.save(**create_params)
    if @url
      render(json: resource, status: 201, location: slug_location)
    else
      render(json: error_resource, status: 409)
    end
  end

  private

  def repository
    @repository ||= Urls::Repository.new
  end

  def resource
    @url.as_json.merge(self: slug_location)
  end

  def error_resource
    { error: { message: "#{create_params[:slug]} has already been taken" } }
  end

  def slug_location
    @slug_url ||= slug_url(@url.slug)
  end

  def create_params
    params.permit(:target_url, :slug).inject({}) do |acc, (k, v)|
      acc[k] = v.to_s.chomp
      acc
    end.symbolize_keys
  end
end
