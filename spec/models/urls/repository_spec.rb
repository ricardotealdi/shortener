describe Urls::Repository do
  subject(:repository) { described_class.new }

  let(:redis_pool) { Rails.configuration.redis_pool }

  after do
    redis_pool.with do |redis|
      keys = redis.keys('shortener:*')
      redis.del(keys) unless keys.blank?
    end
  end

  describe '#find' do
    subject(:find) { repository.find(slug) }

    let(:slug) { 'a-slug' }
    let(:target_url) { 'http://domain.tld' }
    let(:hex_slug) { slug.unpack('H*').first }
    let(:redis_key) { "shortener:url:#{hex_slug}:target_url" }

    context 'when there is a url' do
      before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }

      it { is_expected.to be_a(Url) }

      it '#target_url' do
        expect(find.target_url).to eq(target_url)
      end

      it '#target_url' do
        expect(find.slug).to eq(slug)
      end
    end

    context 'when there isn\'t any url' do
      it { is_expected.to be(nil) }
    end
  end

  describe '#save' do
    subject(:save) { repository.save(url) }

    let(:url) { Url.new(slug, target_url) }
    let(:target_url) { 'http://domain.tld' }
    let(:slug_counter_key) { 'shortener:url:nextslug' }
    let(:hex_slug) { slug.unpack('H*').first }
    let(:redis_key) { "shortener:url:#{hex_slug}:target_url" }
    let(:expected_hex_slug) { expected_slug.unpack('H*').first }
    let(:expected_redis_key) do
      "shortener:url:#{expected_hex_slug}:target_url"
    end

    let(:expected_target_url) do
      -> { redis_pool.with { |redis| redis.get(expected_redis_key) } }
    end

    context 'when no slug is passed' do
      let(:slug) { '' }
      let(:expected_slug) { '1' }

      it { is_expected.to be_truthy }

      it 'creates a slug' do
        expect { save }.to change(&expected_target_url).from(nil).to(target_url)
      end

      it 'changes the slug value in url' do
        expect { save }.to change { url.slug }.from(slug).to(expected_slug)
      end

      context 'and the generated slug already exists' do
        let(:hex_slug) { '1'.unpack('H*').first }
        let(:expected_slug) { '3' }

        before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }

        it { is_expected.to be_truthy }

        it 'creates a slug' do
          expect { save }.to change(&expected_target_url).
            from(nil).to(target_url)
        end

        it 'changes the slug value in url' do
          expect { save }.to change { url.slug }.from(slug).to(expected_slug)
        end
      end
    end

    context 'when a slug is passed' do
      let(:slug) { 'my-slug' }
      let(:expected_slug) { slug }

      it { is_expected.to be_truthy }

      it 'creates a slug' do
        expect { save }.to change(&expected_target_url).
          from(nil).to(target_url)
      end

      it 'does not change the slug value in url' do
        expect { save }.to_not change { url.slug }
      end

      context 'and the slug already exists' do
        before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }

        it { is_expected.to be_falsey }
      end
    end
  end
end
