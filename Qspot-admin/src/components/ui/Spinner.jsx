// Single spinner used everywhere a page/section is loading.
const Spinner = ({ size = 'h-10 w-10', className = '' }) => (
  <div className={`flex items-center justify-center py-10 ${className}`}>
    <div className={`animate-spin rounded-full ${size} border-b-2 border-[#EFB078]`} />
  </div>
);

export default Spinner;
