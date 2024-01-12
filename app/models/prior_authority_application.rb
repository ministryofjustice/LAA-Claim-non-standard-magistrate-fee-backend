class PriorAuthorityApplication < ApplicationRecord
  belongs_to :provider

  attribute :prison_law, :boolean
  attribute :ufn, :string
  attribute :contact_name, :string
  attribute :contact_email, :string
  attribute :firm_name, :string
  attribute :firm_account_number, :string
  attribute :ufn_form_status, :string
  attribute :client_first_name, :string
  attribute :client_last_name, :string
  attribute :client_date_of_birth, :date
  attribute :case_contact_form_status, :string
  enum :status, { pre_draft: 'pre_draft', draft: 'draft', submitted: 'submitted' }
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
end
