module Nsm
  module CheckAnswers
    class FurtherInformationCard < Base
      include FurtherInformationPresentable

      def initialize(further_information, submission)
        @group = 'further_information'
        @section = 'further_information'
        @further_information = further_information
        @submission = submission
        super()
      end
    end
  end
end
