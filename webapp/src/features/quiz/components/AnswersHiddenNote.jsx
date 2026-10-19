import { Clock } from 'lucide-react'
import InfoNoteCard from '../../../components/common/InfoNoteCard'
import { answersHiddenMessage } from '../models/answersAvailability'

// When the correct answers will show, for a result the server still holds back.
export default function AnswersHiddenNote({ availableAt }) {
  return <InfoNoteCard icon={Clock} tone="slate" message={answersHiddenMessage(availableAt)} />
}
