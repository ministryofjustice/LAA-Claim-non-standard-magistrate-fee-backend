module CheckAnswers
  class CaseDetailsCard < Base
    def initialize(claim)
    
    end

    def route_path
      "case_details"
    end

    def title
      I18n.t('steps.check_answers.groups.about_case.case_details.title')
    end
  end
end
