module ApplicationHelper
  # moved here to allow view specs to work
  def current_application
    @current_application ||=
      Claim.for(current_provider).find_by(id: params[:id]) ||
      PriorAuthorityApplication.for(current_provider).find_by(id: params[:application_id] || params[:id])
  end

  def maat_required?(form)
    form.application.claim_type != ClaimType::BREACH_OF_INJUNCTION.to_s
  end

  def multiline_text(string)
    ApplicationController.helpers.sanitize(string.gsub("\n", '<br>'), tags: %w[br])
  end

  def sanitize_strings(array, *tags)
    array.map { ApplicationController.helpers.sanitize(_1, tags:) }
  end

  def relevant_prior_authority_list_anchor(prior_authority_application)
    case prior_authority_application.state
    when 'submitted'
      :submitted
    when 'draft'
      :draft
    else
      :reviewed
    end
  end

  def govuk_table_with_cell(head, rows, caption: {})
    govuk_table do |table|
      table.with_caption(**caption) if caption[:text]
      table.with_head(rows: [head])
      table.with_body do |body|
        rows.each do |item_row|
          body.with_row(html_attributes: item_row.try(:tr_html_attributes) || {}) do |row|
            item_row.each do |cell|
              # Slice to extract only the known keys to ensure compatibility (https://www.rubydoc.info/gems/govuk-components/GovukComponent/TableComponent/CellComponent)
              cell_options = cell.slice(:header, :numeric, :text, :width, :parent,
                                        :rowspan, :colspan, :classes, :html_attributes)
              row.with_cell(**cell_options)
            end
          end
        end
      end
    end
  end

  def generate_aria_labelledby(item_title, position, type, additional_variable = nil)
    base_string = "#{item_title} item#{position} #{type}#{position}"
    additional_variable ? "#{additional_variable}#{position} #{base_string}" : base_string
  end
end
