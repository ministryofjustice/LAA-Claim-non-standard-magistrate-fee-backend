require 'system_helper'

RSpec.describe 'Prior authority application lists' do
  before do
    visit provider_saml_omniauth_callback_path
    create(:prior_authority_application,
           :full,
           laa_reference: 'LAA-AAAAA',
           ufn: '120423/818',
           status: 'submitted',
           updated_at: 1.day.ago)
    create(:prior_authority_application, laa_reference: 'LAA-BBBBB', status: 'submitted', updated_at: 2.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-CCCC1', status: 'granted', updated_at: 3.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-CCCC2', status: 'sent_back', updated_at: 3.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-CCCC3', status: 'part_grant', updated_at: 3.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-CCCC4', status: 'rejected', updated_at: 3.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-CCCC5', status: 'auto_grant', updated_at: 3.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-DDDDD', status: 'draft', updated_at: 4.days.ago)
    create(:prior_authority_application, laa_reference: 'LAA-EEEEE', status: 'draft',
           office_code: 'OTHER', provider: create(:provider, :other))
  end

  context 'only shows right applications in the right tabs' do
    it 'for submitted' do
      visit submitted_prior_authority_applications_path

      expect(page).to have_content 'AAAAA'
      expect(page).to have_content 'BBBBB'
    end

    it 'for reviewed' do
      visit reviewed_prior_authority_applications_path

      expect(page)
        .to have_content('CCCC1')
        .and have_content('CCCC2')
        .and have_content('CCCC3')
        .and have_content('CCCC4')
        .and have_content('CCCC5')
    end

    it 'for drafts' do
      visit draft_prior_authority_applications_path

      expect(page).to have_content 'DDDDD'
    end
  end

  it 'shows most recently updated at the top by default' do
    visit submitted_prior_authority_applications_path

    expect(page.body).to match(/AAAAA.*BBBBB.*/m)
  end

  it 'allows sorting by columns in ascending and descending order' do
    visit submitted_prior_authority_applications_path

    expect(page).to have_content(/AAAAA.*BBBBB.*/m)
    click_on 'LAA reference'
    click_on 'LAA reference'
    expect(page).to have_content(/BBBBB.*AAAAA.*/m)
  end

  it 'does not show applications from other offices' do
    expect(page).to have_no_content 'EEEEE'
  end

  it 'links through to a readonly summary page for submitted applications' do
    visit submitted_prior_authority_applications_path

    click_on '120423/818'
    expect(page).to have_content 'Application details'
    expect(page).to have_content 'LAA-AAAAA'
    within 'main.govuk-main-wrapper' do
      expect(page).to have_no_content 'Change'
    end
    expect(page).to have_content 'Email the LAA case team'
  end
end
