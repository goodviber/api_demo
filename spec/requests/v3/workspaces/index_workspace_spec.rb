require 'rails_helper'

describe 'GET /api/v3/workspaces', type: :request do
  let(:auth_headers) { {} }
  let!(:default_country) { create(:country, :default, :active) }
  let(:expected_errors) { [] }
  let!(:parent_hospital) { nil }
  let!(:search_string) { '' }

  before do
    @controller_class = Api::V3::WorkspacesController
    host! 'example.com'
  end

  subject do
    get api_v3_workspaces_path,
        headers: auth_headers,
        params: { search_string: search_string }

    response
  end

  shared_examples_for 'a successful request' do
    it { is_expected.to have_http_status(:ok) }
    it_behaves_like 'it supports paginates (v3)'
  end

  describe 'anonymous access' do
    let(:expected_errors) {
      [{ code: 'unauthorized', title: 'Unauthorized', meta: {} }]
    }

    it { is_expected.to be_unauthorized }
  end

  describe 'when authenticated' do
    let!(:auth_headers) { authenticated_header(current_user) }
    let!(:current_user) { create(:user, password: 'password', rank: rank) }
    let!(:expected_country) { default_country }
    let!(:workspaces) { create_list(:hospital, 4, :open, country: default_country, creator_id: nil) }
    let!(:closed_workspace) { create(:hospital, :closed, country: default_country, creator_id: nil) }
    let!(:workspaces_with_creator_id) { create_list(:hospital, 2, :closed, country: default_country, creator_id: 2) }
    let!(:workspaces_with_changed_country_code) { create_list(:hospital, 3, :open, country: Country.last, creator_id: nil) }
    let!(:rank) { 'user' }
    let!(:named_workspace) { create(:hospital, :open, country: default_country, name: "happy") }

    let!(:teamspace) { create(:hospital, :teamspace, country: default_country) }

    context 'with valid parameters' do
      it 'contains a sorted list of workspaces' do
        subject
        body = json_response
        response_names = body[:data].map { |workspace| workspace[:name] }
        expect(response_names).to eq response_names.sort
      end

      it 'contains a sorted list of workspaces' do
        subject
        body = json_response
        workspace = body[:data].first
        hospital = Hospital.find(workspace[:id])
        expect(workspace).to be_a_json_minimal_workspace(hospital)
      end

      it "doesn't contain team spaces" do
        subject

        body = json_response
        body[:data].each do |workspace|
          expect(workspace[:creator_id]).to be_nil
        end
      end

      it "doesn't contain hospitals from other countries" do
        subject

        body = json_response
        body[:data].each do |workspace|
          hospital = Hospital.find(workspace[:id])
          expect(hospital.country).to eq(default_country)
        end
      end

      it_behaves_like 'a successful request'

      context 'with search params' do
        let(:search_string) { 'happ' }

        it "contains only the named hopital" do
          subject
          body = json_response
        expect(body[:data][0][:name]).to eq("happy")
        expect(body[:data].size).to be(1)
        end
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
    end
  end
end
