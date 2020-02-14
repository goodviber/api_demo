module Hospitals
  # Enables 'user' rank end-users to create/administer messaging-enabled
  # workspaces.
  class WorkspaceCreatorService
    include ActiveModel::Validations

    validates_presence_of :country, :creator, :name
    validate :open_parent?, if: :parent?

    attr_reader :hospital

    def initialize(options = {})
      extract_options(options)
    end

    def perform
      return false unless valid?

      @hospital = Hospital.new(create_attributes)
      return false unless hospital.valid?

      save_hospital

      hospital
    end

    def save_hospital
      hospital.transaction do
        hospital.save
        create_default_folders
        setup_hospital_administration
        setup_whitelisting
        record_user_newsletter_acceptance
        creator.save
      end
    end

    private

    attr_reader :country, :creator, :name, :newsletter, :parent_id

    def base_attributes
      {
        closed_network_enabled: true,
        country_id: country.id,
        creator_id: creator.id,
        drop_prefix: false,
        name: name,
        nickname: name,
        messaging_enabled: true
      }
    end

    def create_attributes
      return base_attributes unless parent

      base_attributes.merge(
        drop_prefix: parent.drop_prefix,
        prefix: parent.prefix,
        parent_id: parent.id
      )
    end

    def extract_options(opts = {})
      pid = opts[:parent_id]
      @country = opts[:country]
      @creator = opts[:creator]
      @name = opts[:name]
      @newsletter = (opts[:newsletter] || false).to_s != 'false'
      @parent_id = pid.to_i if pid.present?
    end

    def open_parent?
      errors.add(:parent, :invalid) if parent_id && parent.blank?
      errors.add(:parent, :closed) if parent.try(:closed_network_enabled?)
    end

    def parent?
      parent.present?
    end

    def create_default_folders
      GuidelineFolders::DefaultGuidelineFoldersCreatorService.new(hospital_id: hospital.id).perform
    end

    def parent
      return unless parent_id

      @parent ||= Hospital.find_by(country: country, id: parent_id)
    end

    def record_user_newsletter_acceptance
      creator.newsletter_accepted = newsletter
      @creator = UserDecorator.new(creator).user
    end

    def setup_hospital_administration
      creator.rank = 'hospital_admin' if creator.rank == 'user'
      creator.admined_hospitals << hospital
    end

    def setup_whitelisting
      # Create a 'logged_in' invite, to allow them to effectively invite themselves.
      invite = creator.invites.create(inviter: creator, hospital: hospital, state: :logged_in)
      invite.post_creation_actions
    end
  end
end

