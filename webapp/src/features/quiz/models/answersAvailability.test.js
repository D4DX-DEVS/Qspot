import { describe, expect, it } from 'vitest'
import { answersHiddenMessage, submittedMessage } from './answersAvailability'

const NOW = new Date(2026, 9, 20, 15, 0)

describe('answers and score availability', () => {
  it('says when the correct answers show', () => {
    expect(answersHiddenMessage(new Date(2026, 9, 20, 17, 5), NOW)).toBe(
      'Correct answers show after 5:05 pm today, once everyone has finished.',
    )
    expect(answersHiddenMessage(null, NOW)).toContain("aren't shown")
  })

  it('confirms the submit and says when the score shows', () => {
    expect(submittedMessage(new Date(2026, 9, 20, 17, 5), NOW)).toBe(
      'Your answers have been submitted. Your score will show after 5:05 pm today, once everyone has finished.',
    )
    expect(submittedMessage(new Date(2026, 9, 21, 9, 30), NOW)).toBe(
      'Your answers have been submitted. Your score will show after 9:30 am on 21 Oct, once everyone has finished.',
    )
    expect(submittedMessage(null, NOW)).toBe('Your answers have been submitted. Your score will show once the quiz has closed.')
  })
})
