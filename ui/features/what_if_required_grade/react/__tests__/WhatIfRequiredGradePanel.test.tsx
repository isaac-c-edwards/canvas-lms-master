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

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import axios from '@canvas/axios'
import {dispatchPathToGoalEstimates} from '../../../grade_summary/jquery/pathToGoalEstimates'
import WhatIfRequiredGradePanel from '../WhatIfRequiredGradePanel'

vi.mock('@canvas/axios', () => ({
  default: {
    get: vi.fn(),
  },
}))

vi.mock('../../../grade_summary/jquery/pathToGoalEstimates', () => ({
  dispatchPathToGoalEstimates: vi.fn(),
}))

const mockedGet = vi.mocked(axios.get)
const mockedDispatch = vi.mocked(dispatchPathToGoalEstimates)

describe('WhatIfRequiredGradePanel', () => {
  beforeEach(() => {
    mockedGet.mockResolvedValue({
      data: {
        target_percent: 85,
        status: 'success',
        required_uniform_percent: 72.5,
        current_percent: 68,
        weighted: false,
        disclaimer: 'Drop lowest rules are not included in this calculation.',
        message: null,
        estimated_assignments: [
          {
            assignment_id: 99,
            title: 'Final Exam',
            points_possible: 200,
            estimated_points: 150,
          },
        ],
      },
    })
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.clearAllMocks()
  })

  it('does not fetch or show controls until the student opens the tool', async () => {
    const {getByTestId, queryByTestId} = render(
      <WhatIfRequiredGradePanel courseId="42" />,
    )

    expect(getByTestId('what-if-required-grade-panel')).toBeInTheDocument()
    expect(queryByTestId('what-if-target-slider')).not.toBeInTheDocument()
    expect(mockedGet).not.toHaveBeenCalled()
  })

  it('shows success path messaging after the student opens the tool', async () => {
    const user = userEvent.setup()
    const {getByTestId, findByTestId} = render(
      <WhatIfRequiredGradePanel courseId="42" />,
    )

    await user.click(getByTestId('what-if-tool-toggle'))

    await waitFor(() => {
      expect(mockedGet).toHaveBeenCalledWith(
        '/api/v1/courses/42/what_if/required_grade',
        expect.objectContaining({params: {target_percent: 85}}),
      )
    })

    expect(await findByTestId('what-if-success-alert')).toBeInTheDocument()
  })

  it('shows unreachable messaging when API returns unreachable', async () => {
    mockedGet.mockResolvedValue({
      data: {
        target_percent: 95,
        status: 'unreachable',
        required_uniform_percent: null,
        current_percent: 60,
        weighted: false,
        disclaimer: 'Drop lowest rules are not included in this calculation.',
        message: 'Target unreachable with remaining assignments',
      },
    })

    const user = userEvent.setup()
    const {getByTestId, findByTestId} = render(
      <WhatIfRequiredGradePanel courseId="42" />,
    )

    await user.click(getByTestId('what-if-tool-toggle'))

    expect(await findByTestId('what-if-unreachable-alert')).toHaveTextContent(
      'Target unreachable with remaining assignments',
    )
  })

  it('clears table estimates when the student closes the tool', async () => {
    const user = userEvent.setup()
    const {getByTestId, findByTestId} = render(
      <WhatIfRequiredGradePanel courseId="42" />,
    )

    await user.click(getByTestId('what-if-tool-toggle'))
    await findByTestId('what-if-success-alert')

    mockedDispatch.mockClear()
    await user.click(getByTestId('what-if-tool-toggle'))

    expect(mockedDispatch).toHaveBeenCalledWith([])
  })

  it('exposes distinct accessible names for slider and number input', async () => {
    const user = userEvent.setup()
    const {getByRole, getByTestId} = render(
      <WhatIfRequiredGradePanel courseId="42" />,
    )

    await user.click(getByTestId('what-if-tool-toggle'))

    expect(getByRole('slider', {name: 'Target grade (%)'})).toBeInTheDocument()
    expect(getByRole('spinbutton', {name: 'Target grade precise value (%)'})).toBeInTheDocument()
  })

  it('announces status updates in an aria-live region when expanded', async () => {
    const user = userEvent.setup()
    const {container, getByTestId} = render(<WhatIfRequiredGradePanel courseId="42" />)

    await user.click(getByTestId('what-if-tool-toggle'))

    const liveRegion = container.querySelector('[aria-live="polite"]')
    expect(liveRegion).toBeInTheDocument()
    expect(liveRegion).toHaveAttribute('aria-atomic', 'true')
  })

  it('passes AbortSignal to the API and aborts when the tool closes', async () => {
    const pendingSignals: AbortSignal[] = []
    mockedGet.mockImplementation((_url, config) => {
      if (config?.signal) pendingSignals.push(config.signal)
      return new Promise(() => {})
    })

    const user = userEvent.setup()
    const {getByTestId} = render(<WhatIfRequiredGradePanel courseId="42" />)

    await user.click(getByTestId('what-if-tool-toggle'))

    await waitFor(() => {
      expect(pendingSignals.length).toBeGreaterThanOrEqual(1)
      expect(pendingSignals[0]).toBeInstanceOf(AbortSignal)
    })

    await user.click(getByTestId('what-if-tool-toggle'))

    await waitFor(() => {
      expect(pendingSignals[0].aborted).toBe(true)
    })
  })
})
