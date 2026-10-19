import { ShieldCheck } from 'lucide-react'
import Entrance from '../../../components/common/Entrance'
import AuthTextField from './AuthTextField'
import CheckboxRow from './CheckboxRow'

// Consent tick box. Once ticked it asks who gave consent (parent or school)
// and their name.
export default function ConsentCard({ form }) {
  return (
    <div className="rounded-2xl border border-line bg-soft-fill py-1.5 pr-3.5">
      <CheckboxRow
        checked={form.hasConsent}
        onChange={(v) => form.setHasConsent(v)}
        title="A parent/guardian or school has given consent"
        trailing={<ShieldCheck size={30} className={`shrink-0 text-brand/30 ${form.hasConsent ? 'qs-pop' : ''}`} aria-hidden="true" />}
      />
      {form.hasConsent ? (
        <div className="pl-2.5">
          <Entrance rise={10} className="flex gap-6 py-2" role="radiogroup" aria-label="Consent given by">
            {['parent', 'school'].map((option) => (
              <label key={option} className="flex min-h-10 cursor-pointer items-center gap-2 text-[13px] text-ink">
                <input
                  type="radio"
                  name="consent-by"
                  checked={form.consentBy === option}
                  onChange={() => form.setConsentBy(option)}
                  className="size-[18px] accent-[var(--qs-brand)]"
                />
                {option === 'parent' ? 'Parent' : 'School'}
              </label>
            ))}
          </Entrance>
          <Entrance index={1} rise={10} className="pb-2.5">
            <AuthTextField
              label={form.consentBy === 'parent' ? "Parent/Guardian's Name" : 'School Name'}
              value={form.consentName}
              onChange={(v) => form.setConsentName(v)}
              error={form.consentNameError}
            />
          </Entrance>
        </div>
      ) : null}
    </div>
  )
}
