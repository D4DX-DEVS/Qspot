// Defaults, editing values and the list summary for admin announcements.

export const emptyAnnouncementOptions = () => ({
  audience: { kind: 'all', value: '' },
  target: { kind: 'none', id: '' },
  sendAt: '',
});

export const announcementOptionsFrom = (notification) => ({
  audience: notification.audience || { kind: 'all', value: '' },
  target: notification.target || { kind: 'none', id: '' },
  sendAt: notification.sendAt || '',
});

// One line for the list: who, what it opens, and sent or scheduled.
export const announcementSummary = (notification) => {
  const audience = notification.audience?.kind === 'class'
    ? `Class ${notification.audience.value}`
    : notification.audience?.kind === 'course' ? 'One course' : 'All learners';
  const opens = notification.target?.kind && notification.target.kind !== 'none' ? ` · opens ${notification.target.kind}` : '';
  const when = notification.dispatchedAt
    ? ` · sent to ${notification.recipientCount || 0}`
    : notification.sendAt && new Date(notification.sendAt) > new Date()
      ? ` · scheduled ${new Date(notification.sendAt).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' })}`
      : ' · sending soon';
  return `${audience}${opens}${when}`;
};
