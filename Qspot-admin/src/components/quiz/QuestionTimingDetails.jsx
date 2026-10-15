import React from 'react';
import { QUESTION_STATUS } from './quizTimingLabels';

export const QuestionStatusBadge = ({ status }) => {
  const known = QUESTION_STATUS[status];
  if (!known) return null;
  return (
    <span className={`inline-flex items-center px-1.5 py-0.5 text-[10px] font-semibold rounded-full ${known.className}`}>
      {known.label}
    </span>
  );
};

// Time the student took on one question. Shows nothing for attempts from app
// versions that sent no timing.
const QuestionTimingDetails = ({ result }) => {
  if (!result?.status) return null;
  return (
    <div className="mt-2.5 border-t border-white/5 pt-2.5">
      <div>
        <label className="block text-[10px] font-medium text-gray-400">Time taken</label>
        <p className="text-[12px] font-semibold text-gray-200">{(Number(result.duration) || 0).toFixed(1)} s</p>
      </div>
    </div>
  );
};

export default QuestionTimingDetails;
