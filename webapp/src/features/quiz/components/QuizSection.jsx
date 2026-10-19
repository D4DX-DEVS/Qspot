import Entrance from '../../../components/common/Entrance'
import SectionHeader from '../../../components/common/SectionHeader'
import QuizListCard from './QuizListCard'

// "Live Now", "Upcoming" or "Ended" with its quiz cards.
export default function QuizSection({ title, quizzes, onOpen }) {
  return (
    <section className="mt-2">
      <SectionHeader title={title} />
      <div className="mt-1 grid gap-3 md:grid-cols-2">
        {quizzes.map((quiz, index) => (
          <Entrance key={quiz.id} index={index}>
            <QuizListCard quiz={quiz} onOpen={onOpen} />
          </Entrance>
        ))}
      </div>
    </section>
  )
}
