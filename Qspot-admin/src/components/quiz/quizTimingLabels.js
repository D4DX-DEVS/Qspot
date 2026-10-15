// Plain-language labels for the per-question status the API records with each
// attempt (see Qspot-API/services/quizTiming.js).
export const QUESTION_STATUS = {
  answered: { label: 'Answered', className: 'bg-green-900/50 text-green-200' },
  skipped: { label: 'Skipped', className: 'bg-amber-900/50 text-amber-200' },
  timed_out: { label: 'Time ran out', className: 'bg-red-900/50 text-red-200' },
  not_reached: { label: 'Not reached', className: 'bg-gray-700/60 text-gray-300' },
};
