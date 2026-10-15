// Shared page header: eyebrow label + title + optional description and
// action button, used at the top of every admin page for a consistent
// look and spacing.
const PageHeader = ({ eyebrow = 'Admin Dashboard', title, description, actions }) => (
  <div className="mb-6 flex flex-row flex-wrap items-end justify-between gap-4 sm:mb-8">
    <div className="space-y-1.5">
      {eyebrow && <p className="text-xs uppercase tracking-[0.3em] text-white/50">{eyebrow}</p>}
      <h1 className="text-2xl font-bold text-white sm:text-3xl">{title}</h1>
      {description && <p className="max-w-2xl text-sm text-slate-400">{description}</p>}
    </div>
    {actions && <div className="flex flex-wrap items-center gap-3">{actions}</div>}
  </div>
);

export default PageHeader;
