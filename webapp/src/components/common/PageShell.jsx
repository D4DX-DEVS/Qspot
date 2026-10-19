// Page body under the app bar: phone-width content on small screens, a wider
// centred column on desktop.
export default function PageShell({ width = 'max-w-2xl', className = '', children }) {
  return <main className={`mx-auto w-full ${width} px-4 pb-[calc(28px+env(safe-area-inset-bottom))] pt-2 ${className}`}>{children}</main>
}
