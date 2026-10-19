import { UserRound } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import AuthPhoneField from './AuthPhoneField'
import AuthTextField from './AuthTextField'
import ClassSelectField from './ClassSelectField'
import ConsentCard from './ConsentCard'
import CoursePicker from './CoursePicker'

// The fields of the create-account form, in the app's order.
export default function RegistrationFields({ form }) {
  return (
    <div className="flex flex-col gap-3.5">
      <Entrance index={2}>
        <AuthPhoneField label="Phone Number" showPhoneIcon value={form.phone} onChange={(v) => form.setPhone(v)} error={form.phoneError} />
      </Entrance>
      <Entrance index={3}>
        <AuthTextField
          label="Full Name"
          icon={UserRound}
          autoCapitalize="words"
          autoComplete="name"
          value={form.name}
          onChange={(v) => form.setName(v)}
          error={form.nameError}
        />
      </Entrance>
      <Entrance index={4}>
        <ClassSelectField value={form.classNumber} onChange={(v) => form.setClassNumber(v)} error={form.classError} />
      </Entrance>
      <CoursePicker
        courses={form.courses}
        selectedIds={form.selectedCourseIds}
        loading={form.coursesLoading}
        onToggle={(id, selected) => form.toggleCourse(id, selected)}
      />
      <Entrance index={5}>
        <ConsentCard form={form} />
      </Entrance>
    </div>
  )
}
