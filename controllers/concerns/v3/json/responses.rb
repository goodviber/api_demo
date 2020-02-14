module V3
  module Json
    module Responses
      extend ActiveSupport::Concern

      included do
        protected

        def render_json_response(content, meta: {}, status: :success)
          response_json = {
            data: content,
            meta: meta
          }

          render json: response_json, status: status
        end

        def render_error_response(errors: {}, title: nil, code: nil, status: :unprocessable_entity, meta: {})
          code  ||= status
          title ||= code
          response_json = {
            errors: [
              {
                meta:  errors,
                code:  code,
                title: title.to_s.humanize,
              },
            ],
            meta: meta
          }

          render json: response_json, status: status
        end
      end
    end
  end
end
