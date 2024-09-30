require 'rails_helper'

RSpec.describe Nsm::Steps::SolicitorDeclarationForm do
  let(:form) { described_class.new(application:, **arguments) }

  let(:arguments) do
    {
      application:,
      signatory_name:,
    }
  end

  let(:application) { create(:claim, :complete, state: 'draft') }

  describe '#save the form' do
    before do
      allow(SubmitToAppStore).to receive(:perform_later)
      allow(application).to receive(:update!).and_return(true)
    end

    context 'when all fields are set' do
      let(:signatory_name) { 'John Doe' }

      it 'is valid' do
        expect(form.save).to be_truthy
        expect(application.state).to eq('submitted')
        expect(application).to have_received(:update!)
      end

      it 'notifies the app store' do
        form.save

        expect(SubmitToAppStore).to have_received(:perform_later).with(submission: application)
      end

      it 'updates submission to correct state' do
        form.save

        expect(application.state).to eq('submitted')
      end
    end

    context 'when rfi is available for pa and nsm' do
      let(:signatory_name) { 'John Doe' }
      let(:application) { create(:claim, :complete, state: 'sent_back') }

      before do
        allow(FeatureFlags).to receive(:nsm_rfi_loop).and_return(double(:new, enabled?: true))
        allow(SubmitToAppStore).to receive(:perform_later)
        allow(application).to receive(:update!).and_return(true)
      end

      it 'notifies the app store' do
        form.save

        expect(SubmitToAppStore).to have_received(:perform_later).with(submission: application)
      end

      it 'updates submission to correct state' do
        form.save

        expect(application.state).to eq('provider_updated')
      end
    end
  end

  describe 'form is #valid' do
    context 'when the field is set' do
      let(:signatory_name) { 'John Doe' }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    ['Jim Bob', "J'm Bob", "Jim B'b", 'J-m Bob', 'Jim B-b', 'Jim Bob Bob', 'Jim B.b', 'Jim B,b'].each do |name|
      context "it is a valid name string: #{name}" do
        let(:signatory_name) { name }

        it { expect(form).to be_valid }
      end
    end
  end

  describe 'form is #invalid' do
    context 'when the field is empty' do
      let(:signatory_name) { nil }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:signatory_name, :blank)).to be(true)
      end
    end

    ['Jim Bob!', 'Jim', 'Jim-Bob', 'jim@bob', 'jim the 1st'].each do |name|
      context "it is a invalid name string: #{name}" do
        let(:signatory_name) { name }

        it 'is invalid' do
          expect(form).not_to be_valid
          expect(form.errors.of_kind?(:signatory_name, :invalid)).to be(true)
        end
      end
    end
  end
end
