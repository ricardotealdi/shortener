Rails.application.routes.draw do
  get '/:slug', to: 'urls#show', as: :slug
end
