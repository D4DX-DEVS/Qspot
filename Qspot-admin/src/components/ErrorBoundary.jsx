import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error, info) {
    console.error('Admin UI crashed:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-black px-6 text-center text-white">
          <p className="text-sm uppercase tracking-[0.3em] text-red-400">We couldn’t load this page</p>
          <h1 className="text-2xl font-bold">Something interrupted this screen</h1>
          <p className="max-w-md text-sm text-white/70">
            Reload the page to try again. If the problem continues, return to the dashboard and try another page.
          </p>
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="mt-2 rounded-xl bg-gradient-to-r from-[#701845] to-[#EFB078] px-5 py-2.5 text-sm font-semibold text-white"
          >
            Reload this page
          </button>
          <button
            type="button"
            onClick={() => window.location.assign('/admin/dashboard')}
            className="rounded-xl border border-white/20 px-5 py-2.5 text-sm font-semibold text-white"
          >
            Go to dashboard
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

export default ErrorBoundary;
