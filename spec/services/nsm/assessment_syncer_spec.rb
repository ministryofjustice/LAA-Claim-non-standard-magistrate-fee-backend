require 'rails_helper'

RSpec.describe Nsm::AssessmentSyncer, :stub_oauth_token do
  describe '.call' do
    let(:claim) do
      create(:claim, :complete, state:)
    end

    let(:state) { 'granted' }

    let(:letters_and_calls) do
      [
        {
          type: {
            en: 'Letters',
              value: 'letters'
          },
          count: 1,
          uplift: 0,
        },
        {
          type: {
            en: 'Letters',
              value: 'calls'
          },
          count: 1,
          uplift: 0,
        }
      ]
    end

    let(:application) do
      {
        letters_and_calls: letters_and_calls,
        work_items: [],
        disbursements: []
      }
    end

    let(:record) do
      {
        application:,
      }.deep_stringify_keys
    end

    let(:arbitrary_fixed_date) { DateTime.new(2024, 2, 1, 15, 23, 27) }

    before do
      travel_to(arbitrary_fixed_date) do
        described_class.call(claim, record:)
      end
    end

    context 'when there is an error' do
      let(:state) { 'rejected' }

      before do
        allow(claim).to receive(:part_grant?).and_raise 'Some problem!'
        allow(Sentry).to receive(:capture_message)
        described_class.call(claim, record:)
      end

      it 'notifies Sentry' do
        expect(Sentry).to have_received(:capture_message)
      end
    end

    context 'when there is an assessment comment' do
      let(:state) { 'sent_back' }

      let(:record) do
        {
          'application' => application.merge('assessment_comment' => 'More info needed')
        }
      end

      it 'syncs the assessment comment' do
        expect(claim.assessment_comment).to eq 'More info needed'
      end
    end

    context 'when part granted with letters and calls adjusted' do
      let(:claim) do
        create(:claim, :complete, :letters_calls_uplift, state:)
      end

      let(:state) { 'part_grant' }

      let(:record) do
        {
          application: {
            letters_and_calls: [
              {
                type: {
                  en: 'Letters',
                    value: 'letters'
                },
                count: 1,
                uplift: 0,
                uplift_original: 10,
                count_original: 2,
                adjustment_comment: 'Reduced letters and removed uplift'
              },
              {
                type: {
                  en: 'Calls',
                    value: 'calls'
                },
                count: 2,
                uplift: 0,
                uplift_original: 20,
                count_original: 3,
                adjustment_comment: 'Reduced calls and removed uplift'
              }
            ],
            work_items: [],
            disbursements: []
          }
        }.deep_stringify_keys
      end

      it 'syncs letters adjustment fields' do
        expect(claim.allowed_letters).to eq 1
        expect(claim.letters).to eq 2
        expect(claim.letters_uplift).to eq 10
        expect(claim.allowed_letters_uplift).to eq 0
        expect(claim.letters_adjustment_comment).to eq 'Reduced letters and removed uplift'
      end

      it 'syncs calls adjustment fields' do
        expect(claim.allowed_calls).to eq 2
        expect(claim.calls).to eq 3
        expect(claim.allowed_calls_uplift).to eq 0
        expect(claim.calls_uplift).to eq 20
        expect(claim.calls_adjustment_comment).to eq 'Reduced calls and removed uplift'
      end

      context 'when type translations use simple string format' do
        let(:record) do
          {
            application: {
              letters_and_calls: [
                {
                  type: 'letters',
                  count: 1,
                  uplift: 0,
                  uplift_original: 10,
                  count_original: 2,
                  adjustment_comment: 'Reduced letters and removed uplift'
                },
                {
                  type: 'calls',
                  count: 2,
                  uplift: 0,
                  uplift_original: 20,
                  count_original: 3,
                  adjustment_comment: 'Reduced calls and removed uplift'
                }
              ],
              work_items: [],
              disbursements: []
            }
          }.deep_stringify_keys
        end

        it 'syncs letters adjustment fields' do
          expect(claim.allowed_letters).to eq 1
          expect(claim.letters).to eq 2
          expect(claim.letters_uplift).to eq 10
          expect(claim.allowed_letters_uplift).to eq 0
          expect(claim.letters_adjustment_comment).to eq 'Reduced letters and removed uplift'
        end
      end
    end

    context 'when part granted with work items adjusted' do
      let(:state) { 'part_grant' }
      let(:uplifted_work_item) { build(:work_item, :valid, :with_uplift) }
      let(:work_item) { build(:work_item, :valid) }
      let(:claim) do
        create(:claim, state: state, work_items: [uplifted_work_item, work_item])
      end

      let(:record) do
        {
          application: {
            letters_and_calls: letters_and_calls,
            work_items: [
              {
                id: uplifted_work_item.id,
                uplift: 0,
                time_spent: 20,
                uplift_original: 15,
                adjustment_comment: 'Changed work item',
                time_spent_original: 40,
                work_type: { en: 'Bananas', value: 'bananas' },
                work_type_original: { en: 'Pyjamas', value: 'pyjamas' },
              },
              {
                id: work_item.id,
                uplift: 0,
                time_spent: 120
              }
            ],
            disbursements: []
          },
        }.deep_stringify_keys
      end

      before do
        uplifted_work_item.reload
        work_item.reload
      end

      it 'syncs adjusted work item' do
        expect(uplifted_work_item.allowed_uplift).to eq 0
        expect(uplifted_work_item.adjustment_comment).to eq 'Changed work item'
        expect(uplifted_work_item.allowed_time_spent).to eq 20
        expect(uplifted_work_item.allowed_work_type).to eq 'bananas'
      end

      it 'does not sync non adjusted work item' do
        expect(work_item.allowed_time_spent).to be_nil
        expect(work_item.allowed_uplift).to be_nil
        expect(work_item.adjustment_comment).to be_nil
        expect(work_item.allowed_work_type).to be_nil
      end

      context 'when work type uses simple format' do
        let(:record) do
          {
            application: {
              letters_and_calls: letters_and_calls,
              work_items: [
                {
                  id: uplifted_work_item.id,
                  uplift: 0,
                  time_spent: 20,
                  uplift_original: 15,
                  adjustment_comment: 'Changed work item',
                  time_spent_original: 40,
                  work_type: 'bananas',
                  work_type_original: 'pyjamas',
                },
                {
                  id: work_item.id,
                  uplift: 0,
                  time_spent: 120
                }
              ],
              disbursements: []
            },
          }.deep_stringify_keys
        end

        it 'syncs adjusted work item' do
          expect(uplifted_work_item.allowed_uplift).to eq 0
          expect(uplifted_work_item.adjustment_comment).to eq 'Changed work item'
          expect(uplifted_work_item.allowed_time_spent).to eq 20
          expect(uplifted_work_item.allowed_work_type).to eq 'bananas'
        end
      end
    end

    context 'when part granted with disbursements adjusted' do
      let(:state) { 'part_grant' }
      let(:disbursement_with_vat) { build(:disbursement, :valid) }
      let(:disbursement_no_vat) { build(:disbursement, :no_vat) }
      let(:claim) do
        create(:claim, state: state, disbursements: [disbursement_with_vat, disbursement_no_vat])
      end

      let(:record) do
        {
          application: {
            letters_and_calls: letters_and_calls,
            work_items: [],
            disbursements: [
              {
                id: disbursement_with_vat.id,
                adjustment_comment: 'Removed disbursement',
                vat_amount: 0,
                vat_amount_original: 10,
                total_cost_without_vat: 0,
                total_cost_without_vat_original: 100,
                apply_vat: 'false',
                apply_vat_original: 'true',
                miles: 100,
                miles_original: 110
              },
              {
                id: disbursement_no_vat.id,
                vat_amount: 0,
                total_cost_without_vat: 10
              }
            ]
          }
        }.deep_stringify_keys
      end

      before do
        disbursement_with_vat.reload
        disbursement_no_vat.reload
      end

      it 'syncs adjusted disbursement' do
        expect(disbursement_with_vat).to have_attributes(
          allowed_vat_amount: 0,
          adjustment_comment: 'Removed disbursement',
          allowed_total_cost_without_vat: 0,
          allowed_miles: 100,
          allowed_apply_vat: 'false'
        )
      end

      it 'does not sync non adjusted disbursement' do
        expect(disbursement_no_vat).to have_attributes(
          allowed_vat_amount: nil,
          adjustment_comment: nil,
          allowed_total_cost_without_vat: nil,
          allowed_miles: nil,
          allowed_apply_vat: nil
        )
      end
    end

    context 'when granted with letters and calls adjusted' do
      let(:claim) do
        create(:claim, :complete, :letters_calls_uplift, state:)
      end

      let(:state) { 'granted' }

      let(:record) do
        {
          application: {
            letters_and_calls: [
              {
                type: {
                  en: 'Letters',
                    value: 'letters'
                },
                count: 3,
                count_original: 2,
                adjustment_comment: 'Increased letter count'
              },
              {
                type: {
                  en: 'Calls',
                    value: 'calls'
                },
                uplift: 40,
                uplift_original: 20,
                adjustment_comment: 'Increased call uplift'
              }
            ],
            work_items: [],
            disbursements: []
          }
        }.deep_stringify_keys
      end

      it 'syncs letters adjustment fields' do
        expect(claim.allowed_letters).to eq 3
        expect(claim.letters).to eq 2
        expect(claim.letters_adjustment_comment).to eq 'Increased letter count'
      end

      it 'syncs calls adjustment fields' do
        expect(claim.allowed_calls_uplift).to eq 40
        expect(claim.calls_uplift).to eq 20
        expect(claim.calls_adjustment_comment).to eq 'Increased call uplift'
      end
    end

    context 'when granted with work items adjusted' do
      let(:state) { 'granted' }

      let(:uplifted_work_item) { build(:work_item, :valid, :with_uplift) }
      let(:work_item) { build(:work_item, :valid) }

      let(:claim) do
        create(:claim, state: state, work_items: [uplifted_work_item, work_item])
      end

      let(:record) do
        {
          application: {
            letters_and_calls: letters_and_calls,
            work_items: [
              {
                id: uplifted_work_item.id,
                uplift: 20,
                time_spent: 60,
                uplift_original: 15,
                adjustment_comment: 'Changed work item',
                time_spent_original: 40,
                work_type: { en: 'Bananas', value: 'bananas' },
                work_type_original: { en: 'Pyjamas', value: 'pyjamas' },
              },
              {
                id: work_item.id,
                uplift: 0,
                time_spent: 120
              }
            ],
            disbursements: []
          },
        }.deep_stringify_keys
      end

      before do
        uplifted_work_item.reload
        work_item.reload
      end

      it 'syncs adjusted work item' do
        expect(uplifted_work_item.allowed_uplift).to eq 20
        expect(uplifted_work_item.adjustment_comment).to eq 'Changed work item'
        expect(uplifted_work_item.allowed_time_spent).to eq 60
        expect(uplifted_work_item.allowed_work_type).to eq 'bananas'
      end

      it 'does not sync non adjusted work item' do
        expect(work_item.allowed_time_spent).to be_nil
        expect(work_item.allowed_uplift).to be_nil
        expect(work_item.adjustment_comment).to be_nil
        expect(work_item.allowed_work_type).to be_nil
      end
    end

    context 'when granted with disbursements adjusted' do
      let(:state) { 'part_grant' }
      let(:disbursement_with_vat) { build(:disbursement, :valid) }
      let(:disbursement_no_vat) { build(:disbursement, :no_vat) }

      let(:claim) do
        create(:claim, state: state, disbursements: [disbursement_with_vat, disbursement_no_vat])
      end

      let(:record) do
        {
          application: {
            letters_and_calls: letters_and_calls,
            work_items: [],
            disbursements: [
              {
                id: disbursement_with_vat.id,
                adjustment_comment: 'Increased disbursement',
                vat_amount: 20,
                vat_amount_original: 10,
                total_cost_without_vat: 150,
                total_cost_without_vat_original: 100,
                apply_vat: 'true',
                apply_vat_original: 'true',
                miles: 130,
                miles_original: 110
              },
              {
                id: disbursement_no_vat.id,
                vat_amount: 0,
                total_cost_without_vat: 10
              }
            ]
          }
        }.deep_stringify_keys
      end

      before do
        disbursement_with_vat.reload
        disbursement_no_vat.reload
      end

      it 'syncs adjusted disbursement' do
        expect(disbursement_with_vat).to have_attributes(
          allowed_vat_amount: 20,
          adjustment_comment: 'Increased disbursement',
          allowed_total_cost_without_vat: 150,
          allowed_miles: 130,
          allowed_apply_vat: 'true'
        )
      end

      it 'does not sync non adjusted disbursement' do
        expect(disbursement_no_vat).to have_attributes(
          allowed_vat_amount: nil,
          adjustment_comment: nil,
          allowed_total_cost_without_vat: nil,
          allowed_miles: nil,
          allowed_apply_vat: nil
        )
      end
    end
  end
end
