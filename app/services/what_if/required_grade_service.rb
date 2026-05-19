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

module WhatIf
  # Aggregates student-visible assignment totals and runs WhatIfRequiredGradeCalculator.
  # Read-only; v1 excludes drop-lowest rules (see implementation-research.md FR5).
  class RequiredGradeService < ApplicationService
    DROP_RULES_DISCLAIMER =
      "Drop lowest rules are not included in this calculation."

    def initialize(course:, user:, target_percent:)
      super()
      @course = course
      @user = user
      @target_percent = target_percent
    end

    def call
      aggregates = aggregate_totals
      result = if aggregates[:weighted]
                 WhatIfRequiredGradeCalculator.for_weighted_groups(
                   groups: aggregates[:groups],
                   target_percent: @target_percent
                 )
               else
                 WhatIfRequiredGradeCalculator.for_points(
                   **aggregates[:points],
                   target_percent: @target_percent
                 )
               end

      build_response(result, @target_percent, aggregates)
    end

    private

    def aggregate_totals
      assignments = visible_point_assignments.to_a
      submissions = submissions_for(assignments)
      assignment_groups = @course.assignment_groups.active.index_by(&:id)

      if @course.apply_group_weights?
        groups = Hash.new { |hash, key| hash[key] = empty_group_bucket(assignment_groups[key]) }

        assignments.each do |assignment|
          bucket = point_bucket(submissions[assignment.id], assignment)
          group_bucket = groups[assignment.assignment_group_id]
          merge_bucket!(group_bucket, bucket)
        end

        { weighted: true, groups: groups.values, points: nil }
      else
        totals = { graded_score: 0.to_d, graded_possible: 0.to_d, remaining_possible: 0.to_d }

        assignments.each do |assignment|
          bucket = point_bucket(submissions[assignment.id], assignment)
          merge_bucket!(totals, bucket)
        end

        { weighted: false, groups: nil, points: totals }
      end
    end

    def visible_point_assignments
      AssignmentGroup.visible_assignments(
        @user,
        @course,
        @course.assignment_groups.active,
        includes: [:assignment_group]
      ).where(grading_type: "points")
       .where.not(submission_types: "not_graded")
    end

    def submissions_for(assignments)
      return {} if assignments.empty?

      @course.submissions
             .where(user_id: @user.id, assignment_id: assignments.map(&:id))
             .index_by(&:assignment_id)
    end

    def empty_group_bucket(assignment_group)
      {
        weight: assignment_group&.group_weight.to_d,
        graded_score: 0.to_d,
        graded_possible: 0.to_d,
        remaining_possible: 0.to_d
      }
    end

    def point_bucket(submission, assignment)
      possible = assignment.points_possible.to_d
      return zero_bucket if possible <= 0
      return zero_bucket if submission&.excused?

      if graded_for_student?(submission, assignment)
        { graded_score: submission.score.to_d, graded_possible: possible, remaining_possible: 0.to_d }
      else
        { graded_score: 0.to_d, graded_possible: 0.to_d, remaining_possible: possible }
      end
    end

    def zero_bucket
      { graded_score: 0.to_d, graded_possible: 0.to_d, remaining_possible: 0.to_d }
    end

    def merge_bucket!(target, source)
      target[:graded_score] += source[:graded_score]
      target[:graded_possible] += source[:graded_possible]
      target[:remaining_possible] += source[:remaining_possible]
    end

    def graded_for_student?(submission, assignment)
      return false unless submission&.graded?

      assignment.post_manually? ? submission.posted? : true
    end

    def build_response(result, target_percent, aggregates)
      current_percent = current_percent_from(aggregates)

      {
        target_percent: target_percent.to_f,
        status: result.status.to_s,
        required_uniform_percent: result.required_uniform_percent,
        current_percent:,
        weighted: aggregates[:weighted],
        disclaimer: DROP_RULES_DISCLAIMER,
        message: response_message(result.status)
      }
    end

    def current_percent_from(aggregates)
      if aggregates[:weighted]
        weights = aggregates[:groups].sum { |g| g[:weight] }
        return nil if weights <= 0

        total = aggregates[:groups].sum do |group|
          denom = group[:graded_possible] + group[:remaining_possible]
          next 0.to_d if denom <= 0

          group[:weight] * group[:graded_score] * 100 / denom
        end
        (total / weights).round(2).to_f
      else
        points = aggregates[:points]
        denom = points[:graded_possible] + points[:remaining_possible]
        return nil if denom <= 0

        (points[:graded_score] / denom * 100).round(2).to_f
      end
    end

    def response_message(status)
      case status
      when :unreachable
        "Target unreachable with remaining assignments"
      when :already_met
        "Target already met with current grades"
      else
        nil
      end
    end
  end
end
