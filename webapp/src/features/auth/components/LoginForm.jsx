import AuthPhoneField from './AuthPhoneField'
import ClassSelectField from './ClassSelectField'

// Phone number + class fields of the sign-in form.
export default function LoginForm({ form }) {
  return (
    <div className="flex flex-col gap-3.5">
      <AuthPhoneField value={form.phone} onChange={(v) => form.setPhone(v)} error={form.phoneError} />
      <ClassSelectField value={form.classNumber} onChange={(v) => form.setClassNumber(v)} error={form.classError} />
    </div>
  )
}
