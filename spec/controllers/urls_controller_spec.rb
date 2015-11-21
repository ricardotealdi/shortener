describe UrlsController, type: :controller do
  render_views

  describe 'GET show' do
    subject(:show) { get(:show, slug: slug) }

    let(:repository) { instance_double(Urls::Repository, find: url) }
    let(:url) { Url.new(slug, target_url) }
    let(:target_url) { 'http://blog.tealdi.com.br' }
    let(:slug) { 'something' }

    before do
      allow(controller).to receive(:repository).and_return(repository)
    end

    it { expect(show).to have_http_status(301) }
    it { expect(show).to redirect_to(target_url) }
    it { expect(show.body).to eq('') }

    context 'when the url wasn\'t found for the given slug' do
      let(:url) { nil }

      it { expect(show).to have_http_status(404) }
      it { expect(show).to_not redirect_to(target_url) }
      it { expect(show.body).to eq('') }
    end
  end
end
