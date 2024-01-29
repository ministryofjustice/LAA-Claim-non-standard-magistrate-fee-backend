module PriorAuthority
  module Steps
    module AdditionalCosts
      class DetailForm < ::Steps::BaseFormObject
        include Rails.application.routes.url_helpers

        PER_ITEM = 'per_item'.freeze
        PER_HOUR = 'per_hour'.freeze

        UNIT_TYPES = [PER_ITEM, PER_HOUR].freeze
        attribute :id, :string
        attribute :name, :string
        attribute :description, :string
        attribute :unit_type, :string
        attribute :items, :integer
        attribute :cost_per_item, :decimal, precision: 10, scale: 2
        attribute :period, :time_period
        attribute :cost_per_hour, :decimal, precision: 10, scale: 2

        validates :name, presence: true
        validates :description, presence: true
        validates :unit_type, inclusion: { in: UNIT_TYPES, allow_nil: false }

        validates :items, presence: true, numericality: { greater_than: 0 }, if: :per_item?
        validates :cost_per_item, presence: true, numericality: { greater_than: 0 }, if: :per_item?

        validates :period, presence: true, time_period: true, unless: :per_item?
        validates :cost_per_hour, presence: true, numericality: { greater_than: 0 }, unless: :per_item?

        def formatted_total_cost
          NumberTo.pounds(per_item? ? item_cost : time_cost)
        end

        def method
          record.persisted? ? :patch : :post
        end

        def url
          if record.persisted?
            prior_authority_steps_additional_cost_detail_path(application, record)
          else
            prior_authority_steps_additional_cost_details_path(application)
          end
        end

        def per_item?
          unit_type == PER_ITEM
        end

        private

        def persist!
          record.update!(attributes.except('id'))
        end

        def item_cost
          return 0 unless cost_per_item.to_f.positive? && items.to_i.positive?

          cost_per_item * items
        end

        def time_cost
          return 0 unless cost_per_hour.to_i.positive? && period.to_i.positive?

          (cost_per_hour * (period.hours + (period.minutes / 60.0))).round(2)
        end
      end
    end
  end
end
