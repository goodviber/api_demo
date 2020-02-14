require 'rails_helper'

describe 'PUT /api/v3/workspaces', type: :request do
  let!(:accepted_terms) { true }
  let(:auth_headers) { {} }
  let(:expected_errors) { [] }
  let!(:hospital_name) { SecureRandom.uuid }
  let!(:workspace) { create(:hospital, :closed, creator: current_user, country: default_country) }
  let!(:current_user) { create(:user, rank: rank) }
  let(:workspace_params) { { parent_id: parent_hospital.try(:id), name: hospital_name, newsletter: true, terms_of_use: accepted_terms } }
  let(:params) { { workspace: workspace_params } }
  let!(:parent_hospital) { nil }
  let!(:rank) { 'hospital_admin' }

  subject do
    patch api_v3_workspace_path(workspace),
          params: params,
          headers: auth_headers

    response
  end

  describe 'anonymous access' do
    it 'returns HTTP status 401' do
      subject
      expect(response).to have_http_status 401
    end
  end

  shared_examples_for 'a successful request' do
    it { is_expected.to have_http_status(200) }
  end

  shared_examples_for 'an unsuccessful request' do
    it 'returns an error' do
      subject

      body = json_response

      expect(body[:errors]).to eq(expected_errors)
    end
  end

  describe 'anonymous access' do
    let(:expected_errors) {
      [{ code: 'unauthorized', title: 'Unauthorized', meta: {} }]
    }

    it { is_expected.to be_unauthorized }

    it_behaves_like 'an unsuccessful request'
  end

  describe 'when authenticated' do
    let!(:auth_headers) { authenticated_header(current_user) }

    before do
      create(:whitelisted_user_hospital, hospital: workspace, user: current_user)
      create(:hospital_admin_hospital, hospital: workspace, user: current_user)
    end

    context 'access hospital of different country which is not current users country' do
      let!(:workspace) { create(:hospital, creator: current_user) }

      it { is_expected.to have_http_status(:not_found) }
    end

    context 'modifies the name of the object' do
      let(:new_name) { 'test' }
      let(:workspace_params) { { name: new_name } }

      it 'updates the name' do
        expect { subject }.to change { workspace.reload.name }
      end
    end

    context 'not to change the name if creator id is nil' do
      let!(:workspace_without_creator) { create(:hospital, :closed, creator_id: nil) }
      let(:new_name) { 'test' }
      let(:workspace_params) { { name: new_name } }

      it 'does not updates the name' do
        expect { workspace_without_creator }.not_to change { workspace_without_creator.reload.name }
      end
    end

    context 'as an unconfirmed user' do
      let!(:current_user) { create(:user, :unconfirmed, password: 'password', rank: rank) }
      let(:expected_errors) {
        [
          {
            code: 'unconfirmed_user',
            title: 'Please confirm your email address before making this request',
            meta: {}
          }
        ]
      }

      it { is_expected.to have_http_status(:forbidden) }
      it_behaves_like 'an unsuccessful request'
    end

    context 'with invalid parameters' do
      context "without a 'name'" do
        let!(:hospital_name) {}
        let(:expected_errors) {
          [
            {
              code: 'update_workspace_failed',
              title: 'Could not update workspace',
              meta: { name: ["can't be blank"] }
            }
          ]
        }

        it_behaves_like 'an unsuccessful request'
        it { is_expected.to have_http_status(:unprocessable_entity) }
      end
    end

    it_behaves_like 'induction admin request of active and inactive country'
  end
end
