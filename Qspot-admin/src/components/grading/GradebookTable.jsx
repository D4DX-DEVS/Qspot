import React from 'react';
import { cellLabel, percentLabel, toneFor } from '../../utils/gradebook';

const th = 'px-3 py-3 text-left align-bottom text-[10px] font-semibold uppercase tracking-[0.12em] text-white/45';
const td = 'whitespace-nowrap px-3 py-2.5 tabular-nums';
const sticky = 'sticky left-0 z-10 bg-[#130810]';

const cellClass = (cell) => {
  if (cell?.status === 'needs_mark') return 'rounded-md bg-[#EFB078] px-1.5 py-0.5 text-[11px] font-bold text-[#2B0A1C]';
  if (cell?.status === 'returned') return 'rounded-md border border-amber-200/50 px-1.5 py-0.5 text-[11px] text-amber-200';
  if (cell?.status === 'not_sat' || cell?.status === 'not_sent' || cell?.status === 'pending') return 'text-white/35';
  return `font-semibold ${toneFor(cell?.percent)}`;
};

// One row per learner, one column per exam and assignment. Cells that lead
// somewhere (a submission to mark, an exam attempt) are buttons.
const GradebookTable = ({ book, onOpenCell }) => (
  <div className="overflow-x-auto rounded-2xl border border-white/10 bg-white/[0.03]">
    <table className="min-w-full text-sm text-white/85">
      <thead className="border-b border-white/10">
        <tr>
          <th className={`${th} ${sticky}`}>Learner</th>
          {book.columns.map((column) => (
            <th key={column.id} className={`${th} min-w-[110px]`}>
              <span className="block max-w-[150px] whitespace-normal normal-case tracking-normal text-[12px] text-white/75">{column.title}</span>
              <span className="mt-0.5 block">{column.kind === 'exam' ? 'Exam' : `Out of ${column.maxPoints}`}</span>
            </th>
          ))}
          <th className={th}>Practice avg</th>
          <th className={th}>Lessons /{book.lessonsTotal}</th>
          <th className={th}>Overall</th>
        </tr>
      </thead>
      <tbody className="divide-y divide-white/5">
        {book.rows.map((row) => (
          <tr key={row.learner.id}>
            <td className={`${td} ${sticky} max-w-[180px] truncate font-semibold text-white`}>{row.learner.name || 'Unnamed'}</td>
            {book.columns.map((column) => {
              const cell = row.cells[column.id];
              const label = cellLabel(column, cell);
              const opens = cell?.submissionId || cell?.attemptId;
              return (
                <td key={column.id} className={td}>
                  {opens ? (
                    <button type="button" onClick={() => onOpenCell(column, cell, row)} className="rounded-md hover:ring-1 hover:ring-[#EFB078]/60 focus:outline-none focus:ring-2 focus:ring-[#EFB078]">
                      <span className={cellClass(cell)}>{label}</span>
                      {cell.late && cell.status !== 'needs_mark' && <span className="ml-1 text-[10px] text-rose-300">late</span>}
                    </button>
                  ) : <span className={cellClass(cell)}>{label}</span>}
                </td>
              );
            })}
            <td className={`${td} ${toneFor(row.practiceAvg)}`}>{percentLabel(row.practiceAvg)}</td>
            <td className={td}>{row.lessonsDone}</td>
            <td className={`${td} font-bold ${toneFor(row.overall)}`}>{percentLabel(row.overall)}</td>
          </tr>
        ))}
      </tbody>
      <tfoot className="border-t border-white/10 text-white/55">
        <tr>
          <td className={`${td} ${sticky} font-semibold`}>Class average</td>
          {book.columns.map((column) => <td key={column.id} className={td}>{percentLabel(book.averages[column.id])}</td>)}
          <td className={td}>{percentLabel(book.averages.practiceAvg)}</td>
          <td className={td}>{book.averages.lessonsDone ?? '—'}</td>
          <td className={td}>{percentLabel(book.averages.overall)}</td>
        </tr>
      </tfoot>
    </table>
  </div>
);

export default GradebookTable;
