require 'rails_helper'

describe 'GET /api/v3/workspace/:id', type: :request do
  let(:auth_headers) { {} }
  let!(:default_country) { create(:country, :default, :active) }
  let!(:current_user) { create(:user, password: 'password', rank: rank) }
  let!(:workspace) { create(:hospital, creator: current_user, country: default_country) }
  let(:expected_errors) { [] }
  let!(:rank) { 'user' }

  before do
    @controller_class = Api::V3::WorkspacesController
    host! 'example.com'
  end

  subject do
    get api_v3_workspace_path(workspace),
        headers: auth_headers
    response
  end

  shared_examples_for 'a successful request' do
    it { is_expected.to have_http_status(:ok) }
  end

  describe 'anonymous access' do
    let(:expected_errors) {
      [{ code: 'unauthorized', title: 'Unauthorized', meta: {} }]
    }

    it { is_expected.to be_unauthorized }
  end

  describe 'when authenticated' do
    let!(:auth_headers) { authenticated_header(current_user) }
    let!(:rank) { 'user' }

    context 'with valid parameters' do
      it 'contains the workspace with given id' do
        subject
        body = json_response
        hospital = Hospital.find(workspace[:id])
        expect(body[:data]).to be_a_json_minimal_workspace(hospital)
      end
    end

    it_behaves_like 'a successful request'
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
    end

    context 'access hospital of different country which is not current users country' do
      let!(:workspace) { create(:hospital, creator: current_user) }

      it { is_expected.to have_http_status(:not_found) }
    end

    it_behaves_like 'induction admin request of active and inactive country'
  end
end
