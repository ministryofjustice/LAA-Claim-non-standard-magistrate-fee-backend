require 'rails_helper'

RSpec.describe PriorAuthority::Tasks::CheckAnswers, type: :presenter do
  subject(:presenter) { described_class.new(application:) }

  let(:application) { build_stubbed(:prior_authority_application, :full) }

  describe '#path' do
    subject(:path) { presenter.path }

    it { is_expected.to eq("/prior-authority/applications/#{application.id}/steps/check_answers") }
  end

  describe '#not_applicable?' do
    it { is_expected.not_to be_not_applicable }
  end

  describe '#can_start?' do
    context 'when one or more previous task incomplete' do
      it { is_expected.not_to be_can_start }
    end

    context 'when all previous tasks completed' do
      let(:application) { create(:prior_authority_application, :with_all_tasks_completed) }

      it { is_expected.to be_can_start }
    end
  end

  describe '#completed?' do
    subject(:completed?) { presenter.completed? }

    context 'when application state is submitted' do
      before do
        allow(application).to receive(:submitted?).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'when application state is not submitted' do
      before do
        allow(application).to receive(:submitted?).and_return(false)
      end

      it { is_expected.to be false }
    end
  end
end
