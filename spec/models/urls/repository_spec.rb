describe Urls::Repository do
  subject(:repository) { described_class.new }

  describe '#find' do
    subject(:find) { repository.find(slug) }

    let(:slug) { 'a-slug' }
    let(:target_url) { 'http://domain.tld' }
    let(:hex_slug) { slug.unpack('H*').first }
    let(:redis_key) { "url:#{hex_slug}:target_url" }
    let(:redis_pool) { Rails.configuration.redis_pool }

    context 'when there is a url' do
      before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }
      after { redis_pool.with { |redis| redis.del(redis_key) } }

      it { is_expected.to be_a(Url) }

      it '#target_url' do
        expect(find.target_url).to eq(target_url)
      end

      it '#target_url' do
        expect(find.slug).to eq(slug)
      end
    end
  end
end
