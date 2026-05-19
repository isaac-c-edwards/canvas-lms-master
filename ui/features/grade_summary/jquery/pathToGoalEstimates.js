/*
 * Copyright (C) 2026 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import {htmlEscape} from '@instructure/html-escape'

const PATH_ESTIMATE_DATA_KEY = 'pathToGoalEstimate'
export const PATH_TO_GOAL_ESTIMATES_EVENT = 'whatIfRequiredGrade:updateEstimates'

function clearPathToGoalEstimates(GradeSummary) {
  let clearedAny = false

  $('.student_assignment').each(function () {
    const $assignment = $(this)
    if (!$assignment.data(PATH_ESTIMATE_DATA_KEY)) return

    clearedAny = true
    $assignment.removeData(PATH_ESTIMATE_DATA_KEY)

    const originalScore = GradeSummary.getOriginalScore($assignment)
    $assignment.find('.what_if_score').text(originalScore.formattedValue)
    $assignment.find('.grade').html(htmlEscape(originalScore.formattedValue))

    const assignmentId = GradeSummary.getAssignmentId($assignment)
    const workflowState = GradeSummary.getOriginalWorkflowState($assignment)
    GradeSummary.updateScoreForAssignment(
      assignmentId,
      originalScore.numericalValue,
      workflowState,
    )
  })

  if (clearedAny) {
    GradeSummary.updateStudentGrades()
  }
}

function applyPathToGoalEstimates(GradeSummary, assignments) {
  clearPathToGoalEstimates(GradeSummary)

  assignments.forEach(({assignment_id: assignmentId, estimated_points: estimatedPoints}) => {
    const $assignment = $(`#submission_${assignmentId}`)
    if (!$assignment.length) return

    const originalScore = GradeSummary.getOriginalScore($assignment)
    if (originalScore.numericalValue != null) return

    const score = GradeSummary.parseScoreText(String(estimatedPoints))
    $assignment.data(PATH_ESTIMATE_DATA_KEY, true)
    $assignment.find('.what_if_score').text(score.formattedValue)
    $assignment.find('.grade').html(
      `<span class="what-if-path-estimate">${htmlEscape(score.formattedValue)}</span>`,
    )
    GradeSummary.updateScoreForAssignment(assignmentId, score.numericalValue, 'graded')
  })

  GradeSummary.updateStudentGrades()
}

export function bindPathToGoalEstimates(GradeSummary) {
  window.addEventListener(PATH_TO_GOAL_ESTIMATES_EVENT, event => {
    const assignments = event.detail?.assignments ?? []
    if (assignments.length === 0) {
      clearPathToGoalEstimates(GradeSummary)
    } else {
      applyPathToGoalEstimates(GradeSummary, assignments)
    }
  })
}

export function dispatchPathToGoalEstimates(assignments) {
  window.dispatchEvent(
    new CustomEvent(PATH_TO_GOAL_ESTIMATES_EVENT, {
      detail: {assignments},
    }),
  )
}
