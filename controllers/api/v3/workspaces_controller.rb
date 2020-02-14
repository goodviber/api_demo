module Api
  module V3
    class WorkspacesController < ::Api::V3::ApplicationController
      include Analytics::UserProfile
      before_action :load_hospital
      authorize_resource :hospital
      before_action :load_current_country_hospital, except: [:index, :create]
      before_action :set_user_profile, only: [:create]

      def index
        unfiltered_workspaces = Hospital.where(
          country_id: current_country.id,
          creator_id: nil
        )
        searched_workspaces = ::Hospitals::SearchService.search(
          unfiltered_workspaces,
          params[:search_string]
        )

        data = workspaces_serializer(searched_workspaces.by_name)

        render_json_response(data, status: :ok)
      end

      def show
        data = workspace_serializer(@hospital)
        render_json_response(data, status: :ok)
      end

      def create
        if creator_service.perform
          post_successful_workspace_creation
          data = workspace_serializer(creator_service.hospital).as_json
          render_json_response(data, status: :created)
        else
          render_error_response(
            code: 'create_workspace_failed',
            title: 'Could not create Workspace',
            errors: creator_service.errors
          )
        end
      end

      def update
        if @hospital.update(update_params)
          render json:         @hospital,
                 current_user: current_user
        else
          render_error_response(
            errors: @hospital.errors,
            title:  'Could not update Workspace',
            code:   'update_workspace_failed'
          )
        end
      end

      private

      def load_hospital
        @hospital = Hospital.find_by(id: params[:id])
      end

      def load_current_country_hospital
        ## the above load is for authorization which checks for active country
        ## this one ensures the object is scoped to current country of user
        @hospital = Hospital.find_by!(id: params[:id], country: current_country)
      end

      def set_user_profile
        @user = current_user
        user_profile_updater
      end

      def workspace
        creator_service.hospital
      end

      def closed_network_notifier
        @closed_network_notifier ||=
          ::Hospitals::ClosedNetworkNotifier.new(@workspace)
      end

      def workspace_serializer(workspace)
        ::V3::Workspaces::MinimalSerializer.new(workspace).as_json
      end

      def workspaces_serializer(workspaces)
        paginate(workspaces.by_name).map { |workspace|
          workspace_serializer(workspace)
        }
      end

      def post_successful_workspace_creation
        @old_workspace = creator_service.hospital
        user_profile_updater.update(current_user, old_workspace_closed?)
      end

      def create_params
        params.require(:workspace).permit(:name, :newsletter, :parent_id, :terms_of_use)
      rescue ActionController::ParameterMissing => _e
        {}
      end

      def update_params
        Hospitals::WorkspaceParamsService.new(current_user, @hospital, params).params
      end

      def creator_service
        @creator_service ||= Hospitals::WorkspaceCreatorService.new(
          HashWithIndifferentAccess.new({ country: current_country, creator: current_user }.merge(create_params))
        )
      end
    end
  end
end
