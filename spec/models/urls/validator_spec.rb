describe Urls::Validator do
  subject(:validator) { described_class.new(params) }

  describe '#validate' do
    subject(:validate) { validator.validate }

    let(:target_url) { 'http://domain.tld' }
    let(:params) { { target_url: target_url } }

    it { is_expected.to be_truthy }

    context 'when the target url is invalid' do
      [
        'ftp//domain.tld', 'httpx://domain.tld', 'http://123asfasgas~\\', nil
      ].each do |url|
        context "for the target url #{url}" do
          let(:target_url) { url }
          it "raises an error" do
            expect { validate }.to raise_error(
              Errors::InvalidUrl, "Invalid target url: \"#{target_url}\""
            )
          end
        end
      end
    end
  end
end
