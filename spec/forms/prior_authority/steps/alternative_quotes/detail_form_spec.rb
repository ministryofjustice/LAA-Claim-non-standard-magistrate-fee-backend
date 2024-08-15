require 'rails_helper'

RSpec.describe PriorAuthority::Steps::AlternativeQuotes::DetailForm do
  subject(:form) { described_class.new(arguments) }

  let(:arguments) do
    {
      record: record,
      application: application,
      contact_first_name: 'John',
      contact_last_name: 'Smith',
      organisation: 'Acme Ltd',
      postcode: 'SW1 1AA',
      file_upload: file_upload,
      items: '1',
      cost_per_item: '1',
      period: period,
      cost_per_hour: cost_per_hour,
      user_chosen_cost_type: user_chosen_cost_type,
      'travel_time(1)': '',
      'travel_time(2)': '',
      travel_cost_per_hour: travel_cost_per_hour,
      additional_cost_list: additional_cost_list,
      additional_cost_total: '',
    }
  end

  let(:period) { nil }
  let(:cost_per_hour) { nil }
  let(:user_chosen_cost_type) { nil }
  let(:travel_cost_per_hour) { '' }
  let(:additional_cost_list) { '' }
  let(:record) { build(:quote, document: nil) }
  let(:quotes) { [build(:quote, :primary)] }
  let(:application) { create(:prior_authority_application, service_type:, quotes:) }
  let(:service_type) { 'photocopying' }

  let(:file_upload) { instance_double(ActionDispatch::Http::UploadedFile, tempfile:, content_type:) }
  let(:tempfile) { Rails.root.join('spec/fixtures/files/test.png').open }
  let(:content_type) { 'application/pdf' }

  describe '#save' do
    let(:uploader) { instance_double(FileUpload::FileUploader, scan_file: nil) }

    before do
      allow(FileUpload::FileUploader).to receive(:new).and_return(uploader)
    end

    context 'when file for upload is invalid' do
      let(:tempfile) { Rails.root.join('spec/fixtures/files/actually_a_zip.pdf').open }

      it 'returns false' do
        expect(subject.save).to be false
      end

      it 'adds an appropriate error message' do
        subject.save
        expect(subject.errors[:file_upload]).to include(
          'The selected file must be a DOC, DOCX, XLSX, XLS, RTF, ODT, JPG, BMP, PNG, TIF or PDF'
        )
      end
    end

    context 'when file upload fails' do
      before do
        allow(uploader).to receive(:upload).and_raise StandardError
      end

      it 'returns false' do
        expect(subject.save).to be false
      end

      it 'adds an appropriate error message' do
        subject.save
        expect(subject.errors[:file_upload]).to include(
          'Unable to upload file at this time'
        )
      end
    end

    context 'when only one travel field is filled in' do
      let(:travel_cost_per_hour) { '1' }

      it 'returns false' do
        expect(subject.save).to be false
      end

      it 'adds an appropriate error message' do
        subject.save
        expect(subject.errors[:travel_time]).to include(
          'To add travel costs you must enter both the time and the hourly cost'
        )
      end
    end

    context 'when only one additional cost field is filled in' do
      let(:additional_cost_list) { 'Photocopying' }

      it 'returns false' do
        expect(subject.save).to be false
      end

      it 'adds an appropriate error message' do
        subject.save
        expect(subject.errors[:additional_cost_total]).to include(
          'To add additional costs you must enter both a list of the additional costs and the total cost'
        )
      end
    end

    context 'when redundant fields are entered' do
      let(:period) { 180 }
      let(:cost_per_hour) { '35' }
      let(:items) { '3' }
      let(:cost_per_item) { '20' }
      let(:user_chosen_cost_type) { 'per_hour' }
      let(:application) { create(:prior_authority_application, service_type: 'custom', quotes: quotes) }
      let(:record) { build(:quote, document: nil, prior_authority_application: application) }
      let(:file_upload) { nil }

      it 'clears them out' do
        subject.save
        expect(record.reload).to have_attributes(
          items: nil,
          cost_per_item: nil
        )
      end
    end
  end

  describe '#travel_cost' do
    let(:arguments) do
      {
        record: record,
        application: application,
        'travel_time(1)': travel_hours,
        'travel_time(2)': travel_minutes,
        travel_cost_per_hour: travel_cost_per_hour
      }
    end
    let(:travel_hours) { '1' }
    let(:travel_minutes) { '10' }
    let(:travel_cost_per_hour) { '1' }

    context 'when travel_time is invalid' do
      let(:travel_minutes) { '' }

      it 'returns 0' do
        expect(form.travel_cost).to eq 0
      end
    end

    context 'when travel_cost_per_hour is invalid' do
      let(:travel_cost_per_hour) { '1apple' }

      it 'returns 0' do
        expect(form.travel_cost).to eq 0
      end
    end
  end

  describe '#total_cost (per hour)' do
    let(:period) { 30 }
    let(:cost_per_hour) { '10' }
    let(:user_chosen_cost_type) { 'per_hour' }
    let(:service_type) { 'meteorologist' }

    it 'calculates correctly' do
      expect(subject.total_cost).to eq 5.0
    end

    context 'when cost_per_hours is < £1' do
      let(:cost_per_hour) { '0.5' }

      it 'calculates correctly' do
        expect(subject.total_cost).to eq 0.25
      end
    end

    context 'when cost_per_hours is invalid' do
      let(:cost_per_hour) { '1apple' }

      it 'returns 0' do
        expect(subject.total_cost).to eq 0
      end
    end
  end

  describe '#total_cost (per item)' do
    let(:items) { 30 }
    let(:cost_per_item) { '10' }
    let(:user_chosen_cost_type) { 'per_item' }
    let(:service_type) { 'translation_documents' }

    it 'calculates correctly' do
      expect(subject.total_cost).to eq 300.0
    end

    context 'when cost_per_hours is < £1' do
      let(:cost_per_item) { '0.5' }

      it 'calculates correctly' do
        expect(subject.total_cost).to eq 15.0
      end
    end

    context 'when cost_per_hours is invalid' do
      let(:cost_per_item) { '1apple' }

      it 'returns 0' do
        expect(subject.total_cost).to eq 0
      end
    end
  end

  describe '#cost_type' do
    context 'when service has variable cost type' do
      let(:service_type) { 'dna_report' }
      let(:quotes) { [build(:quote, :primary_per_item)] }

      it 'uses the same cost type as the user-chosen primary quote cost type' do
        expect(subject.cost_type).to eq 'per_item'
      end
    end
  end
end
