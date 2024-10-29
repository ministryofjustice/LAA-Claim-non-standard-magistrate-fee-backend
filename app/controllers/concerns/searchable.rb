module Searchable
  extend ActiveSupport::Concern

  def search
    @current_navigation_item = :search
    @form = SearchForm.new(search_params)
    return unless @form.submitted? && @form.valid?

    @pagy, @model = order_and_paginate { SearchService.call(_1, @form.attributes.with_indifferent_access) }
  end

  def search_params
    (params[:search_form]&.permit(SearchForm.attribute_names) || {}).merge(current_provider:)
  end
end