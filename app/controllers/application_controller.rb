class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery(with: :null_session)

  rescue_from(Errors::InvalidUrl) do |exception|
    handle_error(exception, :bad_request)
  end

  rescue_from(Errors::SlugNotFound) do |exception|
    handle_error(exception, :not_found)
  end

  rescue_from(Errors::SlugAlreadyTaken) do |exception|
    handle_error(exception, :conflict)
  end

  rescue_from(Errors::MaxAttemptToFindSlug) do |exception|
    handle_error(exception, :internal_server_error)
  end

  private

  def handle_error(exception, status)
    render(json: build_error_resource(exception.message), status: status)
  end

  def build_error_resource(message)
    { error: { message: message } }
  end
end
