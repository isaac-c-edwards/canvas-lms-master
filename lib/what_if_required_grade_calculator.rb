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

# Read-only calculator for Feature 1 (What-If Grade Calculator).
# Computes the uniform minimum percentage a student must earn on all remaining
# assignments to reach a target course grade.
#
# v1 intentionally omits drop-lowest rules (see implementation-research.md FR5).
# Does not mutate grades; callers supply aggregated point totals from the student
# session context (Assignment / Submission domain).
class WhatIfRequiredGradeCalculator
  Result = Struct.new(:status, :required_uniform_percent, keyword_init: true) do
    def success?
      status == :success
    end

    def unreachable?
      status == :unreachable
    end
  end

  GroupInput = Struct.new(:weight, :graded_score, :graded_possible, :remaining_possible, keyword_init: true)

  class << self
    # Total-points (unweighted) courses.
    def for_points(graded_score:, graded_possible:, remaining_possible:, target_percent:)
      target = target_percent.to_d
      return invalid_target unless target.between?(0, 100)

      graded_score = graded_score.to_d
      graded_possible = graded_possible.to_d
      remaining_possible = remaining_possible.to_d

      if remaining_possible <= 0
        return no_remaining_work(graded_score, graded_possible, target)
      end

      total_possible = graded_possible + remaining_possible
      needed_points = (target / 100 * total_possible) - graded_score
      required = (needed_points / remaining_possible * 100).round(2)

      if required <= 0
        Result.new(status: :already_met, required_uniform_percent: 0.0)
      elsif required > 100
        Result.new(status: :unreachable, required_uniform_percent: nil)
      else
        Result.new(status: :success, required_uniform_percent: required.to_f)
      end
    end

    # Weighted assignment groups. Each group hash may be a GroupInput or keyword args.
    def for_weighted_groups(groups:, target_percent:)
      target = target_percent.to_d
      return invalid_target unless target.between?(0, 100)

      normalized = groups.map { |g| g.is_a?(GroupInput) ? g : GroupInput.new(**g) }
      weights = normalized.sum { |g| g.weight.to_d }
      return Result.new(status: :unreachable, required_uniform_percent: nil) if weights <= 0

      remaining_total = normalized.sum { |g| g.remaining_possible.to_d }
      if remaining_total <= 0
        current = current_weighted_percent(normalized, weights)
        return already_met_from_current(current, target)
      end

      const_term = 0.to_d
      coeff = 0.to_d

      normalized.each do |group|
        denom = group.graded_possible.to_d + group.remaining_possible.to_d
        next if denom <= 0

        w = group.weight.to_d
        const_term += w * group.graded_score.to_d * 100 / denom
        coeff += w * group.remaining_possible.to_d / denom
      end

      if coeff <= 0
        return Result.new(status: :unreachable, required_uniform_percent: nil)
      end

      required = ((target * weights - const_term) / coeff).round(2)

      if required <= 0
        Result.new(status: :already_met, required_uniform_percent: 0.0)
      elsif required > 100
        Result.new(status: :unreachable, required_uniform_percent: nil)
      else
        Result.new(status: :success, required_uniform_percent: required.to_f)
      end
    end

    private

    def invalid_target
      Result.new(status: :unreachable, required_uniform_percent: nil)
    end

    def no_remaining_work(graded_score, graded_possible, target)
      return Result.new(status: :unreachable, required_uniform_percent: nil) if graded_possible <= 0

      current = (graded_score / graded_possible * 100).round(2)
      already_met_from_current(current, target)
    end

    def already_met_from_current(current_percent, target)
      if current_percent >= target
        Result.new(status: :already_met, required_uniform_percent: 0.0)
      else
        Result.new(status: :unreachable, required_uniform_percent: nil)
      end
    end

    def current_weighted_percent(groups, weights)
      total = groups.sum do |group|
        denom = group.graded_possible.to_d + group.remaining_possible.to_d
        next 0 if denom <= 0

        group.weight.to_d * group.graded_score.to_d * 100 / denom
      end
      (total / weights).round(2)
    end
  end
end
