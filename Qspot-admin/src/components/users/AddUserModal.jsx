import Modal from '../ui/Modal';
import FormField from '../ui/FormField';
import TextInput from '../ui/TextInput';
import SegmentedControl from '../ui/SegmentedControl';
import { FacultySelect } from '../ui/EntitySelect';
import useAddUserForm, { ROLE_OPTIONS } from '../../hooks/useAddUserForm';
import { dobInputLimits } from '../../utils/dob';

// Users page dialog for creating a student or teacher account. The fields
// change with the kind of account because each signs in differently.
const AddUserModal = ({ onClose, onCreated }) => {
  const { form, setField, saving, error, submit, isTeacher, classError, checkClass } = useAddUserForm(onCreated);
  const dobLimits = dobInputLimits();

  const handleSubmit = (e) => {
    e.preventDefault();
    submit();
  };

  return (
    <Modal title="Add User" subtitle="New account" onClose={onClose}>
      <form onSubmit={handleSubmit} className="space-y-5">
        <div className="space-y-2">
          <SegmentedControl
            label="Account type"
            options={ROLE_OPTIONS}
            value={form.role}
            onChange={(role) => setField('role', role)}
          />
          <p className="text-xs text-white/50">
            {isTeacher
              ? 'Signs in to the app with their phone number and date of birth ("Teacher? Sign in with date of birth").'
              : 'Signs in to the app with this name and phone number.'}
          </p>
        </div>

        <FormField
          label="Name"
          htmlFor="add-user-name"
          hint={isTeacher ? undefined : 'They must type the same name to sign in (spaces and capitals don’t matter).'}
        >
          <TextInput
            id="add-user-name"
            value={form.name}
            onChange={(value) => setField('name', value)}
            placeholder="Enter full name"
            minLength={3}
            required
          />
        </FormField>

        <FormField label="Phone" htmlFor="add-user-phone" hint="Outside India, start with + and the country code, e.g. +44 7400 123456.">
          <TextInput
            id="add-user-phone"
            type="tel"
            value={form.phone}
            onChange={(value) => setField('phone', value)}
            placeholder="Enter phone number"
            required
          />
        </FormField>

        {isTeacher ? (
          <>
            <FormField label="Date of birth" htmlFor="add-user-dob" hint="They sign in with this date.">
              <TextInput
                id="add-user-dob"
                type="date"
                value={form.dob}
                onChange={(value) => setField('dob', value)}
                min={dobLimits.min}
                max={dobLimits.max}
                required
              />
            </FormField>
            <FormField
              label="Teacher profile"
              hint="Their profile from Speakers. Their teacher screens show the questions and work for this profile."
            >
              <FacultySelect
                value={form.facultyProfile}
                onChange={(value) => setField('facultyProfile', value)}
                placeholder="Select from Speakers"
                required
              />
            </FormField>
          </>
        ) : (
          <FormField
            label="Class"
            htmlFor="add-user-class"
            hint="Class 8 to 12 only."
            error={classError}
            errorId="add-user-class-error"
          >
            <TextInput
              id="add-user-class"
              inputMode="numeric"
              autoComplete="off"
              value={form.class}
              onChange={(value) => setField('class', value)}
              onBlur={checkClass}
              placeholder="Enter class (8 to 12)"
              aria-invalid={Boolean(classError)}
              aria-describedby={classError ? 'add-user-class-error' : undefined}
              className={classError ? 'border-red-400/60! focus:border-red-400/80!' : ''}
            />
          </FormField>
        )}

        <FormField label="Email (optional)" htmlFor="add-user-email">
          <TextInput
            id="add-user-email"
            type="email"
            value={form.email}
            onChange={(value) => setField('email', value)}
            placeholder="Enter email address"
          />
        </FormField>

        {error && (
          <p role="alert" className="rounded-2xl border border-red-400/30 bg-red-900/20 px-4 py-3 text-sm text-red-200">
            {error}
          </p>
        )}

        <div className="flex flex-col-reverse items-stretch justify-end gap-3 pt-2 sm:flex-row sm:items-center">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg border border-white/10 bg-white/5 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white/75 hover:bg-white/10 hover:text-white"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving}
            className="rounded-lg bg-gradient-to-r from-[#701845]/90 via-[#9E4B63]/80 to-[#EFB078]/85 px-5 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-white shadow-[0_16px_34px_rgba(136,32,82,0.45)] disabled:opacity-50"
          >
            {saving ? 'Creating...' : 'Create Account'}
          </button>
        </div>
      </form>
    </Modal>
  );
};

export default AddUserModal;
