module Hospitals
  # Hospitals::SearchService takes in a collection of hospitals and a search term and produces a collection of
  # hospitals matching that search term
  class SearchService < Object
    class << self
      def search(hospitals, search_string)
        return hospitals if search_string.blank?

        hospitals.ransack(name_or_nickname_or_prefix_cont: search_string).result
      end
    end
  end
end
