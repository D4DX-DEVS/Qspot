// Phone numbers are Indian 10-digit mobiles for now. Every place that saves or
// looks up a number cleans it the same way, so "+91 98765 43210",
// "098765 43210" and "9876543210" are one account.
const normalizePhone = (raw) => {
  let phone = String(raw || '').replace(/\s+/g, '');
  if (phone.startsWith('+91')) phone = phone.slice(3);
  else if (phone.startsWith('91') && phone.length > 10) phone = phone.slice(2);
  else if (phone.startsWith('0')) phone = phone.replace(/^0+/, '');
  return phone.slice(-10);
};

module.exports = { normalizePhone };
