require 'rails_helper'

RSpec.describe Nsm::Steps::FurtherInformationForm do
  subject(:form) { described_class.new(arguments) }

  let(:arguments) do
    {
      application:,
      record:,
      information_supplied:
    }
  end

  let(:record) { instance_double(FurtherInformation) }

  describe '#validate' do
    let(:application) { instance_double(Claim) }

    context 'with information supplied' do
      let(:information_supplied) { 'some information' }

      it { is_expected.to be_valid }
    end

    context 'with blank information supplied' do
      let(:information_supplied) { '' }

      it 'has a validation error on the field' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:information_supplied, :blank)).to be(true)
        expect(form.errors.messages[:information_supplied]).to include('Enter the requested information')
      end
    end
  end

  describe '#save' do
    subject(:save) { form.save }

    context 'with valid information supplied' do
      let(:application) { create(:claim, :with_further_information_supplied) }
      let(:record) { application.further_informations.last }
      let(:information_supplied) { 'new info' }

      it 'persists the further information' do
        expect { save }
          .to change { application.reload.further_informations.last.information_supplied }
          .from('here is the extra information you requested')
          .to('new info')
      end
    end
  end

  describe '#explanation' do
    let(:application) { create(:claim, :with_further_information_supplied) }
    let(:record) { application.further_informations.last }
    let(:information_supplied) { 'new info' }

    it 'returns the explanation' do
      expect(form.explanation).to eq('please provide further evidence')
    end
  end
end
