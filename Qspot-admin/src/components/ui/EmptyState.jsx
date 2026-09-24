// Shared "nothing here yet" placeholder for lists/tables.
const EmptyState = ({ icon: Icon, title = 'Nothing here yet', description, action }) => (
  <div className="flex flex-col items-center gap-3 py-14 text-center text-white/70">
    {Icon && <Icon className="text-white/30" size={40} />}
    <p className="text-lg font-semibold text-white">{title}</p>
    {description && <p className="max-w-sm text-sm text-white/50">{description}</p>}
    {action}
  </div>
);

export default EmptyState;
