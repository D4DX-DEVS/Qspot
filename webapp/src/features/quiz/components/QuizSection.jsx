import Entrance from '../../../components/common/Entrance'
import SectionHeader from '../../../components/common/SectionHeader'
import ViewAllButton from '../../../components/common/ViewAllButton'
import QuizListCard from './QuizListCard'

// "Live Quizzes", "Upcoming Quizzes" or "Past Quizzes" with its quiz cards,
// the first few only until "View All" ([sections] holds which are open).
export default function QuizSection({ id, title, icon, iconClass, quizzes, started, onOpen, sections }) {
  const open = sections.isOpen(id)
  const listId = `${id}-list`
  return (
    <section id={id} className="mt-8 scroll-mt-4">
      <SectionHeader
        title={title}
        icon={icon}
        iconClass={iconClass}
        action={sections.hasMore(quizzes) ? <ViewAllButton open={open} controls={listId} onClick={() => sections.toggle(id)} /> : null}
      />
      <div id={listId} className="mt-3 flex flex-col gap-3.5">
        {sections.visible(id, quizzes).map((quiz, index) => (
          <Entrance key={quiz.id} index={index}>
            <QuizListCard quiz={quiz} record={started?.get(quiz.id)} onOpen={onOpen} />
          </Entrance>
        ))}
      </div>
    </section>
  )
}
