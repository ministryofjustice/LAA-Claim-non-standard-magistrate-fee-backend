require 'rails_helper'

RSpec.describe Nsm::Steps::Office::SelectController, type: :controller do
  let(:provider) { Provider.new }

  before do
    allow(controller).to receive(:current_provider).and_return(provider)
  end

  describe '#edit' do
    it 'responds with HTTP success' do
      get :edit
      expect(response).to be_successful
    end
  end

  describe '#update' do
    let(:form_class) { Nsm::Steps::Office::SelectForm }
    let(:form_object) { instance_double(form_class, attributes: { foo: double }) }
    let(:form_class_params_name) { form_class.name.underscore }
    let(:expected_params) do
      { form_class_params_name => { foo: 'bar' } }
    end

    before do
      allow(form_class).to receive(:new).and_return(form_object)
    end

    context 'when the form saves successfully' do
      before do
        expect(form_object).to receive(:save).and_return(true)
      end

      let(:decision_tree) { instance_double(Decisions::OfficeDecisionTree, destination: '/expected_destination') }

      it 'asks the decision tree for the next destination and redirects there' do
        expect(Decisions::OfficeDecisionTree).to receive(:new).and_return(decision_tree)

        put :update, params: expected_params

        expect(response).to have_http_status(:redirect)
        expect(subject).to redirect_to('/expected_destination')
      end
    end

    context 'when the form fails to save' do
      before do
        expect(form_object).to receive(:save).and_return(false)
      end

      it 'renders the question page again' do
        put :update, params: expected_params
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
