require 'rails_helper'

RSpec.describe Nsm::Steps::DisbursementCostForm do
  subject(:form) { described_class.new(arguments) }

  let(:arguments) do
    {
      application:,
      record:,
      miles:,
      total_cost_without_vat:,
      details:,
      prior_authority:,
      apply_vat:,
      add_another:,
    }
  end

  let(:application) do
    instance_double(Claim, work_items: disbursements, update!: true, date: Date.yesterday)
  end
  let(:disbursements) { [double(:disbursement), record] }
  let(:record) { double(:record, id: SecureRandom.uuid, disbursement_type: disbursement_type, vat_amount: vat_amount) }
  let(:disbursement_type) { DisbursementTypes.values.reject(&:other?).sample.to_s }
  let(:miles) { 10 }
  let(:total_cost_without_vat) { nil }
  let(:details) { 'Some text' }
  let(:prior_authority) { nil }
  let(:apply_vat) { 'false' }
  let(:vat_amount) { nil }
  let(:add_another) { YesNoAnswer::NO }

  describe '#validate' do
    context 'when disbursement_type is not other' do
      context 'and miles are blank' do
        let(:miles) { nil }

        it 'has an error' do
          expect(form).not_to be_valid
          expect(form.errors.of_kind?(:miles, :blank)).to be(true)
        end
      end

      context 'and details are blank' do
        let(:details) { nil }

        it 'has an error' do
          expect(form).not_to be_valid
          expect(form.errors.of_kind?(:details, :blank)).to be(true)
        end
      end

      context 'and prior_authority is blank' do
        let(:prior_authority) { nil }

        it { is_expected.to be_valid }
      end
    end

    context 'when disbursement_type is other' do
      let(:disbursement_type) { DisbursementTypes::OTHER.to_s }
      let(:prior_authority) { YesNoAnswer::YES }
      let(:total_cost_without_vat) { 10.0 }

      context 'and miles are blank' do
        let(:miles) { nil }

        it { is_expected.to be_valid }
      end

      context 'and details are blank' do
        let(:details) { nil }

        it 'has an error' do
          expect(form).not_to be_valid
          expect(form.errors.of_kind?(:details, :blank)).to be(true)
        end
      end

      context 'and prior_authority is blank' do
        let(:prior_authority) { nil }

        it 'has an error' do
          expect(form).not_to be_valid
          expect(form.errors.of_kind?(:prior_authority, :blank)).to be(true)
        end
      end

      context 'and total_cost_without_vat is blank' do
        let(:total_cost_without_vat) { nil }

        it 'has an error' do
          expect(form).not_to be_valid
          expect(form.errors.of_kind?(:total_cost_without_vat, :blank)).to be(true)
        end
      end
    end
  end

  describe '#apply_vat' do
    context 'when it is passed in' do
      context 'and is the true string' do
        let(:apply_vat) { 'true' }

        it { expect(form.apply_vat).to be(true) }
      end

      context 'and is the false string' do
        let(:apply_vat) { 'false' }

        it { expect(form.apply_vat).to be(false) }
      end
    end

    context 'when it is not passed in' do
      let(:apply_vat) { nil }

      context 'and a vat_amount exists on the record' do
        let(:vat_amount) { 10 }

        it { expect(form.apply_vat).to be(true) }
      end

      context 'and a vat_amount does not exist on the record' do
        let(:vat_amount) { nil }

        it { expect(form.apply_vat).to be(false) }
      end
    end
  end

  describe '#total_cost' do
    context 'when type is other' do
      let(:disbursement_type) { DisbursementTypes::OTHER.to_s }
      let(:total_cost_without_vat) { 150 }

      it 'is equal to total_cost_witout_vat' do
        expect(form.total_cost).to eq(150.0)
      end
    end

    context 'when type is not other' do
      let(:disbursement_type) { DisbursementTypes::BIKE.to_s }

      context 'when miles are nil' do
        let(:miles) { nil }

        it { expect(form.total_cost).to be_nil }
      end

      context 'when miles are not nil' do
        let(:miles) { 100 }

        it 'equal to miles times rate/mile' do
          expect(form.total_cost).to eq(25.0)
        end
      end
    end
  end

  describe '#vat' do
    context 'when there is not a pre-vat cost' do
      let(:disbursement_type) { DisbursementTypes::OTHER.to_s }
      let(:total_cost_without_vat) { nil }

      it 'returns a nil total cost' do
        expect(form.send(:vat)).to be_nil
      end
    end
  end

  describe '#save!' do
    let(:application) { create(:claim) }
    let(:record) { Disbursement.create!(disbursement_type: disbursement_type, claim: application) }
    let(:disbursement_type) { DisbursementTypes::CAR.to_s }

    context 'when disbursement_type is car' do
      let(:disbursement_type) { DisbursementTypes::CAR.to_s }

      it 'calculates and stores the total_cost_without_vat' do
        expect { form.save! }.to change { record.reload.attributes }
          .from(
            hash_including(
              'miles' => nil,
              'total_cost_without_vat' => nil,
              'vat_amount' => nil,
            )
          )
          .to(
            hash_including(
              'miles' => 10,
              'total_cost_without_vat' => 4.5,
              'vat_amount' => 0.0,
            )
          )
      end

      context 'when apply_vat is true' do
        let(:apply_vat) { 'true' }

        it 'calculates and stores the total_cost_without_vat and vat_amount' do
          expect { form.save! }.to change { record.reload.attributes }
            .from(
              hash_including(
                'miles' => nil,
                'total_cost_without_vat' => nil,
                'vat_amount' => nil,
              )
            )
            .to(
              hash_including(
                'miles' => 10,
                'total_cost_without_vat' => 4.5,
                'vat_amount' => 0.9,
              )
            )
        end

        context 'when vat_amount has a part penny' do
          let(:miles) { 11.5 }

          it 'calculates and stores the total_cost_without_vat and vat_amount rounded to the nearest penny' do
            expect { form.save! }.to change { record.reload.attributes }
              .from(
                hash_including(
                  'miles' => nil,
                  'total_cost_without_vat' => nil,
                  'vat_amount' => nil,
                )
              )
              .to(
                hash_including(
                  'miles' => 11.5,
                  'total_cost_without_vat' => 5.18,
                  'vat_amount' => 1.04,
                )
              )
          end
        end
      end
    end

    context 'when disbursement_type is other' do
      let(:disbursement_type) { DisbursementTypes::OTHER.to_s }
      let(:total_cost_without_vat) { 50 }

      it 'stores the total_cost_without_vat' do
        expect { form.save! }.to change { record.reload.attributes }
          .from(
            hash_including(
              'miles' => nil,
              'total_cost_without_vat' => nil,
              'vat_amount' => nil,
            )
          )
          .to(
            hash_including(
              'miles' => nil,
              'total_cost_without_vat' => 50.0,
              'vat_amount' => 0.0,
            )
          )
      end

      context 'when apply_vat is true' do
        let(:apply_vat) { 'true' }

        it 'stores the total_cost_without_vat and vat_amount' do
          expect { form.save! }.to change { record.reload.attributes }
            .from(
              hash_including(
                'miles' => nil,
                'total_cost_without_vat' => nil,
                'vat_amount' => nil,
              )
            )
            .to(
              hash_including(
                'miles' => nil,
                'total_cost_without_vat' => 50.0,
                'vat_amount' => 10.0,
              )
            )
        end
      end
    end

    context 'when a "mileage" disbursement type changed to other' do
      let(:application) { create(:claim) }
      let(:record) { Disbursement.create!(disbursement_type: disbursement_type, claim: application) }
      let(:disbursement_type) { DisbursementTypes::CAR.to_s }
      let(:miles) { 101 }
      let(:prior_authority) { nil }

      before do
        form.save!
        record.update!(disbursement_type: DisbursementTypes::OTHER.to_s)
      end

      it 'clears the miles value' do
        expect { form.save! }.to change { record.reload.attributes }
          .from(
            hash_including(
              'miles' => 101,
            )
          )
          .to(
            hash_including(
              'miles' => nil,
            )
          )
      end

      context 'when an "other" disbursement type changed to a "mileage" type' do
        let(:application) { create(:claim) }
        let(:record) { Disbursement.create!(disbursement_type: disbursement_type, claim: application) }
        let(:disbursement_type) { DisbursementTypes::OTHER.to_s }
        let(:miles) { nil }
        let(:prior_authority) { 'yes' }

        before do
          form.save!
          record.update!(disbursement_type: DisbursementTypes::CAR.to_s)
        end

        it 'clears the prior_authority value' do
          expect { form.save! }.to change { record.reload.attributes }
            .from(
              hash_including(
                'prior_authority' => 'yes',
              )
            )
            .to(
              hash_including(
                'prior_authority' => nil,
              )
            )
        end
      end
    end
  end
end
