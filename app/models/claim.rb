class Claim < ApplicationRecord
  include LettersAndCallsCosts
  include StageReachedCalculatable

  belongs_to :submitter, class_name: 'Provider'
  belongs_to :firm_office, optional: true
  belongs_to :solicitor, optional: true
  has_many :defendants, -> { order(:position) }, dependent: :destroy, as: :defendable, inverse_of: :defendable
  has_one :main_defendant, lambda {
                             where(main: true)
                           }, class_name: 'Defendant', dependent: nil, as: :defendable, inverse_of: :defendable
  has_many :work_items, -> { order(:completed_on, :work_type, :id) }, dependent: :destroy, inverse_of: :claim
  has_many :disbursements, lambda {
                             order(:disbursement_date, :disbursement_type, :id)
                           }, dependent: :destroy, inverse_of: :claim
  has_many :supporting_evidence, -> { order(:created_at, :file_name) },
           dependent: :destroy,
           inverse_of: :documentable,
           class_name: 'SupportingDocument',
           as: :documentable

  scope :reviewed, -> { where(status: %i[granted part_grant rejected sent_back expired further_info]) }
  scope :submitted_or_resubmitted, -> { where(status: %i[submitted provider_updated]) }

  scope :for, ->(provider) { where(office_code: provider.office_codes).or(where(office_code: nil, submitter: provider)) }

  enum :status, { draft: 'draft', submitted: 'submitted', granted: 'granted', part_grant: 'part_grant',
                  review: 'review', sent_back: 'sent_back', provider_requested: 'provider_requested',
                  rejected: 'rejected' }

  def date
    rep_order_date || cntp_date
  end

  def short_id
    id.first(8)
  end

  def translated_matter_type
    {
      value: matter_type,
      en: MatterType.description_by_id(matter_type)
    }
  end

  def translated_hearing_outcome
    {
      value: hearing_outcome,
      en: OutcomeCode.description_by_id(hearing_outcome)
    }
  end

  def translated_reasons_for_claim
    reasons_for_claim.map do |reason|
      translations(reason, 'helpers.label.nsm_steps_reason_for_claim_form.reasons_for_claim_options')
    end
  end

  def translate_plea
    {
      'plea' => translations(plea, 'helpers.label.nsm_steps_case_disposal_form.plea_options'),
      'plea_category' => translations(plea_category, 'helpers.label.nsm_steps_case_disposal_form.plea_category')
    }
  end

  def translated_letters_and_calls
    pricing = Pricing.for(self)
    [
      { 'type' => translations('letters', 'helpers.label.nsm_steps_letters_calls_form.type_options'),
        'count' => letters, 'pricing' => pricing.letters.to_f, 'uplift' => letters_uplift },
      { 'type' => translations('calls', 'helpers.label.nsm_steps_letters_calls_form.type_options'),
        'count' => calls, 'pricing' => pricing.calls.to_f, 'uplift' => calls_uplift },
    ]
  end

  def translated_equality_answers
    {
      'answer_equality' => translations(answer_equality,
                                        'helpers.label.nsm_steps_answer_equality_form.answer_equality_options'),
      'disability' => translations(disability, 'helpers.label.nsm_steps_equality_questions_form.disability_options'),
      'ethnic_group' => translations(ethnic_group,
                                     'helpers.label.nsm_steps_equality_questions_form.ethnic_group_options'),
      'gender' => translations(gender, 'helpers.label.nsm_steps_equality_questions_form.gender_options')
    }
  end

  def as_json(*)
    super
      .merge(
        'letters_and_calls' => translated_letters_and_calls,
        'claim_type' => translations(claim_type, 'helpers.label.nsm_steps_claim_type_form.claim_type_options'),
        'matter_type' => translated_matter_type,
        'reasons_for_claim' => translated_reasons_for_claim,
        'hearing_outcome' => translated_hearing_outcome,
        **translate_plea,
        **translated_equality_answers
      ).slice!('letters', 'letters_uplift', 'calls', 'calls_uplift', 'app_store_updated_at')
  end

  def work_item_position(work_item)
    sorted_work_item_ids.index(work_item.id) + 1
  end

  def update_work_item_positions!
    updated_attributes = sorted_work_item_positions.index_by { |d| d[:id] }

    WorkItem.transaction do
      WorkItem.update(updated_attributes.keys, updated_attributes.values)
    end
  end

  def disbursement_position(disbursement)
    sorted_disbursement_ids.index(disbursement.id) + 1
  end

  def update_disbursement_positions!
    updated_attributes = sorted_disbursement_positions.index_by { |d| d[:id] }

    Disbursement.transaction do
      Disbursement.update(updated_attributes.keys, updated_attributes.values)
    end
  end

  private

  def sorted_work_item_ids
    @sorted_work_item_ids ||= work_items.sort_by do |workitem|
      [
        workitem.completed_on || Time.new(2000, 1, 1).in_time_zone.to_date,
        workitem.work_type&.downcase,
        workitem.created_at
      ]
    end.map(&:id)
  end

  def sorted_work_item_positions
    @sorted_work_item_positions ||= sorted_work_item_ids.each_with_object([]).with_index do |(id, memo), idx|
      memo << { id: id, position: idx + 1 }
    end
  end

  def sorted_disbursement_ids
    @sorted_disbursement_ids ||= disbursements.sort_by do |disb|
      [
        disb.disbursement_date || Time.new(2000, 1, 1).in_time_zone.to_date,
        disb.translated_disbursement_type&.downcase,
        disb.created_at
      ]
    end.map(&:id)
  end

  def sorted_disbursement_positions
    @sorted_disbursement_positions ||= sorted_disbursement_ids.each_with_object([]).with_index do |(id, memo), idx|
      memo << { id: id, position: idx + 1 }
    end
  end
end
