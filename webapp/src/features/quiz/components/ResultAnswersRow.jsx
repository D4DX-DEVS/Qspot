import { Eye } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import OutlinedButton from '../../../components/common/OutlinedButton'
import AnswersHiddenNote from './AnswersHiddenNote'

// Under the scores: the review button, a button that first loads the answers,
// or when the answers will show.
export default function ResultAnswersRow({ result, loading, onReview, onLoadReview }) {
  let body = null
  if (result.results.length) body = <OutlinedButton icon={Eye} label="Review Answers" onClick={onReview} />
  else if (!result.answersRevealed) body = <AnswersHiddenNote availableAt={result.answersAvailableAt} />
  else if (result.attemptId) body = <OutlinedButton icon={Eye} label="Review Answers" loading={loading} onClick={onLoadReview} />
  return body ? <Entrance index={4}>{body}</Entrance> : null
}
