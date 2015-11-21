Rails.application.routes.draw do
  post '/', to: 'urls#create'
  get '/:slug', to: 'urls#show', as: :slug
end
