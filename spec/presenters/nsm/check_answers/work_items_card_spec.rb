require 'rails_helper'

RSpec.describe Nsm::CheckAnswers::WorkItemsCard do
  subject { described_class.new(claim) }

  let(:claim) { build(:claim, :case_type_magistrates, :firm_details, work_items:) }
  let(:work_items) do
    [
      build(:work_item, :valid, work_type: WorkTypes::ADVOCACY.to_s, time_spent: 180),
      build(:work_item, :valid, work_type: WorkTypes::ADVOCACY.to_s, time_spent: 180),
      build(:work_item, :valid, work_type: WorkTypes::PREPARATION.to_s, time_spent: 120),
    ]
  end

  before { work_items.each { _1.claim = claim } }

  describe '#title' do
    it 'shows correct title' do
      expect(subject.title).to eq('Work items')
    end

    context 'when no work items' do
      let(:work_items) { [] }

      it 'shows title with the missing data tag' do
        expect(subject.title).to eq('Work items <strong class="govuk-tag govuk-tag--red">Incomplete</strong>')
      end
    end
  end

  describe '#row_data' do
    context 'when vat registered' do
      it 'generates work items rows' do
        expect(subject.row_data).to eq(
          [
            {
              head_key: 'items',
              text: '<strong>Total per item</strong>'
            },
            {
              head_opts: { text: 'Attendance without counsel' },
              text: '£0.00'
            },
            {
              head_opts: { text: 'Preparation' },
              text: '£104.30'
            },
            {
              head_opts: { text: 'Advocacy' },
              text: '£392.52'
            },
            {
              footer: true,
              head_key: 'total',
              text: '<strong>£496.82</strong>',
            },
            {
              head_key: 'total_inc_vat',
              text: '<strong>£596.18</strong>'
            }
          ]
        )
      end
    end

    context 'when not vat registered' do
      let(:claim) { build(:claim, :case_type_magistrates, :full_firm_details, work_items:) }

      it 'generates work items rows' do
        expect(subject.row_data).to eq(
          [
            {
              head_key: 'items',
              text: '<strong>Total per item</strong>'
            },
            {
              head_opts: { text: 'Attendance without counsel' },
              text: '£0.00'
            },
            {
              head_opts: { text: 'Preparation' },
              text: '£104.30'
            },
            {
              head_opts: { text: 'Advocacy' },
              text: '£392.52'
            },
            {
              footer: true,
              head_key: 'total',
              text: '<strong>£496.82</strong>',
            }
          ]
        )
      end

      it 'correctly formats the foot row' do
        expect(subject.rows).to include(
          {
            key: {
              text: 'Total'
            },
            value: {
              text: '<strong>£496.82</strong>'
            },
            classes: 'govuk-summary-list__row-double-border'
          }
        )
      end
    end
  end
end
