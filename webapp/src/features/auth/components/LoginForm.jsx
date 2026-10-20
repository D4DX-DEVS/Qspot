import { CircleAlert, UserRound } from 'lucide-react'
import AuthPhoneField from './AuthPhoneField'
import AuthTextField from './AuthTextField'

// Name + phone number fields of the sign-in form, and the server's reason
// when a sign-in is turned down.
export default function LoginForm({ form }) {
  return (
    <div className="flex flex-col gap-3.5">
      <AuthTextField
        label="Full Name"
        icon={UserRound}
        autoCapitalize="words"
        autoComplete="name"
        value={form.name}
        onChange={(v) => form.setName(v)}
        error={form.nameError}
      />
      <AuthPhoneField
        value={form.phone}
        onChange={(v) => form.setPhone(v)}
        country={form.country}
        onCountryChange={(c) => form.setCountry(c)}
        error={form.phoneError}
      />
      {form.serverError ? (
        <p role="alert" className="flex items-start gap-2.5 rounded-2xl bg-coral-soft px-4 py-3 text-[13px] leading-normal text-ink">
          <CircleAlert size={18} className="mt-px shrink-0 text-coral" aria-hidden="true" />
          {form.serverError}
        </p>
      ) : null}
    </div>
  )
}
