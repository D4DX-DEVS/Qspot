import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import Entrance from '../../../components/common/Entrance'
import { useIsDark } from '../../../lib/colorScheme'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import { register } from '../actions/authActions'
import { paintMosqueSkyline } from '../art/mosqueSkyline'
import { paintBottomWaves, paintCornerWave } from '../art/waves'
import AuthArt from '../components/AuthArt'
import AuthBackButton from '../components/AuthBackButton'
import AuthBrandMark from '../components/AuthBrandMark'
import AuthHeadline from '../components/AuthHeadline'
import AuthPageLayout from '../components/AuthPageLayout'
import GradientPillButton from '../components/GradientPillButton'
import RegistrationFields from '../components/RegistrationFields'
import { authStore } from '../stores/authStore'
import { RegistrationFormStore } from '../stores/registrationFormStore'

const skylineOnly = (ctx, w, h, palette) => paintMosqueSkyline(ctx, w, h, palette, { showBookStand: false })

// Create-account form (mobile-app/lib/screens/auth/screens/registration_screen.dart).
// Built but hidden: shown only when VITE_ENABLE_REGISTRATION is true.
export default function RegistrationPage() {
  const form = useLocalNotifier(() => new RegistrationFormStore())
  const auth = useNotifier(authStore)
  const navigate = useNavigate()
  const isDark = useIsDark()

  useEffect(() => {
    form.loadCourses()
  }, [form])

  return (
    <AuthPageLayout
      topArt={<AuthArt paint={paintCornerWave} />}
      topArtHeight={230}
      artHeight="120px"
      bottomArt={<AuthArt paint={isDark ? skylineOnly : paintBottomWaves} />}
    >
      <form
        noValidate
        onSubmit={(e) => {
          e.preventDefault()
          if (form.isComplete && !auth.isLoading) register(form, navigate)
        }}
      >
        <Entrance index={0} className="relative">
          <AuthBrandMark size={116} />
          <div className="absolute left-0 top-0">
            <AuthBackButton onClick={() => navigate('/login')} />
          </div>
        </Entrance>
        <Entrance index={1}>
          <AuthHeadline
            title="Create Your "
            accent="Account"
            subtitle="Your number and class sign you in, so there is no password to remember."
          />
        </Entrance>
        <div className="mt-6">
          <RegistrationFields form={form} />
        </div>
        <Entrance index={6} className="mt-6">
          <GradientPillButton type="submit" label="Create Account" enabled={form.isComplete} loading={auth.isLoading} />
        </Entrance>
        <Entrance index={6} as="p" className="mt-4 text-center text-[12.5px] leading-[1.4] text-muted">
          We only use your number and class to sign you in.
        </Entrance>
      </form>
    </AuthPageLayout>
  )
}
