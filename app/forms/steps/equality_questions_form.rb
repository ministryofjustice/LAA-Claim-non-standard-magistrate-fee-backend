require 'steps/base_form_object'

# this is a form to determine where to move to the equality questions
# or skip them, as such it does not persist anything to DB
module Steps
  class EqualityQuestionsForm < Steps::BaseFormObject
    attribute :gender, :value_object, source: Genders
    attribute :ethnic_group, :value_object, source: EthnicGroups
    attribute :disablities, :value_object, source: Disablities

    validates :gender, inclusion: { in: Genders.values }
    validates :ethnic_group, inclusion: { in: EthnicGroups.values }
    validates :disablities, inclusion: { in: Disablities.values }

    private

    def persist!
      application.update!(attributes)
    end
  end
end
