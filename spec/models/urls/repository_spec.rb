describe Urls::Repository do
  subject(:repository) { described_class.new }

  let(:redis_pool) { Rails.configuration.redis_pool }

  after do
    redis_pool.with do |redis|
      keys = redis.keys('shortener:test:*')
      redis.del(keys) unless keys.blank?
    end
  end

  describe '#find' do
    subject(:find) { repository.find(slug) }

    let(:slug) { 'a-slug' }
    let(:target_url) { 'http://domain.tld' }
    let(:hex_slug) { slug.unpack('H*').first }
    let(:redis_key) { "shortener:test:url:#{hex_slug}:target_url" }

    context 'when there is a url' do
      before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }

      it { is_expected.to be_a(Url) }

      it '#target_url' do
        expect(find.target_url).to eq(target_url)
      end

      it '#slug' do
        expect(find.slug).to eq(slug)
      end
    end

    context 'when there isn\'t any url' do
      it 'raises an error' do
        expect { find }.to raise_error(Errors::SlugNotFound)
      end
    end
  end

  describe '#save' do
    subject(:save) { repository.save(target_url: target_url, slug: slug) }

    let(:target_url) { 'http://domain.tld' }
    let(:slug_counter_key) { 'shortener:test:url:nextslug' }
    let(:hex_slug) { slug.unpack('H*').first }
    let(:redis_key) { "shortener:test:url:#{hex_slug}:target_url" }
    let(:expected_hex_slug) { expected_slug.unpack('H*').first }
    let(:expected_redis_key) do
      "shortener:test:url:#{expected_hex_slug}:target_url"
    end

    let(:expected_target_url) do
      -> { redis_pool.with { |redis| redis.get(expected_redis_key) } }
    end

    context 'when no slug is passed' do
      let(:slug) { '' }
      let(:expected_slug) { '1' }

      it { is_expected.to be_a(Url) }

      it '#target_url' do
        expect(save.target_url).to eq(target_url)
      end

      it '#slug' do
        expect(save.slug).to eq(expected_slug)
      end

      it 'creates a slug' do
        expect { save }.to change(&expected_target_url).from(nil).to(target_url)
      end

      context 'and the generated slug already exists' do
        let(:hex_slug) { '1'.unpack('H*').first }
        let(:expected_slug) { '3' }

        before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }

        it { is_expected.to be_a(Url) }

        it '#target_url' do
          expect(save.target_url).to eq(target_url)
        end

        it '#slug' do
          expect(save.slug).to eq(expected_slug)
        end

        it 'creates a slug' do
          expect { save }.to change(&expected_target_url).
            from(nil).to(target_url)
        end
      end
    end

    context 'when a slug is passed' do
      let(:slug) { 'My Slug' }
      let(:hex_slug) { slug.parameterize.unpack('H*').first }
      let(:expected_slug) { slug.parameterize }

      it { is_expected.to be_a(Url) }

      it '#target_url' do
        expect(save.target_url).to eq(target_url)
      end

      it '#slug' do
        expect(save.slug).to eq(expected_slug)
      end

      it 'creates a slug' do
        expect { save }.to change(&expected_target_url).
          from(nil).to(target_url)
      end

      context 'and the slug already exists' do
        before { redis_pool.with { |redis| redis.set(redis_key, target_url) } }

        it 'raises an error' do
          expect { save }.to raise_error(Errors::SlugAlreadyTaken)
        end
      end
    end
  end
end
