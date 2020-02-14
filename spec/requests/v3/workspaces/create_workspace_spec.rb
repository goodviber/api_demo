require 'rails_helper'

describe 'POST /api/v3/workspaces', type: :request do
  let!(:accepted_terms) { true }
  let(:auth_headers) { {} }
  let!(:default_country) { create(:country, :default, :active) }
  let(:expected_errors) { [] }
  let!(:hospital_name) { SecureRandom.uuid }
  let!(:hospital_params) do
    {
      parent_id: parent_hospital.try(:id),
      name: hospital_name,
      newsletter: true,
      terms_of_use: accepted_terms
    }
  end
  let!(:parent_hospital) { nil }

  let!(:params) { { workspace: hospital_params } }

  before do
    host! "example.com"
  end

  subject do
    post api_v3_workspaces_path,
         params: params,
         headers: auth_headers

    response
  end

  shared_examples_for 'a successful request' do
    context 'with valid parameters' do
      context 'with a parent' do
        context 'that is an open hospital' do
          let!(:parent_hospital) { create(:hospital, :open, country: default_country) }

          it 'should have the parent set' do
            subject

            body = json_response

            expect(body.dig(:data, :parent_id)).to eq(parent_hospital.id)
          end
        end
      end
    end

    it { is_expected.to have_http_status(:created) }
    it do
      expect { subject }.to change { Hospital.count }.by(1)
    end

    it 'returns the basic workspace information' do
      subject

      body = json_response
      created_hospital = Hospital.last
      expect(body[:data]).to be_a_json_minimal_workspace(created_hospital)

      expect(created_hospital.guideline_folders.count).to eql(5)
      expect(created_hospital.guideline_folders.last.name).to eql("Teaching")
    end

    # TEMP: Terms acceptance temporarily deprecated
    it "doesn't record terms of use acceptance" do
      subject

      body = json_response
      created_hospital = Hospital.find_by(id: body.dig(:data, :id))

      expect(created_hospital.terms_accepted).to be(false)
      expect(created_hospital.terms_accepted_at).to be_nil
    end

    it 'tracks a profile update' do
      expect {
        subject
      }.to have_enqueued_job(Mixpanel::UserProfileUpdateEventJob)
                        .on_queue('mixpanel')
    end
  end

  shared_examples_for 'an unsuccessful request' do
    it "doesn't create a hospital" do
      expect { subject }.not_to change(Hospital, :count)
    end

    it "returns an error" do
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
    let!(:current_user) { create(:user, password: 'password') }
    let!(:expected_country) { default_country }

    context "as a user" do
      it_behaves_like 'a successful request'
    end

    context "as a hospital_admin" do
      let!(:rank) { 'hospital_admin' }

      it_behaves_like 'a successful request'
    end

    context "as a induction_admin" do
      let!(:rank) { 'induction_admin' }

      it_behaves_like 'a successful request'
    end
    context 'with valid parameters' do

      context 'without a parent' do
        it_behaves_like 'a successful request'
      end

      context 'with a parent' do
        context 'that is an open hospital' do
          let!(:parent_hospital) { create(:hospital, :open, country: default_country) }

          it 'should have the parent set' do
            subject

            body = json_response

            expect(body.dig(:data, :parent_id)).to eq(parent_hospital.id)
          end

          it_behaves_like 'a successful request'
        end
      end
    end

    context 'as an unconfirmed user' do
      let!(:current_user) { create(:user, :unconfirmed, password: 'password') }
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
      context 'invalid parent hospital' do
        context 'with a closed hospital' do
          let(:expected_errors) {
            [
              {
                code: 'create_workspace_failed',
                title: 'Could not create workspace',
                meta: {:parent=>["must be an open workspace"]}
              }
            ]
          }
          let!(:parent_hospital) { create(:hospital, :closed, country: default_country) }

          it_behaves_like 'an unsuccessful request'

          it { is_expected.to have_http_status(:unprocessable_entity) }
        end
      end

      context "without a 'name'" do
        let!(:hospital_name) { }
        let(:expected_errors) {
          [
            {
              code: 'create_workspace_failed',
              title: 'Could not create workspace',
              meta: {:name=>["can't be blank"]}
            }
          ]
        }

        it_behaves_like 'an unsuccessful request'

        it { is_expected.to have_http_status(:unprocessable_entity) }
      end

      # TEMP: Terms acceptance temporarily deprecated
      # context "without accepting the workspace terms of use" do
      #   let!(:accepted_terms) { false }
      #   let(:expected_errors) {
      #     [
      #       {
      #         code: 'create_workspace_failed',
      #         title: 'Could not create workspace',
      #         meta: { terms_of_use: [{ error: 'accepted' }] }
      #       }
      #     ]
      #   }

      #   it_behaves_like 'an unsuccessful request'

      #   it { is_expected.to have_http_status(:unprocessable_entity) }
      # end
    end
  end
end
