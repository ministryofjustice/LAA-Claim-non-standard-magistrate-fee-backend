require 'rails_helper'

RSpec.describe PriorAuthority::Steps::CheckAnswersForm do
  subject(:form) { described_class.new(arguments) }

  let(:arguments) do
    {
      application:,
      confirm_excluding_vat:,
      confirm_travel_expenditure:,
      commit_draft:
    }
  end

  describe '#validate' do
    let(:application) { instance_double(PriorAuthorityApplication) }
    let(:commit_draft) { nil }

    context 'with all confirmations accepted' do
      let(:confirm_excluding_vat) { 'true' }
      let(:confirm_travel_expenditure) { 'true' }

      it { is_expected.to be_valid }
    end

    context 'with confirm_excluding_vat not accepted' do
      let(:confirm_excluding_vat) { 'false' }
      let(:confirm_travel_expenditure) { 'true' }

      it 'has a validation error on the field' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:confirm_excluding_vat, :accepted)).to be(true)
        expect(form.errors.messages[:confirm_excluding_vat])
          .to include('Select if you confirm that all costs are exclusive of VAT')
      end
    end

    context 'with confirm_travel_expenditure not accepted' do
      let(:confirm_excluding_vat) { 'true' }
      let(:confirm_travel_expenditure) { 'false' }

      it 'has a validation error on the field' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:confirm_travel_expenditure, :accepted)).to be(true)
        expect(form.errors.messages[:confirm_travel_expenditure])
          .to include(
            'Select if you confirm that any travel expenditure (such as mileage, ' \
            'parking and travel fares) is included as additional items in the primary ' \
            'quote, and is not included as part of any hourly rate'
          )
      end
    end
  end

  describe '#save' do
    subject(:save) { form.save }

    let(:application) { create(:prior_authority_application, status: 'draft') }

    context 'when saving and coming back later (commit draft)' do
      let(:confirm_excluding_vat) { 'true' }
      let(:confirm_travel_expenditure) { 'true' }
      let(:commit_draft) { true }

      it 'does NOT persist the confirmations' do
        expect { save }.not_to change { application.reload.attributes }
          .from(
            hash_including(
              'confirm_excluding_vat' => nil,
              'confirm_travel_expenditure' => nil,
            )
          )
      end

      it 'does NOT update the status of the application' do
        expect { save }.not_to change(application, :status).from('draft')
      end

      it 'does NOT submit the application to the app store' do
        allow(SubmitToAppStore).to receive(:new)
        save
        expect(SubmitToAppStore).not_to have_received(:new)
      end
    end

    context 'when accepting and sending (not saving a draft)' do
      let(:confirm_excluding_vat) { 'true' }
      let(:confirm_travel_expenditure) { 'true' }
      let(:commit_draft) { nil }

      it 'persists the value' do
        expect { save }.to change { application.reload.attributes }
          .from(
            hash_including(
              'confirm_excluding_vat' => nil,
              'confirm_travel_expenditure' => nil,
            )
          )
          .to(
            hash_including(
              'confirm_excluding_vat' => true,
              'confirm_travel_expenditure' => true,
            )
          )
      end

      it 'updates the status of the application to submitted' do
        expect { save }.to change(application, :status).from('draft').to('submitted')
      end

      it 'submits the application to the appstore' do
        app_store_submitter = instance_double(SubmitToAppStore)
        allow(SubmitToAppStore).to receive(:new).and_return(app_store_submitter)
        allow(app_store_submitter).to receive(:process)
        save
        expect(app_store_submitter).to have_received(:process).with(submission: application)
      end

      context 'when update fails' do
        before do
          allow(application).to receive(:update!).and_raise(StandardError)
        end

        it 'does NOT submit the application to the app store' do
          allow(SubmitToAppStore).to receive(:new)
          save
        rescue StandardError
          expect(SubmitToAppStore).not_to have_received(:new)
        end
      end
    end

    context 'with unaccepted confirmations' do
      let(:confirm_excluding_vat) { false }
      let(:confirm_travel_expenditure) { false }
      let(:commit_draft) { nil }

      it 'does not persist the confirmations' do
        expect { save }.not_to change { application.reload.attributes }
          .from(
            hash_including(
              'confirm_excluding_vat' => nil,
              'confirm_travel_expenditure' => nil,
            )
          )
      end

      it 'does NOT update the status of the application' do
        expect { save }.not_to change(application, :status).from('draft')
      end

      it 'does NOT submit the application to the app store' do
        allow(SubmitToAppStore).to receive(:new)
        save
        expect(SubmitToAppStore).not_to have_received(:new)
      end
    end

    context 'with nil confirmations' do
      let(:confirm_excluding_vat) { nil }
      let(:confirm_travel_expenditure) { nil }
      let(:commit_draft) { nil }

      it 'does not persist the confirmations' do
        expect { save }.not_to change { application.reload.attributes }
          .from(
            hash_including(
              'confirm_excluding_vat' => nil,
              'confirm_travel_expenditure' => nil,
            )
          )
      end

      it 'does NOT update the status of the application' do
        expect { save }.not_to change(application, :status).from('draft')
      end
    end
  end
end
