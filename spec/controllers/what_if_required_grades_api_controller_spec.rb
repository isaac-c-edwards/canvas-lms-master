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

require_relative "../apis/api_spec_helper"

describe WhatIfRequiredGradesApiController do
  describe "#show" do
    before(:once) do
      @course = course_model
      @student = student_in_course(course: @course, active_all: true).user
      @teacher = teacher_in_course(course: @course, active_all: true).user
      @group = @course.assignment_groups.create!(name: "Assignments", group_weight: 100)
      @assignment = @course.assignments.create!(
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
      @assignment.grade_student(@student, grade: 64, grader: @teacher)
    end

    before { user_session(@student) }

    it "returns required grade for enrolled student" do
      get :show, params: { course_id: @course.id, target_percent: 80 }, format: :json

      json = response.parsed_body
      expect(response).to be_successful
      expect(json["status"]).to eq "success"
      expect(json["required_uniform_percent"]).to be 80.0
      expect(json["disclaimer"]).to include("Drop lowest")
    end

    it "returns bad request for invalid target_percent" do
      get :show, params: { course_id: @course.id, target_percent: 150 }, format: :json

      expect(response).to be_bad_request
      expect(response.parsed_body["error"]).to include("target_percent")
    end

    it "denies users without enrollment" do
      outsider = user_factory(active_all: true)
      user_session(outsider)

      get :show, params: { course_id: @course.id, target_percent: 80 }, format: :json

      expect(response).to be_unauthorized
    end

    it "denies when course hides final grades" do
      @course.settings = @course.settings.merge(hide_final_grades: true)
      @course.save!

      get :show, params: { course_id: @course.id, target_percent: 80 }, format: :json

      expect(response).to be_unauthorized
    end
  end
end
