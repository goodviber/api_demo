module Hospitals
  # Service class for creating a hospital
  class CreatorService
    include ActiveModel::Validations

    def initialize(hospital)
      @hospital = hospital
    end

    def perform
      errors.merge!(@hospital.errors) unless hospital.valid?
      return false if errors.any?

      add_default_folders if hospital.save

      hospital
    end

    private

    attr_reader :hospital

    def add_default_folders
      GuidelineFolders::DefaultGuidelineFoldersCreatorService.new(hospital_id: hospital.id)
      .perform
    end
  end
end
