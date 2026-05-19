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

import React, {useCallback, useEffect, useState} from 'react'
import axios from '@canvas/axios'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {NumberInput} from '@instructure/ui-number-input'
import {RangeInput} from '@instructure/ui-range-input'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {dispatchPathToGoalEstimates} from '../../grade_summary/jquery/pathToGoalEstimates'

const I18n = createI18nScope('what_if_required_grade')

export type EstimatedAssignment = {
  assignment_id: number
  title: string
  points_possible: number
  estimated_points: number
}

export type RequiredGradeResponse = {
  target_percent: number
  status: 'success' | 'unreachable' | 'already_met'
  required_uniform_percent: number | null
  current_percent: number | null
  weighted: boolean
  estimated_assignments?: EstimatedAssignment[]
  disclaimer: string
  message: string | null
}

type WhatIfRequiredGradePanelProps = {
  courseId: string
}

const DEFAULT_TARGET = 85

function clampTarget(value: number): number {
  return Math.min(100, Math.max(0, value))
}

function parseTargetValue(value: number | string): number | null {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  return Number.isNaN(parsed) ? null : parsed
}

function WhatIfRequiredGradePanel({courseId}: WhatIfRequiredGradePanelProps) {
  const [toolEnabled, setToolEnabled] = useState(false)
  const [targetPercent, setTargetPercent] = useState(DEFAULT_TARGET)
  const [result, setResult] = useState<RequiredGradeResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchRequiredGrade = useCallback(
    async (target: number, signal: AbortSignal) => {
      setLoading(true)
      setError(null)

      try {
        const {data} = await axios.get<RequiredGradeResponse>(
          `/api/v1/courses/${courseId}/what_if/required_grade`,
          {params: {target_percent: target}, signal},
        )
        setResult(data)
      } catch (e) {
        if (signal.aborted || axios.isCancel(e)) return
        setResult(null)
        setError(I18n.t('Unable to calculate your path to this goal. Please try again.'))
      } finally {
        if (!signal.aborted) setLoading(false)
      }
    },
    [courseId],
  )

  useEffect(() => {
    if (!toolEnabled) return

    const controller = new AbortController()
    const timer = window.setTimeout(() => {
      if (targetPercent >= 0 && targetPercent <= 100) {
        fetchRequiredGrade(targetPercent, controller.signal)
      }
    }, 400)

    return () => {
      window.clearTimeout(timer)
      controller.abort()
    }
  }, [targetPercent, fetchRequiredGrade, toolEnabled])

  useEffect(() => {
    if (!toolEnabled) {
      dispatchPathToGoalEstimates([])
      return
    }

    if (result?.status === 'success' && result.estimated_assignments?.length) {
      dispatchPathToGoalEstimates(result.estimated_assignments)
    } else {
      dispatchPathToGoalEstimates([])
    }
  }, [result, toolEnabled])

  useEffect(() => {
    return () => {
      dispatchPathToGoalEstimates([])
    }
  }, [])

  const handleToolToggle = (_event: React.SyntheticEvent, expanded: boolean) => {
    setToolEnabled(expanded)
    if (!expanded) {
      dispatchPathToGoalEstimates([])
      setResult(null)
      setError(null)
      setLoading(false)
    }
  }

  const handleTargetChange = (value: number | string) => {
    const parsed = parseTargetValue(value)
    if (parsed == null) return
    setTargetPercent(clampTarget(parsed))
  }

  const handleNumberInputChange = (
    _event: React.SyntheticEvent,
    value: number | string,
  ) => {
    if (value === '') return
    handleTargetChange(value)
  }

  const successMessage =
    result?.status === 'success' && result.required_uniform_percent != null
      ? I18n.t(
          'To reach %{target}%, aim for about %{required}% on your remaining work.',
          {
            target: result.target_percent,
            required: result.required_uniform_percent,
          },
        )
      : null

  return (
    <View as="section" margin="medium 0" data-testid="what-if-required-grade-panel">
      <ToggleDetails
        summary={I18n.t('Path to Your Goal')}
        expanded={toolEnabled}
        onToggle={handleToolToggle}
        data-testid="what-if-tool-toggle"
      >
        <Text as="p" size="small" margin="0 0 small 0">
          {I18n.t(
            'Choose a target course grade to see the uniform percentage you would need on remaining assignments.',
          )}
        </Text>

        {result?.current_percent != null && (
          <Text as="p" size="small" margin="0 0 small 0">
            {I18n.t('Your current overall grade is about %{percent}%.', {
              percent: result.current_percent,
            })}
          </Text>
        )}

        <RangeInput
          renderLabel={I18n.t('Target grade (%)')}
          min={0}
          max={100}
          step={1}
          value={targetPercent}
          onChange={handleTargetChange}
          data-testid="what-if-target-slider"
        />

        <NumberInput
          renderLabel={I18n.t('Target grade precise value (%)')}
          displayInt={true}
          min={0}
          max={100}
          value={targetPercent}
          onChange={handleNumberInputChange}
          margin="small 0"
          data-testid="what-if-target-input"
        />

        {loading && (
          <View margin="small 0" textAlign="center">
            <Spinner renderTitle={I18n.t('Calculating path to your goal')} size="small" />
          </View>
        )}

        <View aria-live="polite" aria-atomic="true">
          {error && (
            <Alert variant="error" margin="small 0">
              {error}
            </Alert>
          )}

          {!error && result?.status === 'unreachable' && (
            <Alert variant="warning" margin="small 0" data-testid="what-if-unreachable-alert">
              {result.message ||
                I18n.t('Target unreachable with remaining assignments')}
            </Alert>
          )}

          {!error && result?.status === 'already_met' && (
            <Alert variant="success" margin="small 0" data-testid="what-if-already-met-alert">
              {result.message ||
                I18n.t('You are already at or above this target based on your current grades.')}
            </Alert>
          )}

          {!error && successMessage && (
            <Alert variant="info" margin="small 0" data-testid="what-if-success-alert">
              {successMessage}
            </Alert>
          )}

          {!error && result?.status === 'success' && result.estimated_assignments?.length ? (
            <Text as="p" size="x-small" margin="small 0 0 0 0" color="secondary">
              {I18n.t(
                'Estimated points on remaining assignments appear in gray in the grades table. Click a score to adjust it.',
              )}
            </Text>
          ) : null}
        </View>

        {result?.disclaimer && (
          <Text as="p" size="x-small" margin="small 0 0 0 0" color="secondary">
            {result.disclaimer}
          </Text>
        )}
      </ToggleDetails>
    </View>
  )
}

export default WhatIfRequiredGradePanel
