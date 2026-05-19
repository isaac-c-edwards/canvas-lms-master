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

describe WhatIfRequiredGradeCalculator do
  describe ".for_points" do
    it "returns unreachable for research §5 example (90% target needs 140% on remainder)" do
      # 800/1000 graded, 200 points remaining, target 90% overall
      result = described_class.for_points(
        graded_score: 800,
        graded_possible: 1000,
        remaining_possible: 200,
        target_percent: 90
      )

      expect(result).to be_unreachable
      expect(result.required_uniform_percent).to be_nil
    end

    it "computes a success path when target is reachable" do
      result = described_class.for_points(
        graded_score: 800,
        graded_possible: 1000,
        remaining_possible: 200,
        target_percent: 80
      )

      expect(result).to be_success
      expect(result.required_uniform_percent).to eq 80.0
    end

    it "marks unreachable when required uniform percent exceeds 100" do
      result = described_class.for_points(
        graded_score: 400,
        graded_possible: 500,
        remaining_possible: 500,
        target_percent: 95
      )

      expect(result).to be_unreachable
      expect(result.required_uniform_percent).to be_nil
    end

    it "returns already_met when target is below current standing" do
      result = described_class.for_points(
        graded_score: 900,
        graded_possible: 1000,
        remaining_possible: 100,
        target_percent: 85
      )

      expect(result.status).to eq :already_met
      expect(result.required_uniform_percent).to eq 0.0
    end
  end

  describe ".for_weighted_groups" do
    let(:groups) do
      [
        { weight: 50, graded_score: 400, graded_possible: 500, remaining_possible: 100 },
        { weight: 50, graded_score: 300, graded_possible: 400, remaining_possible: 100 }
      ]
    end

    it "returns uniform required percent for weighted courses" do
      result = described_class.for_weighted_groups(groups:, target_percent: 85)

      expect(result).to be_success
      expect(result.required_uniform_percent).to be_a(Float)
      expect(result.required_uniform_percent).to be > 0
      expect(result.required_uniform_percent).to be <= 100
    end

    it "matches points-based math when a single group carries full weight" do
      single = [{ weight: 100, graded_score: 800, graded_possible: 1000, remaining_possible: 200 }]

      points = described_class.for_points(
        graded_score: 800,
        graded_possible: 1000,
        remaining_possible: 200,
        target_percent: 80
      )
      weighted = described_class.for_weighted_groups(groups: single, target_percent: 80)

      expect(weighted.required_uniform_percent).to eq points.required_uniform_percent
    end

    it "returns unreachable when no remaining points exist and target is not met" do
      groups_no_remaining = [
        { weight: 100, graded_score: 700, graded_possible: 1000, remaining_possible: 0 }
      ]

      result = described_class.for_weighted_groups(groups: groups_no_remaining, target_percent: 90)

      expect(result).to be_unreachable
    end
  end
end
