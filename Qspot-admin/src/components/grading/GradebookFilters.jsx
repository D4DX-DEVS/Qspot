import React, { useEffect, useState } from 'react';
import apiClient from '../../api/client';
import { CourseSelect } from '../ui/EntitySelect';

const classLabel = (value) => (/^\d+$/.test(value) ? `Class ${value}` : value);

// Class and course pickers shared by the gradebook and the marking queue.
const GradebookFilters = ({ cls, courseId, onClass, onCourse }) => {
  const [classes, setClasses] = useState([]);

  useEffect(() => {
    let active = true;
    apiClient.get('/admin/gradebook/classes')
      .then((response) => { if (active) setClasses(Array.isArray(response.data) ? response.data : []); })
      .catch(() => { if (active) setClasses([]); });
    return () => { active = false; };
  }, []);

  return (
    <div className="mb-5 flex flex-col gap-3 sm:flex-row">
      <select
        id="gradebook-class"
        value={cls}
        onChange={(event) => onClass(event.target.value)}
        className="w-full rounded-2xl border border-white/10 bg-[#160b17] px-4 py-3 text-sm text-white outline-none sm:w-56"
      >
        <option value="">All classes</option>
        {classes.map((value) => <option key={value} value={value}>{classLabel(value)}</option>)}
      </select>
      <div className="w-full sm:w-72">
        <CourseSelect value={courseId} onChange={onCourse} includeAllOption allLabel="All courses" />
      </div>
    </div>
  );
};

export default GradebookFilters;
