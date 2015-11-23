class UrlsController < ApplicationController
  before_action(only: :create) { Urls::Validator.new(create_params).validate }

  ##
  # Redirects a shortened url to its target url
  #
  # GET /:slug
  #
  # @example
  #   $ GET http://localhost:3000/tealdi
  #
  #     # => HTTP/1.1 301 Moved Permanently
  #     # => Location: http://www.tealdi.com.br
  #
  def show
    slug = params.require(:slug).to_s.strip

    url = repository.find(slug)

    head(status: 301, location: url.target_url)
  end

  ##
  # Creates a new shortened url
  #
  # POST /
  #
  # params:
  #   target_url - (Required) This is the target url
  #   slug - You can provide your own slug to use as the path of the shortened
  #          url. (i.e: http://sho.rt/[slug]). If you don't provide any, it
  #          will be generated.
  #
  # @example
  #   $ POST http://localhost:3000/
  #     Content-Type: application/json
  #     {
  #       "target_url":"http://blog.tealdi.com.br"
  #     }
  #     # => HTTP/1.1 201 Created
  #     # => Location: http://localhost:3000/3b
  #     # => Content-Type: application/json; charset=utf-8
  #     # =>
  #     # => {
  #     # =>   "slug":"3b",
  #     # =>   "target_url":"http://blog.tealdi.com.br",
  #     # =>   "self":"http://localhost:3000/3b"
  #     # => }
  #
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
