# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Lti
  module Pns
    # Builds a notice informing a tool that an LTI resource was copied or
    # re-copied into a context.
    class LtiResourceCopyNoticeBuilder < NoticeBuilder
      REQUIRED_PARAMS = %i[
        source_context
        source_resource_id
        target_context
        target_resource_id
        copied_at
      ].freeze

      attr_reader :params

      def initialize(params = {})
        REQUIRED_PARAMS.each do |param_name|
          raise ArgumentError, "Missing required parameter: #{param_name}" unless params[param_name]
        end

        @params = params
        super()
      end

      def notice_type
        Lti::Pns::NoticeTypes::RESOURCE_COPY
      end

      def custom_instructure_claims(_tool)
        {}
      end

      def custom_ims_claims(_tool)
        target_context = params[:target_context]
        {
          context: {
            id: Lti::V1p1::Asset.opaque_identifier_for(target_context),
            label: target_context.respond_to?(:course_code) ? target_context.course_code : nil,
            title: target_context.respond_to?(:name) ? target_context.name : nil,
            type: [Lti::SubstitutionsHelper::LIS_V2_ROLE_MAP[target_context.class] || target_context.class.to_s]
          }.compact,
          resource_id: params[:target_resource_id],
          origin_resource_ids: [
            {
              context: Lti::V1p1::Asset.opaque_identifier_for(params[:source_context]),
              resource_id: params[:source_resource_id]
            }
          ]
        }
      end

      def notice_event_timestamp
        params[:copied_at]
      end

      def user
        nil
      end

      def variable_expander(_tool)
        nil
      end
    end
  end
end
