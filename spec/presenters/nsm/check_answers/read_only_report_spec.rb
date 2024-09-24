# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Nsm::CheckAnswers::ReadOnlyReport do
  describe '#section_groups' do
    context 'not in a complete state' do
      subject { described_class.new(claim, cost_summary_in_overview:) }

      let(:claim) { build(:claim, :complete) }
      let(:cost_summary_in_overview) { true }

      context 'section groups' do
        it 'returns multiple groups' do
          expect(subject.section_groups).to be_an_instance_of Array
          expect(subject.section_groups.count).to eq 8
        end

        context 'when status section_group name is passed in' do
          it 'returns multiple groups' do
            expect(subject.section_groups(:status)).to be_an_instance_of Array
            expect(subject.section_groups(:status).count).to eq 1
          end
        end

        context 'when overview section_group name is passed in' do
          it 'returns multiple groups' do
            expect(subject.section_groups(:overview)).to be_an_instance_of Array
            expect(subject.section_groups(:overview).count).to eq 8
          end
        end

        context 'when claimed_costs section_group name is passed in' do
          it 'returns multiple groups' do
            expect(subject.section_groups(:claimed_costs)).to be_an_instance_of Array
            expect(subject.section_groups(:claimed_costs).count).to eq 2
          end
        end
      end

      context 'section group' do
        let(:section_group) { subject.section_group('claim_type', subject.claim_type_section) }

        it 'returns a section object' do
          expect(section_group[:sections].count).to eq 1
        end
      end

      context 'application status section' do
        it 'returns single elements' do
          expect(subject.application_status_section.count).to eq 1
        end
      end

      context 'claim type section' do
        it 'returns single elements' do
          expect(subject.claim_type_section.count).to eq 1
        end
      end

      context 'about you section' do
        it 'returns single elements' do
          expect(subject.about_you_section.count).to eq 1
        end
      end

      context 'about defendants section' do
        it 'returns single elements' do
          expect(subject.about_defendant_section.count).to eq 1
        end
      end

      context 'about case section' do
        it 'returns multiple elements' do
          expect(subject.about_case_section.count).to eq 3
        end
      end

      context 'about claim section' do
        it 'returns multiple elements' do
          expect(subject.about_claim_section.count).to eq 4
        end

        context 'when cost summary is excluded' do
          let(:cost_summary_in_overview) { false }

          it 'returns fewer elements' do
            expect(subject.about_claim_section.count).to eq 3
          end
        end
      end

      context 'supporting evidence section' do
        it 'returns a single element' do
          expect(subject.supporting_evidence_section.count).to eq 1
        end
      end
    end

    context 'in a complete state' do
      subject { described_class.new(claim) }

      let(:claim) { build(:claim, :complete, :completed_state) }

      context 'section groups' do
        it 'returns multiple groups' do
          expect(subject.section_groups).to be_an_instance_of Array
          expect(subject.section_groups.count).to eq 8
        end
      end

      context 'section group' do
        let(:section_group) { subject.section_group('claim_type', subject.claim_type_section) }

        it 'returns a section object' do
          expect(section_group[:sections].count).to eq 1
        end
      end

      context 'application status section' do
        it 'returns single elements' do
          expect(subject.application_status_section.count).to eq 1
        end
      end

      context 'claim type section' do
        it 'returns single elements' do
          expect(subject.claim_type_section.count).to eq 1
        end
      end

      context 'about you section' do
        it 'returns single elements' do
          expect(subject.about_you_section.count).to eq 1
        end
      end

      context 'about defendants section' do
        it 'returns single elements' do
          expect(subject.about_defendant_section.count).to eq 1
        end
      end

      context 'about case section' do
        it 'returns multiple elements' do
          expect(subject.about_case_section.count).to eq 3
        end
      end

      context 'about claim section' do
        it 'returns multiple elements' do
          expect(subject.about_claim_section.count).to eq 4
        end
      end

      context 'supporting evidence section' do
        it 'returns a single element' do
          expect(subject.supporting_evidence_section.count).to eq 1
        end
      end

      context 'equality answers section' do
        it 'returns a single element' do
          expect(subject.equality_answers_section.count).to eq 1
        end
      end
    end
  end
end
