// Marking by parts ("rubric"): helpers shared by the assignment form and
// the marking panel. The server checks the same rules (services/rubric.js).

export const MAX_RUBRIC_PARTS = 8;

export const emptyRubric = () => ({ enabled: false, criteria: [] });

export const rubricFrom = (assignment) => ({
  enabled: Boolean(assignment?.rubric?.enabled),
  criteria: (assignment?.rubric?.criteria || []).map((part) => ({ label: part.label, maxPoints: part.maxPoints })),
});

export const isRubricOn = (rubric) => Boolean(rubric?.enabled && rubric.criteria?.length);

export const rubricTotal = (rubric) =>
  (rubric?.criteria || []).reduce((sum, part) => sum + (Number(part.maxPoints) || 0), 0);

// The rubric to send, or an error message for the form.
export const rubricForSave = (rubric) => {
  const criteria = (rubric.criteria || []).map((part) => ({ label: String(part.label || '').trim(), maxPoints: Number(part.maxPoints) }));
  if (!rubric.enabled) return { rubric: { enabled: false, criteria: criteria.filter((p) => p.label && Number.isInteger(p.maxPoints) && p.maxPoints >= 1) } };
  if (!criteria.length) return { error: 'Add at least one part to mark by parts.' };
  if (criteria.some((p) => !p.label)) return { error: 'Give every part a name.' };
  if (criteria.some((p) => !Number.isInteger(p.maxPoints) || p.maxPoints < 1 || p.maxPoints > 1000)) {
    return { error: 'Each part must be out of a whole number between 1 and 1000.' };
  }
  if (rubricTotal({ criteria }) > 1000) return { error: 'The parts can add up to at most 1000 points.' };
  return { rubric: { enabled: true, criteria } };
};
