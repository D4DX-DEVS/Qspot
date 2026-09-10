const axios = require('axios');
const bcrypt = require('bcryptjs');

// In-memory store for demo purposes. Replace with Redis/DB for production.
const store = new Map();

const env = {
  INSTANCE_ID: process.env.DXING_INSTANCE_ID,
  API_KEY: process.env.DXING_API_KEY,
  OTP_TTL_MS: 5 * 60 * 1000, // 5 minutes
  COOLDOWN_MS: 60 * 1000, // 60 seconds
  MAX_ATTEMPTS: 5,
  SEND_URL: 'https://app.dxing.in/api/send/otp',
};

function normalizePhone(p) {
  // TODO: normalize to E.164 if needed (e.g., using libphonenumber).
  return p;
}

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function maskPhone(p) {
  return p.replace(/.(?=.{4})/g, '*');
}

async function sendOtpViaDixing(phone, code) {
  // Adjust header and field names per Dixing’s official docs if they differ
  const headers = {
    Authorization: `Bearer ${env.API_KEY}`,
    'x-api-key': env.API_KEY, // some providers accept API key header style
    'Content-Type': 'application/json',
  };

  // Dixing API format - use our generated OTP directly in message
  const payload = {
    secret: env.API_KEY,
    type: 'whatsapp',
    message: `Your OTP is ${code}. Valid for 5 minutes.`,
    phone: phone,
    account: env.INSTANCE_ID,
    priority: 1
  };

  // If Dixing auto-generates OTPs instead, use:
  // const payload = { instance_id: env.INSTANCE_ID, to: phone, channel: 'whatsapp', auto: true };

  const res = await axios.post(env.SEND_URL, payload, { headers, timeout: 10000 });
  if (res.status < 200 || res.status >= 300) {
    throw new Error('Dixing OTP send failed');
  }
  if (res.data && res.data.success === false) {
    throw new Error(res.data.message || 'Dixing error');
  }
  // If provider returns an otp_id or reference, you can return/store it here
  return res.data;
}

async function requestWhatsappOtp(rawPhone) {
  const phone = normalizePhone(rawPhone);
  const key = `otp:${phone}`;
  const now = Date.now();

  const existing = store.get(key);
  if (existing && now - existing.lastSentAt < env.COOLDOWN_MS) {
    const wait = Math.ceil((env.COOLDOWN_MS - (now - existing.lastSentAt)) / 1000);
    return { ok: true, phone: maskPhone(phone), cooldown: wait };
  }

  const code = generateOtp();
  
  // Store the original code for direct comparison
  const record = { 
    originalCode: code, 
    expAt: now + env.OTP_TTL_MS, 
    attempts: 0, 
    lastSentAt: now 
  };
  store.set(key, record);

  await sendOtpViaDixing(phone, code);

  return { ok: true, phone: maskPhone(phone), cooldown: Math.floor(env.COOLDOWN_MS / 1000) };
}

async function verifyWhatsappOtp(rawPhone, code) {
  const phone = normalizePhone(rawPhone);
  const key = `otp:${phone}`;
  
  // Get the stored record
  const record = store.get(key);
  
  // Check if record exists
  if (!record) {
    return { ok: false, error: 'No OTP found. Please request a new OTP.' };
  }
  
  // Check if expired
  const now = Date.now();
  if (now > record.expAt) {
    store.delete(key);
    return { ok: false, error: 'OTP expired. Please request a new OTP.' };
  }
  
  // Check attempts
  if (record.attempts >= env.MAX_ATTEMPTS) {
    store.delete(key);
    return { ok: false, error: 'Too many attempts. Please request a new OTP.' };
  }
  
  // Increment attempts
  record.attempts += 1;
  
  // Compare the code directly
  const storedCode = record.originalCode;
  
  if (code !== storedCode) {
    return { ok: false, error: 'Invalid OTP code.' };
  }
  
  // Success - delete the record
  store.delete(key);
  return { ok: true };
}

module.exports = {
  requestWhatsappOtp,
  verifyWhatsappOtp,
};


