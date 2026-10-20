import { createElement } from 'react'
import { CircleCheck } from 'lucide-react'
import NoticeSheet from '../../../components/common/NoticeSheet'
import { dialogStore } from '../../../stores/dialogStore'
import { submittedMessage } from '../models/answersAvailability'

// "Answers Submitted" while the score is held back until the quiz closes:
// shown right after submitting, and when a taken quiz is tapped in the list
// (quiz_submitted_notice.dart).
export const showSubmittedNotice = (availableAt) =>
  dialogStore.show(
    (close) =>
      createElement(NoticeSheet, {
        icon: CircleCheck,
        tone: 'mint',
        title: 'Answers Submitted',
        message: submittedMessage(availableAt),
        onClose: () => close(),
      }),
    { kind: 'sheet' },
  )
