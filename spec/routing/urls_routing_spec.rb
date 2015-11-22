describe 'routes for Urls', type: :routing do
  it 'routes POST / to create action on UrlsController' do
    expect(post('/')).to route_to('urls#create')
  end

  it 'routes GET /:slug to show action on UrlsController' do
    expect(get('/foo')).to route_to(
      controller: 'urls', action: 'show', slug: 'foo'
    )
  end
end
