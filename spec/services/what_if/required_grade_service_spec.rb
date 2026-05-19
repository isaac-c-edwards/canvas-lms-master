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

describe WhatIf::RequiredGradeService do
  describe "#call" do
    before(:once) do
      @course = course_model
      @student = student_in_course(course: @course, active_all: true).user
      @teacher = teacher_in_course(course: @course, active_all: true).user
      @group = @course.assignment_groups.create!(name: "Assignments", group_weight: 100)
    end

    it "returns required uniform percent for unweighted courses" do
      a1 = @course.assignments.create!(
        title: "Graded",
        points_possible: 80,
        grading_type: "points",
        assignment_group: @group
      )
      a2 = @course.assignments.create!(
        title: "Remaining",
        points_possible: 20,
        grading_type: "points",
        assignment_group: @group
      )
      a1.grade_student(@student, grade: 64, grader: @teacher)

      result = described_class.call(course: @course, user: @student, target_percent: 80)

      expect(result[:status]).to eq "success"
      expect(result[:required_uniform_percent]).to be 80.0
      expect(result[:weighted]).to be false
      expect(result[:current_percent]).to be 64.0
      expect(result[:estimated_assignments]).to eq [
        {
          assignment_id: a2.id,
          title: "Remaining",
          points_possible: 20.0,
          estimated_points: 16.0
        }
      ]
    end

    it "returns unreachable status when target cannot be met" do
      a1 = @course.assignments.create!(
        title: "Graded",
        points_possible: 80,
        grading_type: "points",
        assignment_group: @group
      )
      @course.assignments.create!(
        title: "Remaining",
        points_possible: 20,
        grading_type: "points",
        assignment_group: @group
      )
      a1.grade_student(@student, grade: 40, grader: @teacher)

      result = described_class.call(course: @course, user: @student, target_percent: 95)

      expect(result[:status]).to eq "unreachable"
      expect(result[:required_uniform_percent]).to be_nil
      expect(result[:estimated_assignments]).to eq []
      expect(result[:message]).to eq "Target unreachable with remaining assignments"
    end
  end
end
