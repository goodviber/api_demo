module V3
  module  Workspaces
    # poro serializer for guideline
    class MinimalSerializer
      attr_reader :object

      def initialize(object)
        @object = object
      end

      def as_json
        properties
          .merge(workspace_admin_users)
          .merge(name_hash)
      end

      private

      def properties
        {
          id: object.id,
          messaging_enabled: object.messaging_enabled,
          closed_network_enabled: object.closed_network_enabled,
          creator_id: object.creator_id,
          parent_id: object.parent_id,
          updated_at: object.updated_at
        }
      end

      def name_hash
        {
          name: object.name,
          nickname: object.nickname
        }
      end

      def admin_users
        object.admin_users
      end

      def workspace_admin_users
        {
          admin_users: admin_users.map { |admin_user| V3::Users::MinimalSerializer.new(admin_user).as_json }
        }
      end
    end
  end
end
