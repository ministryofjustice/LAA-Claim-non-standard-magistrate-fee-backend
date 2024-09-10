require 'rails_helper'

RSpec.describe PriorAuthority::Steps::PrimaryQuoteForm do
  subject(:form) { described_class.new(arguments) }

  let(:arguments) do
    {
      record:,
      application:,
      service_type_autocomplete_suggestion:,
      contact_first_name:,
      contact_last_name:,
      organisation:,
      town:,
      postcode:,
      file_upload:,
    }
  end

  let(:record) { instance_double(Quote, document:) }
  let(:document) { instance_double(SupportingDocument, file_name: 'foo.png') }
  let(:application) { instance_double(PriorAuthorityApplication, service_type: 'forensics') }
  let(:service_type_autocomplete_suggestion) { 'forensics_expert' }
  let(:file_upload) { nil }
  let(:contact_first_name) { 'Joe' }
  let(:contact_last_name) { 'Bloggs' }
  let(:organisation) { 'LAA' }
  let(:town) { 'Townville' }
  let(:postcode) { 'CR0' }

  describe '#validate' do
    context 'with valid quote details not including a file upload' do
      it { is_expected.to be_valid }
    end

    context 'when no file has previously been uploaded' do
      let(:document) { instance_double(SupportingDocument, file_name: nil) }

      it 'treats a blank file upload as a validation error' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:file_upload, :blank)).to be(true)
      end
    end

    context 'with blank quote details' do
      let(:service_type_autocomplete_suggestion) { '' }
      let(:contact_first_name) { '' }
      let(:contact_last_name) { '' }
      let(:organisation) { '' }
      let(:postcode) { '' }

      it 'has a validation errors on blank fields' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:service_type_autocomplete, :blank)).to be(true)
        expect(form.errors.of_kind?(:contact_first_name, :blank)).to be(true)
        expect(form.errors.of_kind?(:contact_last_name, :blank)).to be(true)
        expect(form.errors.of_kind?(:organisation, :blank)).to be(true)
        expect(form.errors.of_kind?(:postcode, :blank)).to be(true)
        expect(form.errors.messages.values.flatten)
          .to include('Enter the service required',
                      "Enter the service provider's first name",
                      'Enter the organisation name',
                      'Enter the postcode')
      end
    end

    context 'with invalid quote details' do
      let(:service_type_autocomplete_suggestion) { 'Forensics Expert' }
      let(:postcode) { 'loren ipsum' }

      it 'has a validation errors on blank fields' do
        expect(form).not_to be_valid
        expect(form.errors.of_kind?(:postcode, :invalid)).to be(true)
        expect(form.errors.messages.values.flatten).to include(
          'Enter a real postcode, or at least the first part of a real postcode, for example B1, CR1, SW11 or SW1A'
        )
      end
    end

    context 'with a file upload' do
      let(:file_upload) { instance_double(ActionDispatch::Http::UploadedFile, tempfile:, content_type:) }
      let(:tempfile) { Rails.root.join('spec/fixtures/files/test.png').open }
      let(:content_type) { 'image/png' }
      let(:uploader) { instance_double(FileUpload::FileUploader, scan_file: nil) }

      before do
        allow(FileUpload::FileUploader).to receive(:new).and_return(uploader)
      end

      context 'with a valid upload' do
        it { is_expected.to be_valid }
      end

      context 'with an overly large file' do
        let(:tempfile) { instance_double(File, size:) }
        let(:size) { ENV['PA_MAX_UPLOAD_SIZE_BYTES'].to_i + 1 }

        before do
          allow(Marcel::MimeType).to receive(:for).and_return(content_type)
        end

        it 'adds an appropriate error message' do
          expect(form).not_to be_valid
          expect(form.errors[:file_upload]).to include(
            'The selected file must be smaller than 5MB'
          )
        end
      end

      context 'with unsupported file masquering as supported one' do
        let(:tempfile) { Rails.root.join('spec/fixtures/files/actually_a_zip.pdf').open }

        it 'adds an appropriate error message' do
          expect(form).not_to be_valid
          expect(form.errors[:file_upload]).to include(
            'The selected file must be a DOC, DOCX, XLSX, XLS, RTF, ODT, JPG, BMP, PNG, TIF or PDF'
          )
        end
      end

      context 'with suspected malware' do
        before do
          allow(uploader).to receive(:scan_file).and_raise FileUpload::FileUploader::PotentialMalwareError
        end

        it 'adds an appropriate error message' do
          expect(form).not_to be_valid
          expect(form.errors[:file_upload]).to include(
            'File potentially contains malware so cannot be uploaded. Please contact your administrator'
          )
        end
      end
    end
  end

  describe '#save' do
    subject(:save) { form.save }

    let(:record) { create(:quote, :blank, prior_authority_application: application) }
    let(:application) { create(:prior_authority_application) }

    context 'with valid quote details' do
      let(:service_type_autocomplete_suggestion) { 'Forensic scientist' }
      let(:contact_first_name) { 'Joe' }
      let(:contact_last_name) { 'Bloggs' }
      let(:organisation) { 'LAA' }
      let(:postcode) { 'CR0 1RE' }

      it 'persists the quote' do
        expect { save }.to change { record.reload.attributes }
          .from(
            hash_including(
              'contact_first_name' => nil,
              'contact_last_name' => nil,
              'organisation' => nil,
              'postcode' => nil,
              'primary' => nil
            )
          )
          .to(
            hash_including(
              'contact_first_name' => 'Joe',
              'contact_last_name' => 'Bloggs',
              'organisation' => 'LAA',
              'postcode' => 'CR0 1RE',
              'primary' => true
            )
          )
      end

      it 'persists the application changes' do
        expect { save }.to change { application.reload.attributes }
          .from(
            hash_including(
              'service_type' => nil,
            )
          )
          .to(
            hash_including(
              'service_type' => 'forensic_scientist',
              'custom_service_name' => nil,
            )
          )
      end
    end

    context 'with incomplete quote details' do
      let(:service_type_autocomplete_suggestion) { 'Forensic scientist' }
      let(:contact_first_name) { '' }
      let(:organisation) { '' }
      let(:postcode) { '' }

      it 'does not persist the client details' do
        expect { save }.not_to change { record.reload.attributes }
          .from(
            hash_including(
              'contact_first_name' => nil,
              'contact_last_name' => nil,
              'organisation' => nil,
              'postcode' => nil,
              'primary' => nil
            )
          )
      end
    end

    context 'when data populated from the DB' do
      subject(:form) { described_class.build(quote, application: prior_authority_application) }

      let(:prior_authority_application) { create(:prior_authority_application, :with_primary_quote) }
      let(:quote) { create(:quote, :primary, prior_authority_application:) }

      it 'saving does not modify application fields' do
        expect { form.save }.not_to(change do
                                      [application.reload.service_type, application.reload.custom_service_name]
                                    end)
      end
    end

    context 'with a valid file' do
      let(:file_upload) do
        instance_double(ActionDispatch::Http::UploadedFile,
                        tempfile: tempfile,
                        content_type: 'image/png',
                        original_filename: 'foo.png')
      end
      let(:tempfile) { Rails.root.join('spec/fixtures/files/test.png').open }
      let(:uploader) { instance_double(FileUpload::FileUploader, scan_file: nil) }

      before do
        allow(FileUpload::FileUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:upload).and_return('/cloud/url')
      end

      it 'uploads the file' do
        expect(uploader).to receive(:upload).with(file_upload)
        save
      end

      it 'updates the metadata' do
        save
        expect(record.document).to have_attributes(
          file_name: 'foo.png',
          file_type: 'image/png',
          file_size: 2875,
          file_path: '/cloud/url'
        )
      end

      context 'when there is an upload error' do
        before { expect(uploader).to receive(:upload).with(file_upload).and_raise StandardError }

        it 'does not update data' do
          expect { save }.not_to(change { application.reload.attributes })
        end

        it 'adds a validation error' do
          save
          expect(form.errors[:file_upload]).to include 'Unable to upload file at this time'
        end
      end
    end

    context 'when the service type is changed' do
      let(:contact_first_name) { 'Joe' }
      let(:contact_last_name) { 'Bloggs' }
      let(:organisation) { 'LAA' }
      let(:postcode) { 'CR0 1RE' }
      let(:record) { application.primary_quote }
      let(:service_type_autocomplete_suggestion) { 'Photocopying' }

      context 'when changed to one with a different item type' do
        let(:application) do
          create(:prior_authority_application,
                 service_type: 'transcription_recording',
                 quotes: [
                   build(:quote, :primary, items: 3, cost_per_item: 1.23),
                   build(:quote, :alternative, items: 3, cost_per_item: 1.25)
                 ])
        end

        let(:service_type_autocomplete_suggestion) { 'Photocopying' }

        it 'clears out old item data for primary quote' do
          expect { save }.to change { application.reload.primary_quote.attributes }.from(
            hash_including('items' => 3, 'cost_per_item' => 1.23)
          ).to(
            hash_including('items' => nil, 'cost_per_item' => nil)
          )
        end

        it 'removes alternative quotes entirely' do
          expect { save }.to change(application.alternative_quotes, :count).from(1).to(0)
        end
      end

      context 'when changed to one with a different cost basis type' do
        let(:application) do
          create(:prior_authority_application,
                 service_type: 'pathologist_report',
                 quotes: [
                   build(:quote, :primary, period: 30, cost_per_hour: 1.23),
                   build(:quote, :alternative, period: 60, cost_per_hour: 1.25)
                 ])
        end

        it 'clears out old item data for primary quote' do
          expect { save }.to change { application.reload.primary_quote.attributes }.from(
            hash_including('period' => 30, 'cost_per_hour' => 1.23)
          ).to(
            hash_including('period' => nil, 'cost_per_hour' => nil)
          )
        end

        it 'removes alternative quotes entirely' do
          expect { save }.to change(application.alternative_quotes, :count).from(1).to(0)
        end
      end
    end
  end

  describe 'variable assignment order' do
    subject(:form) { described_class.new }

    it 'service_type_autocomplete_suggestion overwrites service_type_autocomplete' do
      form.service_type_autocomplete = 'Culture expert'
      form.service_type_autocomplete_suggestion = 'apples'

      expect(form.service_type).to eq('custom')
      expect(form.custom_service_name).to eq('apples')
    end

    it 'service_type_autocomplete does not overwrites service_type_autocomplete_suggestion' do
      form.service_type_autocomplete_suggestion = 'apples'
      form.service_type_autocomplete = 'Culture expert'

      expect(form.service_type).to eq('custom')
      expect(form.custom_service_name).to eq('apples')
    end
  end

  describe '#service_type' do
    subject(:form) { described_class.new(arguments.merge(service_type_autocomplete_suggestion:)) }

    let(:service_type) { 'culture_expert' }

    context 'service type suggestion matches provided service' do
      let(:service_type_autocomplete_suggestion) { 'Culture expert' }

      it { expect(subject.service_type).to eq(PriorAuthority::QuoteServices::CULTURE_EXPERT.value) }
    end

    context 'service type suggestion matches a different service' do
      let(:service_type_autocomplete_suggestion) { 'Computer expert' }

      it 'uses the service type associated with the suggestion' do
        expect(subject.service_type).to eq(PriorAuthority::QuoteServices::COMPUTER_EXPERT.value)
      end
    end

    context 'service type suggestion does not match a quote service' do
      let(:service_type_autocomplete_suggestion) { 'garbage value' }

      it { expect(subject.service_type).to eq(PriorAuthority::QuoteServices.new('custom').value.to_s) }
    end
  end

  describe '#custom_service_name' do
    subject(:form) do
      described_class.new(arguments.merge(service_type_autocomplete_suggestion:).with_indifferent_access)
    end

    let(:service_type) { PriorAuthority::QuoteServices.values.sample }

    context 'service type suggestion matches a quote service' do
      let(:service_type_autocomplete_suggestion) { service_type.translated }

      it { expect(subject.custom_service_name).to be_nil }
    end

    context 'service type suggestion does not match a quote service' do
      let(:service_type_autocomplete_suggestion) { 'garbage value' }

      it { expect(subject.custom_service_name).to eq('garbage value') }
    end

    context 'when it is included but blank' do
      let(:service_type_autocomplete_suggestion) { '' }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#draft?' do
    let(:application) { instance_double(PriorAuthorityApplication, state:) }

    context 'when state is draft' do
      let(:state) { 'draft' }

      it { is_expected.to be_draft }
    end

    context 'when state is pre_draft' do
      let(:state) { 'pre_draft' }

      it { is_expected.to be_draft }
    end

    context 'when state is anything else' do
      let(:state) { 'apples' }

      it { is_expected.not_to be_draft }
    end
  end

  describe '#service_type_translation' do
    subject { described_class.new(application:) }

    let(:application) { create(:prior_authority_application, service_type:, custom_service_name:) }

    context 'when standard service type' do
      let(:service_type) { 'meteorologist' }
      let(:custom_service_name) { nil }

      it { expect(subject.service_type_translation).to eq('Meteorologist') }
    end

    context 'when custom service type' do
      let(:service_type) { 'custom' }
      let(:custom_service_name) { 'apples' }

      it { expect(subject.service_type_translation).to eq('apples') }
    end

    context 'when noservice type' do
      let(:service_type) { nil }
      let(:custom_service_name) { nil }

      it { expect(subject.service_type_translation).to be_nil }
    end
  end
end
