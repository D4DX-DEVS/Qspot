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
          <p className="text-sm uppercase tracking-[0.3em] text-red-400">Something went wrong</p>
          <h1 className="text-2xl font-bold">This page hit an unexpected error</h1>
          <button
            type="button"
            onClick={() => window.location.assign('/admin/dashboard')}
            className="mt-2 rounded-xl bg-gradient-to-r from-[#701845] to-[#EFB078] px-5 py-2.5 text-sm font-semibold text-white"
          >
            Back to dashboard
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

export default ErrorBoundary;
