# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
#

# @API What If Required Grade
#
# Read-only endpoint for Feature 1 target-grade calculator (student session).
#
# @model WhatIfRequiredGradeResponse
#     {
#       "id": "WhatIfRequiredGradeResponse",
#       "properties": {
#         "target_percent": {
#           "description": "Requested target overall percentage",
#           "example": 85.0,
#           "type": "number"
#         },
#         "status": {
#           "description": "success, unreachable, or already_met",
#           "example": "success",
#           "type": "string"
#         },
#         "required_uniform_percent": {
#           "description": "Uniform % needed on remaining work, or null if unreachable",
#           "example": 72.5,
#           "type": "number"
#         },
#         "current_percent": {
#           "description": "Student current overall percent from visible assignments",
#           "example": 68.0,
#           "type": "number"
#         },
#         "weighted": {
#           "description": "Whether the course uses weighted assignment groups",
#           "example": false,
#           "type": "boolean"
#         },
#         "disclaimer": {
#           "description": "Scope disclaimer (drop rules omitted in v1)",
#           "type": "string"
#         },
#         "message": {
#           "description": "Human-readable status for unreachable or already_met",
#           "type": "string"
#         }
#       }
#     }
#
class WhatIfRequiredGradesApiController < ApplicationController
  # @API Calculate required uniform grade for a target
  # Returns the uniform minimum percentage needed on remaining assignments.
  #
  # @argument target_percent [Required][Float]
  #   Target overall course percentage (0-100).
  #
  # @returns WhatIfRequiredGradeResponse
  def show
    course = @domain_root_account.all_courses.active.find(params[:course_id])
    enrollment = course.student_enrollments.active.find_by(user_id: @current_user.id)
    return render_unauthorized_action unless enrollment&.grants_right?(@current_user, :read_grades)
    return render_unauthorized_action if course.hide_final_grades?

    target_percent = parse_target_percent(params[:target_percent])
    unless target_percent
      return render json: { error: "target_percent is required and must be a number between 0 and 100." },
                    status: :bad_request
    end

    payload = WhatIf::RequiredGradeService.call(course:, user: @current_user, target_percent:)

    respond_to do |format|
      format.json { render json: payload }
    end
  end

  private

  def parse_target_percent(raw)
    return nil if raw.blank?

    value = Float(raw)
    return nil unless value.between?(0, 100)

    value
  rescue ArgumentError, TypeError
    nil
  end
end
