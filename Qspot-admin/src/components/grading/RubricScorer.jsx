import React from 'react';

// One row per part with a button for each score (or a number box for parts
// out of more than 10), and the total underneath.
const RubricScorer = ({ criteria, scores, onScore }) => {
  const total = scores.reduce((sum, value) => sum + (value === '' || value === null || value === undefined ? 0 : Number(value)), 0);
  const max = criteria.reduce((sum, part) => sum + Number(part.maxPoints || 0), 0);

  return (
    <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
      <p className="mb-2 text-[10px] font-semibold uppercase tracking-[0.16em] text-white/40">Mark each part</p>
      <div className="space-y-2.5">
        {criteria.map((part, index) => (
          <div key={`${part.label}-${index}`} className="flex flex-wrap items-center justify-between gap-2">
            <span className="min-w-0 flex-1 break-words text-sm text-white/80">{part.label}</span>
            {part.maxPoints <= 10 ? (
              <div className="flex flex-wrap gap-1" role="group" aria-label={`${part.label}, out of ${part.maxPoints}`}>
                {Array.from({ length: part.maxPoints + 1 }, (_, points) => {
                  const on = scores[index] !== '' && Number(scores[index]) === points;
                  return (
                    <button
                      key={points}
                      type="button"
                      aria-pressed={on}
                      onClick={() => onScore(index, points)}
                      className={`h-7 w-7 rounded-md border text-xs font-bold ${on ? 'border-[#EFB078] bg-[#EFB078] text-[#2B0A1C]' : 'border-white/15 text-white/70 hover:border-white/40'}`}
                    >
                      {points}
                    </button>
                  );
                })}
              </div>
            ) : (
              <span className="flex items-center gap-1.5 text-xs text-white/50">
                <input
                  id={`rubric-score-${index}`}
                  type="number"
                  min="0"
                  max={part.maxPoints}
                  value={scores[index]}
                  onChange={(event) => onScore(index, event.target.value)}
                  className="w-20 rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-sm text-white outline-none focus:border-[#EFB078]/60"
                />
                / {part.maxPoints}
              </span>
            )}
          </div>
        ))}
      </div>
      <p className="mt-3 border-t border-white/10 pt-2 text-right text-sm text-white/70">
        Total <b className="text-[#EFB078]">{total} / {max}</b>
      </p>
    </div>
  );
};

export default RubricScorer;
