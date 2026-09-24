// Shared error box with a working Retry button. Callers must clear their
// `error` state at the START of the fetch (before the request goes out) so
// Retry actually recovers instead of re-rendering the same error forever.
const ErrorState = ({ message, onRetry }) => (
  <div className="rounded-2xl border border-red-500/30 bg-red-900/20 px-4 py-3 text-red-300">
    <span>{message || 'Something went wrong.'}</span>
    {onRetry && (
      <button
        type="button"
        onClick={onRetry}
        className="ml-4 font-semibold text-red-200 underline hover:text-white"
      >
        Retry
      </button>
    )}
  </div>
);

export default ErrorState;
