import Entrance from '../../../components/common/Entrance'
import SectionHeader from '../../../components/common/SectionHeader'
import QuizListCard from './QuizListCard'

// "Live Now", "Coming Up" or "Past Quizzes" with its quiz cards.
export default function QuizSection({ title, emoji, quizzes, onOpen }) {
  return (
    <section className="mt-4">
      <SectionHeader title={title} emoji={emoji} />
      <div className="mt-1 grid gap-3 md:grid-cols-2">
        {quizzes.map((quiz, index) => (
          <Entrance key={quiz.id} index={index} className="h-full">
            <QuizListCard quiz={quiz} onOpen={onOpen} />
          </Entrance>
        ))}
      </div>
    </section>
  )
}
