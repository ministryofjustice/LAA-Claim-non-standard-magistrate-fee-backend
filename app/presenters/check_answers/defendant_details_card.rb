# frozen_string_literal: true

module CheckAnswers
  class DefendantDetailsCard < Base
    attr_reader :defendant_details

    def initialize(claim)
      @defendant_details = claim.defendants
      @group = 'about_defendant'
      @section = 'defendant_summary'
    end

    def row_data
      main_defendant_row +
      additional_defendants.flat_map.with_index do |defendant, index|
        additional_defendant_row(defendant, index)
      end
    end

    private

    def main_defendant
      defendant_details.find { |defendant| defendant[:main] }
    end

    def additional_defendants
      defendant_details.reject { |defendant| defendant[:main] }
    end

    def main_defendant_row
      [
        {
          head_key: 'main_defendant_full_name',
          text: main_defendant[:full_name]
        },
        {
          head_key: 'main_defendant_maat',
          text: main_defendant[:maat]
        }
      ]
    end

    def additional_defendant_row(defendant, index)
      [
        {
          head_key: 'additional_defendant_full_name',
          text: defendant[:full_name],
          head_opts: { count: index + 1 }
        },
        {
          head_key: 'additional_defendant_maat',
          text: defendant[:maat],
          head_opts: { count: index + 1 }
        }
      ]
    end
  end
end
