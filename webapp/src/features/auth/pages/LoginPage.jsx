import { Info, ShieldCheck } from 'lucide-react'
import { useLocation, useNavigate } from 'react-router-dom'
import Entrance from '../../../components/common/Entrance'
import IconNoteCard from '../../../components/common/IconNoteCard'
import InfoNoteCard from '../../../components/common/InfoNoteCard'
import OrDivider from '../../../components/common/OrDivider'
import LatticeBackdrop from '../../../components/scene/LatticeBackdrop'
import { REGISTRATION_ENABLED } from '../../../config/env'
import { useLocalNotifier, useNotifier } from '../../../lib/useNotifier'
import { signIn } from '../actions/authActions'
import AuthLinkRow from '../components/AuthLinkRow'
import GradientPillButton from '../components/GradientPillButton'
import LoginArtPanel from '../components/LoginArtPanel'
import LoginForm from '../components/LoginForm'
import WelcomeCard from '../components/WelcomeCard'
import { authStore } from '../stores/authStore'
import { LoginFormStore } from '../stores/loginFormStore'

// Sign-in: name + phone number on a glass card beside a night arch with the
// welcome words (wide screens), or on a sheet under a night sky (phones)
// (mobile-app/lib/screens/auth/screens/login_screen.dart).
export default function LoginPage() {
  const form = useLocalNotifier(() => new LoginFormStore())
  const auth = useNotifier(authStore)
  const navigate = useNavigate()
  const from = useLocation().state?.from

  return (
    <div className="relative min-h-dvh overflow-x-hidden bg-bg">
      <LatticeBackdrop glow="right" />
      <div className="relative flex min-h-dvh flex-col lg:grid lg:grid-cols-2">
        <LoginArtPanel />
        <main className="relative -mt-7 flex flex-1 flex-col lg:mt-0 lg:items-center lg:justify-center lg:px-[6%] lg:py-10">
          <Entrance index={1} className="flex w-full flex-1 flex-col lg:max-w-[520px] lg:flex-none">
            <WelcomeCard title="Welcome Back" subtitle="Sign in to continue to QSPOT">
              <form
                noValidate
                onSubmit={(e) => {
                  e.preventDefault()
                  // Always pressable: a press on an incomplete form says what is missing.
                  if (!auth.isLoading) signIn(form, navigate, from || '/quizzes')
                }}
              >
                <div className="mb-4">
                  <InfoNoteCard icon={Info} tone="slate" message="Please enter the name and phone number used during registration." />
                </div>
                <LoginForm form={form} />
                <div className="mt-6">
                  <GradientPillButton type="submit" label="Sign In" enabled loading={auth.isLoading} />
                </div>
                {REGISTRATION_ENABLED ? (
                  <div className="mt-5">
                    <OrDivider />
                    <div className="mt-2">
                      <AuthLinkRow prompt="Don't Have an Account?" action="Register Now" onClick={() => navigate('/register')} />
                    </div>
                  </div>
                ) : null}
                <div className="mt-6">
                  <IconNoteCard icon={ShieldCheck} title="Your learning journey is safe" message="We keep your information secure and private." />
                </div>
              </form>
            </WelcomeCard>
          </Entrance>
        </main>
      </div>
    </div>
  )
}
