describe UrlsController, type: :controller do
  render_views

  let(:repository) { instance_double(Urls::Repository) }

  before do
    allow(Urls::Repository).to receive(:new).and_return(repository)
  end

  describe 'GET show' do
    subject(:show) { get(:show, slug: slug) }

    let(:url) { Url.new(slug, target_url) }
    let(:target_url) { 'http://blog.tealdi.com.br' }
    let(:slug) { 'something ' }

    before do
      allow(repository).to receive(:find).and_return(url)
    end

    it { is_expected.to have_http_status(301) }
    it { is_expected.to redirect_to(target_url) }
    it { expect(show.body).to eq('') }

    it do
      expect(repository).to receive(:find).with(slug.strip)

      show
    end

    context 'when the url wasn\'t found for the given slug' do
      let(:expected_json) do
        {
          error: {
            message: "Slug has not been found: \"#{slug}\""
          }
        }.to_json
      end

      before do
        allow(repository).to receive(:find).and_raise(
          Errors::SlugNotFound, slug
        )
      end

      it { expect(show).to have_http_status(404) }
      it { expect(show).to_not redirect_to(target_url) }
      it { expect(show.body).to eq(expected_json) }
    end
  end

  describe 'POST create' do
    subject(:create) { post(:create, params) }

    let(:url) { Url.new(slug, target_url) }
    let(:target_url) { 'http://blog.tealdi.com.br' }
    let(:slug) { 'slug' }
    let(:params) { { target_url: target_url } }
    let(:success) { true }
    let(:expected_url) { 'http://test.host/slug' }
    let(:expected_json) { url.as_json.merge(self: expected_url).to_json }

    before do
      allow(repository).to receive(:save).and_return(url)
    end

    it { is_expected.to have_http_status(:created) }
    it { expect(create.location).to eq(expected_url) }
    it { expect(create.body).to eq(expected_json) }

    context 'when the target url is not a valid url' do
      let(:target_url) { nil }
      let(:expected_json) do
        {
          error: {
            message: "Invalid target url: \"#{target_url}\""
          }
        }.to_json
      end

      it { is_expected.to have_http_status(400) }
      it { expect(create.body).to eq(expected_json) }
    end

    context 'when the max attempt of finding the next slug has been reached' do
      let(:expected_json) do
        {
          error: {
            message: 'Max attempts reached to find available slug: 10'
          }
        }.to_json
      end

      before do
        allow(repository).to receive(:save).and_raise(
          Errors::MaxAttemptToFindSlug, 10
        )
      end

      it { is_expected.to have_http_status(500) }
      it { expect(create.body).to eq(expected_json) }
    end

    context 'when a slug is sent' do
      let(:params) { { target_url: target_url, slug: slug } }

      it { is_expected.to have_http_status(:created) }
      it { expect(create.location).to eq(expected_url) }
      it { expect(create.body).to eq(expected_json) }

      context 'when the slug has already been taken' do
        let(:expected_json) do
          {
            error: {
              message: "Slug has already been taken: \"#{slug}\""
            }
          }.to_json
        end

        before do
          allow(repository).to receive(:save).and_raise(
            Errors::SlugAlreadyTaken, slug
          )
        end

        it { is_expected.to have_http_status(409) }
        it { expect(create.body).to eq(expected_json) }
      end
    end
  end
end
