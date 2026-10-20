import { useLocation, useNavigate } from 'react-router-dom'
import Entrance from '../../../components/common/Entrance'
import { REGISTRATION_ENABLED } from '../../../config/env'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import { signIn } from '../actions/authActions'
import { paintMosqueSkyline } from '../art/mosqueSkyline'
import ArchHeader from '../components/ArchHeader'
import AuthArt from '../components/AuthArt'
import AuthBrandMark from '../components/AuthBrandMark'
import AuthHeadline from '../components/AuthHeadline'
import AuthLinkRow from '../components/AuthLinkRow'
import AuthPageLayout from '../components/AuthPageLayout'
import GradientPillButton from '../components/GradientPillButton'
import LoginForm from '../components/LoginForm'
import { authStore } from '../stores/authStore'
import { LoginFormStore } from '../stores/loginFormStore'

// Sign-in: name + phone number, under a pointed arch over a mosque
// skyline (mobile-app/lib/screens/auth/screens/login_screen.dart).
export default function LoginPage() {
  const form = useLocalNotifier(() => new LoginFormStore())
  const auth = useNotifier(authStore)
  const navigate = useNavigate()
  const from = useLocation().state?.from

  return (
    <AuthPageLayout
      center
      artHeight="clamp(170px, 30dvh, 280px)"
      // Only the empty sky at the top of the art may sit under the form:
      // any deeper and the last row covers the crescent moon.
      overlap={0.1}
      bottomArt={<AuthArt paint={paintMosqueSkyline} />}
    >
      <form
        noValidate
        onSubmit={(e) => {
          e.preventDefault()
          // Always pressable: a press on an incomplete form says what is missing.
          if (!auth.isLoading) signIn(form, navigate, from || '/quizzes')
        }}
      >
        <Entrance index={0}>
          <ArchHeader>
            {/* Smaller on short screens (laptops, small phones) so the form and
                the skyline fit with less scrolling. */}
            <AuthBrandMark size={150} className="max-h-[17dvh] max-w-[17dvh]" />
            <AuthHeadline
              center
              title="Learn the "
              accent="Qur’ān"
              trailing={',\none episode at a time.'}
              subtitle="Sign in with your name and phone number to continue."
              fontSize={26}
              subtitleFontSize={13.5}
            />
          </ArchHeader>
        </Entrance>
        <Entrance index={1}>
          <LoginForm form={form} />
        </Entrance>
        <Entrance index={2} className="mt-5">
          <GradientPillButton type="submit" label="Sign In" enabled loading={auth.isLoading} />
        </Entrance>
        {REGISTRATION_ENABLED ? (
          <Entrance index={3} className="mt-4">
            <AuthLinkRow prompt="Don't Have an Account?" action="Register Now" onClick={() => navigate('/register')} />
          </Entrance>
        ) : null}
      </form>
    </AuthPageLayout>
  )
}
