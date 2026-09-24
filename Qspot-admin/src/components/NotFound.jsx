import { Link } from 'react-router-dom';

const NotFound = () => (
  <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-black px-6 text-center text-white">
    <p className="text-sm uppercase tracking-[0.3em] text-white/50">404</p>
    <h1 className="text-3xl font-bold">Page not found</h1>
    <p className="max-w-sm text-white/60">The page you're looking for doesn't exist or may have moved.</p>
    <Link
      to="/admin/dashboard"
      className="mt-2 rounded-xl bg-gradient-to-r from-[#701845] to-[#EFB078] px-5 py-2.5 text-sm font-semibold text-white"
    >
      Back to dashboard
    </Link>
  </div>
);

export default NotFound;
