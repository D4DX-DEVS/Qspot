import { useEffect, useState } from 'react';
import apiClient from '../../api/client';

// Generic "pick one document from an admin list endpoint" <select>.
// FacultySelect / SubjectSelect / CourseSelect below are thin wrappers so
// call sites keep a descriptive name while sharing one fetch+render
// implementation (previously duplicated per page).
const EntitySelect = ({
  path,
  value,
  onChange,
  labelKey = 'name',
  placeholder = 'Select…',
  required = false,
  className = '',
  extractItems = (data) => (Array.isArray(data) ? data : data?.items || []),
  includeAllOption = false,
  allLabel = 'All',
}) => {
  const [options, setOptions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    setLoading(true);
    apiClient
      .get(path)
      .then((res) => {
        if (active) setOptions(extractItems(res.data));
      })
      .catch(() => {
        if (active) setOptions([]);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [path]);

  return (
    <select
      value={value || ''}
      onChange={(e) => onChange(e.target.value)}
      required={required}
      disabled={loading}
      className={`block w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white backdrop-blur-sm transition-all focus:border-[#EFB078]/60 focus:outline-none ${className}`}
    >
      <option value="">{loading ? 'Loading…' : includeAllOption ? allLabel : placeholder}</option>
      {options.map((opt) => (
        <option key={opt._id} value={opt._id} className="bg-black">
          {opt[labelKey] || opt.name || opt.title}
        </option>
      ))}
    </select>
  );
};

export const FacultySelect = (props) => (
  <EntitySelect path="/speakers" placeholder="Select a faculty" {...props} />
);

export const SubjectSelect = (props) => (
  <EntitySelect path="/subjects" placeholder="Select a subject" {...props} />
);

export const CourseSelect = (props) => (
  <EntitySelect path="/courses" placeholder="Select a course" {...props} />
);

export default EntitySelect;
