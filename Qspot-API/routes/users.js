const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const fs = require('fs/promises');
const path = require('path');
const User = require('../models/user');
const Question = require('../models/question');
const Video = require('../models/videos');
const Subject = require('../models/subject');
const Course = require('../models/course');
const VideoProgress = require('../models/videoProgress');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const Quiz = require('../models/quiz');
const QuizConfig = require('../models/quizConfig');
const QuizSession = require('../models/quizSession');
const Schedule = require('../models/schedule');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');
const { requestWhatsappOtp, verifyWhatsappOtp } = require('../services/otpWhatsapp');
const { authenticateUser } = require('../middlewares/auth');
const { learnerSubjects } = require('../services/learnerScope');
const { parseUpcomingLimit } = require('../services/upcomingLimit');
const { buildProgressSummary } = require('../services/progressSummary');
const { parseDob, sameDob } = require('../services/dob');
const { sameName } = require('../services/nameKey');
const { isStudent, studentByName, nameTakenOnPhone } = require('../services/sharedPhone');
const { examAnswersAt, answersRevealed, revealFields } = require('../services/answerReveal');
const { publicUser } = require('../services/publicUser');
const { shapeVideo } = require('../services/videoShape');
const { normalizePhone, phoneError } = require('../services/phone');
const { isAccessible } = require('../services/quizAccess');
const { REGISTRATION_OPEN } = require('../services/registration');
const {
  profileUpload,
  CDN_ENABLED,
  getCdnUrl,
  deleteFile
} = require('../services/cdnStorageService');

const router = express.Router();

const asDate = (value) => {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

const isoOrNull = (value) => {
  const date = asDate(value);
  return date ? date.toISOString() : null;
};

const dayKey = (value, offsetMinutes = 0) => {
  const date = asDate(value);
  return date ? new Date(date.getTime() + offsetMinutes * 60 * 1000).toISOString().slice(0, 10) : null;
};

const dayBefore = (value) => {
  const date = asDate(value);
  if (!date) return null;
  return new Date(date.getTime() - 24 * 60 * 60 * 1000);
};

const previousDayKey = (key) => dayKey(dayBefore(`${key}T00:00:00.000Z`));

const activityStreak = (timestamps, now = new Date(), offsetMinutes = 0) => {
  const days = new Set(timestamps.map((value) => dayKey(value, offsetMinutes)).filter(Boolean));
  const sorted = [...days].sort().reverse();
  const today = dayKey(now, offsetMinutes);
  const yesterday = dayKey(dayBefore(now), offsetMinutes);
  const lastActivityDate = sorted[0] || null;

  let current = 0;
  let cursor = days.has(today) ? today : days.has(yesterday) ? yesterday : null;
  while (cursor && days.has(cursor)) {
    current += 1;
    cursor = previousDayKey(cursor);
  }

  let longest = 0;
  for (const start of sorted) {
    let run = 1;
    let cursorDay = previousDayKey(start);
    while (cursorDay && days.has(cursorDay)) {
      run += 1;
      cursorDay = previousDayKey(cursorDay);
    }
    if (run > longest) longest = run;
  }

  return {
    current,
    longest,
    timezoneOffsetMinutes: offsetMinutes,
    // There is no persisted grace-day entitlement in the current schema. Keep
    // this false until one exists instead of claiming a benefit implicitly.
    graceDayAvailable: false,
    lastActivityDate
  };
};

const percentForProgress = (progress, videoDurationSeconds = 0) => {
  if (!progress) return 0;
  if (progress.completed) return 100;
  const duration = Number(progress.durationSeconds) || Number(videoDurationSeconds) || 0;
  if (duration <= 0) return 0;
  return Math.max(0, Math.min(100, Math.round(((Number(progress.watchedSeconds) || 0) / duration) * 100)));
};

const todayItem = ({ kind, id, title, status, subject = null, releaseAt = null, dueAt = null, percent = 0, estimatedMinutes = null, assessmentType = null }) => ({
  kind,
  id: String(id),
  title: String(title || ''),
  status,
  subject,
  releaseAt: isoOrNull(releaseAt),
  dueAt: isoOrNull(dueAt),
  ...(assessmentType ? { assessmentType } : {}),
  percent: Math.max(0, Math.min(100, Math.round(Number(percent) || 0))),
  estimatedMinutes: estimatedMinutes === null || estimatedMinutes === undefined
    ? null
    : Math.max(0, Math.round(Number(estimatedMinutes) || 0))
});

const maskPhone = (phone) => phone.replace(/.(?=.{4})/g, '*');

const signUserToken = (user) => jwt.sign(
  { userId: user._id, phone: user.phone, role: user.role || 'student' },
  process.env.JWT_SECRET,
  { expiresIn: '30d' }
);

const uploadProfilePhoto = (req, res, next) => profileUpload.single('image')(req, res, next);

const removeStoredProfileImage = async (user) => {
  if (!user) return;
  if (user.profileImageKey) {
    try {
      await deleteFile(user.profileImageKey);
    } catch (error) {
      console.warn('Could not delete old profile photo from CDN:', error.message);
    }
  }
  if (!CDN_ENABLED && typeof user.profileImage === 'string' && user.profileImage.startsWith('/uploads/profile/')) {
    const filename = path.basename(user.profileImage);
    try {
      await fs.unlink(path.join(__dirname, '..', 'uploads', 'profile', filename));
    } catch (error) {
      if (error.code !== 'ENOENT') console.warn('Could not delete old profile photo:', error.message);
    }
  }
};

const removeUploadedProfileFile = async (file) => {
  if (!file) return;
  if (CDN_ENABLED && file.key) {
    try {
      await deleteFile(file.key);
    } catch (error) {
      console.warn('Could not delete failed profile photo from CDN:', error.message);
    }
  }
  if (!CDN_ENABLED && file.filename) {
    try {
      await fs.unlink(path.join(__dirname, '..', 'uploads', 'profile', path.basename(file.filename)));
    } catch (error) {
      if (error.code !== 'ENOENT') console.warn('Could not delete failed profile photo:', error.message);
    }
  }
};

// POST /api/user/register
router.post('/register', async (req, res) => {
  if (!REGISTRATION_OPEN) {
    return res.status(403).json({ message: 'Registration is closed for now. Please try again later.' });
  }
  try {
    const { name, phone, class: userClass, email, consent, courseIds } = req.body || {};

    if (!String(name || '').trim() || !String(phone || '').trim() || !String(userClass || '').trim()) {
      return res.status(400).json({ message: 'Name, phone, and class are required' });
    }

    const normalizedName = String(name).trim();
    const normalizedClass = String(userClass).trim();
    if (normalizedName.length < 3) {
      return res.status(400).json({ message: 'Name must be at least 3 characters' });
    }

    const normalizedPhone = normalizePhone(phone);
    const phoneProblem = phoneError(normalizedPhone);
    if (phoneProblem) {
      return res.status(400).json({ message: phoneProblem });
    }

    const rawCourseIds = Array.isArray(courseIds) ? courseIds.map((id) => String(id)) : [];
    if (rawCourseIds.some((id) => !mongoose.Types.ObjectId.isValid(id))) {
      return res.status(400).json({ message: 'courseIds contains an invalid course id' });
    }
    const selectedCourseIds = [...new Set(rawCourseIds)];
    if (selectedCourseIds.length > 0) {
      const activeCount = await Course.countDocuments({ _id: { $in: selectedCourseIds }, isActive: true });
      if (activeCount !== selectedCourseIds.length) {
        return res.status(400).json({ message: 'One or more selected courses are unavailable' });
      }
    }

    // A shared number is fine; the same name twice on it is not.
    if (await nameTakenOnPhone(normalizedPhone, normalizedName)) {
      return res.status(409).json({ message: 'A student with this name is already registered with this phone number' });
    }

    let consentValue = undefined;
    if (consent && consent.by) {
      if (!['parent', 'school'].includes(consent.by)) {
        return res.status(400).json({ message: "consent.by must be 'parent' or 'school'" });
      }
      const consentName = String(consent.name || '').trim();
      if (!consentName) {
        return res.status(400).json({ message: 'consent.name is required when consent is provided' });
      }
      consentValue = { by: consent.by, name: consentName.slice(0, 160), at: new Date() };
    }

    const user = await User.create({
      name: normalizedName,
      phone: normalizedPhone,
      class: normalizedClass,
      courseIds: selectedCourseIds,
      email: email || '',
      // The number is confirmed with a one-time code later, not at sign-up.
      phoneVerified: false,
      consent: consentValue
    });

    return res.status(201).json({
      message: 'User registered successfully',
      user: publicUser(user)
    });
  } catch (err) {
    if (err && err.code === 11000) {
      return res.status(409).json({ message: 'User with this phone number already exists' });
    }
    console.error('User registration error:', err?.message || err);
    return res.status(500).json({ message: 'Registration failed' });
  }
});

// POST /api/user/refresh-token
// Swaps a still-valid sign-in for a fresh 30-day one. The app calls this only
// when its sign-in has less than a day left, so a student is never signed out
// in the middle of a quiz. An expired or invalid sign-in is refused by
// authenticateUser like any other request.
router.post('/refresh-token', authenticateUser, (req, res) => {
  const token = signUserToken({ _id: req.user.id, phone: req.user.phone, role: req.user.role });
  res.json({ token });
});

// POST /api/user/login
// Students sign in with name + phone number, teachers with phone number +
// date of birth; a date never signs a student in, a name never a teacher.
// The name is compared without spaces or capitals (see services/nameKey).
// Failed attempts are limited per phone number and per IP in server.js. A
// wrong name and an unknown number get the same answer, so the endpoint does
// not reveal which numbers have accounts.
router.post('/login', async (req, res) => {
  try {
    const { phone, name, class: userClass, dob } = req.body || {};
    const hasName = String(name ?? '').trim() !== '';
    const hasDob = String(dob || '').trim() !== '';
    // An app from before the name sign-in sends the class instead.
    if (!hasName && !hasDob && String(userClass ?? '').trim() !== '') {
      return res.status(400).json({ message: 'Please update the app and sign in with your name and phone number.' });
    }
    if (!phone || (!hasName && !hasDob)) {
      return res.status(400).json({ message: 'Name and phone are required' });
    }

    const normalizedPhone = normalizePhone(phone);
    const phoneProblem = phoneError(normalizedPhone);
    if (phoneProblem) {
      return res.status(400).json({ message: phoneProblem });
    }

    // Brothers and sisters can share a number; the name or date picks the account.
    const accounts = await User.find({ phone: normalizedPhone });

    if (hasName) {
      const user = studentByName(accounts, name);
      if (!user) {
        return res.status(404).json({ message: 'No student account matches this name and phone number.' });
      }
      return res.json({ message: 'Login successful', token: signUserToken(user), user: publicUser(user) });
    }

    const dobValue = parseDob(dob);
    if (!dobValue) {
      return res.status(400).json({ message: 'dob must be a valid date (YYYY-MM-DD)' });
    }
    const teachers = accounts.filter((account) => !isStudent(account));
    const teacher = teachers.find((account) => sameDob(account.dob, dobValue));
    if (!teacher && teachers.some((account) => !account.dob)) {
      return res.status(409).json({
        code: 'DOB_MISSING',
        message: 'No date of birth is saved for this number yet, so it cannot sign in this way. Please contact support to add it.'
      });
    }
    // An app from before the name sign-in may still send a student's date.
    if (!teacher) {
      return res.status(404).json({
        message: 'No teacher account matches this phone number and date of birth. Students: please update the app and sign in with your name.'
      });
    }

    return res.json({ message: 'Login successful', token: signUserToken(teacher), user: publicUser(teacher) });
  } catch (err) {
    console.error('login error:', err?.message || err);
    return res.status(500).json({ message: 'Login failed' });
  }
});

// POST /api/user/login/request-otp
router.post('/login/request-otp', async (req, res) => {
  try {
    const { phone } = req.body || {};
    if (!phone) return res.status(400).json({ message: 'Phone is required' });

    const normalizedPhone = normalizePhone(phone);
    const phoneProblem = phoneError(normalizedPhone);
    if (phoneProblem) {
      return res.status(400).json({ message: phoneProblem });
    }
    const user = await User.findOne({ phone: normalizedPhone });
    if (!user) {
      return res.status(404).json({ message: 'User not registered' });
    }

    const isTestPhone =
      process.env.TEST_LOGIN &&
      normalizedPhone === normalizePhone(process.env.TEST_LOGIN);

    if (isTestPhone) {
      return res.json({ message: 'OTP sent', phone: maskPhone(normalizedPhone), cooldown: 60 });
    }

    const result = await requestWhatsappOtp(normalizedPhone);
    return res.json({
      message: 'OTP sent',
      phone: result.phone || maskPhone(normalizedPhone),
      cooldown: result.cooldown ?? 60
    });
  } catch (err) {
    console.error('request-otp error:', err?.message || err);
    return res.status(500).json({ message: 'Failed to send OTP' });
  }
});

// POST /api/user/login/verify
router.post('/login/verify', async (req, res) => {
  try {
    const { phone, code } = req.body || {};
    if (!phone || !code) return res.status(400).json({ message: 'Phone and code are required' });

    const normalizedPhone = normalizePhone(phone);
    const phoneProblem = phoneError(normalizedPhone);
    if (phoneProblem) {
      return res.status(400).json({ message: phoneProblem });
    }
    if (!/^\d{6}$/.test(String(code).trim())) {
      return res.status(400).json({ message: 'OTP must be a 6-digit number' });
    }

    const testLogin = process.env.TEST_LOGIN ? normalizePhone(process.env.TEST_LOGIN) : null;
    const testOtp = process.env.TEST_OTP;
    const isTestLogin =
      testLogin && testOtp &&
      normalizedPhone === testLogin &&
      code === testOtp;

    if (!isTestLogin) {
      const verify = await verifyWhatsappOtp(normalizedPhone, code);
      if (!verify.ok) {
        return res.status(400).json({ message: verify.error || 'Invalid or expired code' });
      }
    }

    // A code proves the number, not which of the accounts sharing it is theirs.
    const accounts = await User.find({ phone: normalizedPhone }).limit(2);
    if (accounts.length > 1) {
      return res.status(409).json({ message: 'Please update the app and sign in with your name and phone number.' });
    }
    let user = accounts[0] || null;
    if (!user && isTestLogin) {
      // Dev convenience: the documented test login should work on a fresh
      // database without registering by hand. Gated on TEST_LOGIN/TEST_OTP, so
      // it only ever creates that one test number.
      user = await User.create({
        phone: normalizedPhone,
        name: process.env.TEST_LOGIN_NAME || 'Test Student',
        class: process.env.TEST_LOGIN_CLASS || '8',
        email: ''
      });
      console.log(`Test login created user for ${normalizedPhone}`);
    }
    if (!user) {
      return res.status(404).json({ message: 'User not found. Please register first.' });
    }

    // A correct code is the proof the number is theirs.
    if (user.phoneVerified === false) {
      user.phoneVerified = true;
      await user.save();
    }

    return res.json({ message: 'Login successful', token: signUserToken(user), user: publicUser(user) });
  } catch (err) {
    console.error('verify-otp error:', err?.message || err);
    return res.status(500).json({ message: 'Verification failed' });
  }
});

// GET /api/user/me
router.get('/me', authenticateUser, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(publicUser(user));
  } catch (error) {
    console.error('Error fetching current user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// PUT /api/user/me
router.put('/me', authenticateUser, uploadProfilePhoto, async (req, res) => {
  try {
    const { name, class: userClass, email, language, consent, courseIds, dob } = req.body || {};
    const removeProfileImage = String(req.body?.removeProfileImage || '').toLowerCase() === 'true';
    const update = {};
    // The date of birth is the sign-in secret: it can be filled in once for an
    // account that has none, never changed afterwards.
    let dobValue = null;
    if (dob !== undefined) {
      dobValue = parseDob(dob);
      if (!dobValue) {
        await removeUploadedProfileFile(req.file);
        return res.status(400).json({ message: 'dob must be a valid date (YYYY-MM-DD)' });
      }
    }
    if (name !== undefined) {
      if (!String(name).trim()) return res.status(400).json({ message: 'Name cannot be empty' });
      update.name = String(name).trim();
    }
    if (userClass !== undefined) {
      if (!String(userClass).trim()) return res.status(400).json({ message: 'Class cannot be empty' });
      update.class = String(userClass).trim();
    }
    if (email !== undefined) update.email = email;
    if (courseIds !== undefined) {
      if (!Array.isArray(courseIds)) {
        return res.status(400).json({ message: 'courseIds must be an array' });
      }
      const rawCourseIds = courseIds.map((id) => String(id));
      if (rawCourseIds.some((id) => !mongoose.Types.ObjectId.isValid(id))) {
        return res.status(400).json({ message: 'courseIds contains an invalid course id' });
      }
      const selectedCourseIds = [...new Set(rawCourseIds)];
      const activeCount = await Course.countDocuments({ _id: { $in: selectedCourseIds }, isActive: true });
      if (activeCount !== selectedCourseIds.length) {
        return res.status(400).json({ message: 'One or more selected courses are unavailable' });
      }
      update.courseIds = selectedCourseIds;
    }
    if (language !== undefined) {
      if (!['en', 'ml'].includes(language)) {
        return res.status(400).json({ message: "language must be 'en' or 'ml'" });
      }
      update.language = language;
    }
    if (consent !== undefined) {
      if (!consent || !['parent', 'school'].includes(consent.by) || !String(consent.name || '').trim()) {
        return res.status(400).json({ message: 'consent requires by (parent or school) and name' });
      }
      update.consent = { by: consent.by, name: String(consent.name).trim().slice(0, 160), at: new Date() };
    }

    const currentUser = await User.findById(req.user.id);
    if (!currentUser) return res.status(404).json({ message: 'User not found' });
    // The name tells apart accounts that share a number, so it must stay unique on it.
    if (update.name !== undefined && !sameName(currentUser.name, update.name)
      && await nameTakenOnPhone(currentUser.phone, update.name, currentUser._id)) {
      await removeUploadedProfileFile(req.file);
      return res.status(409).json({ message: 'Another account on your phone number already has this name.' });
    }
    if (dobValue) {
      if (currentUser.dob && !sameDob(currentUser.dob, dobValue)) {
        await removeUploadedProfileFile(req.file);
        return res.status(409).json({ message: 'Your date of birth is already saved and cannot be changed here.' });
      }
      if (!currentUser.dob) update.dob = dobValue;
    }
    if (req.file) {
      update.profileImage = CDN_ENABLED
        ? getCdnUrl(req.file.key)
        : `/uploads/profile/${req.file.filename}`;
      update.profileImageKey = CDN_ENABLED ? req.file.key : '';
    } else if (removeProfileImage) {
      update.profileImage = '';
      update.profileImageKey = '';
    }

    const user = await User.findByIdAndUpdate(req.user.id, update, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Remove the previous asset only after the database points at the new
    // value, so a failed update never destroys a working avatar.
    if (req.file || removeProfileImage) await removeStoredProfileImage(currentUser);

    res.json({ message: 'Profile updated', user: publicUser(user) });
  } catch (error) {
    await removeUploadedProfileFile(req.file);
    console.error('Error updating current user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/today
// Stable learner Today contract:
// { next, continue: Item[], upcoming: Item[],
//   streak: { current, longest, graceDayAvailable, lastActivityDate },
//   summary: { videos, quizzes, upcoming, continue, watchedSeconds } }
// Item always contains kind/id/title/status/subject/releaseAt/dueAt/percent/
// estimatedMinutes. `subject` is {_id,name} for videos and null otherwise.
router.get('/today', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const requestedOffset = Number(req.query.tzOffsetMinutes);
    const timezoneOffsetMinutes = Number.isInteger(requestedOffset) && Math.abs(requestedOffset) <= 840
      ? requestedOffset : 0;
    // Lessons from the learner's own courses only, like the Subjects list.
    const scopedSubjects = await learnerSubjects(userId);
    const [videos, progressRows, videoAttempts, allQuizConfigs, quizAttempts, quizSessions, schedules, assignments, assignmentSubmissions, learner] = await Promise.all([
      Video.find({ subject: { $in: scopedSubjects.map((subject) => subject._id) }, isPublished: { $ne: false } })
        .select('_id title subject releaseDate durationSeconds order createdAt')
        .populate('subject', '_id name')
        .sort({ releaseDate: 1, subject: 1, order: 1, createdAt: 1 })
        .lean(),
      VideoProgress.find({ userId }).select('videoId positionSeconds watchedSeconds durationSeconds completed lastViewedAt completedAt createdAt updatedAt').lean(),
      VideoQuizAttempt.find({ userId }).select('videoId createdAt updatedAt percentage').lean(),
      QuizConfig.find({ isEnable: true, endDate: { $gte: now } })
        .select('_id title assessmentType startDate endDate overallTimeLimit perQuestionTimeLimit numberOfQuestions allowedClasses conditions')
        .sort({ startDate: 1 })
        .lean(),
      Quiz.find({ userId }).select('quizId percentage createdAt updatedAt').lean(),
      QuizSession.find({ userId }).select('quizId startedAt createdAt updatedAt').lean(),
      Schedule.find({ class: req.user.class, scheduleDate: { $gte: now } })
        .select('_id title scheduleDate faculty')
        .populate('faculty', '_id name designation')
        .sort({ scheduleDate: 1 })
        .lean(),
      Assignment.find({
        isPublished: true,
        $or: [{ releaseAt: null }, { releaseAt: { $lte: now } }],
        $and: [{ $or: [{ class: '' }, { class: null }, { class: req.user.class }] }]
      }).select('_id title releaseAt dueAt maxPoints').sort({ dueAt: 1 }).lean(),
      AssignmentSubmission.find({ userId }).select('assignmentId status submittedAt').lean(),
      User.findById(userId).select('learningEvents').lean()
    ]);

    const progressByVideo = new Map(progressRows.map((row) => [String(row.videoId), row]));
    const quizAttemptByQuiz = new Map(quizAttempts.map((attempt) => [String(attempt.quizId), attempt]));
    const quizSessionByQuiz = new Map(quizSessions.map((session) => [String(session.quizId), session]));
    const assignmentSubmissionByAssignment = new Map(assignmentSubmissions.map((submission) => [String(submission.assignmentId), submission]));
    const activityTimestamps = [];

    (learner?.learningEvents || []).forEach((event) => {
      if (event.occurredAt) activityTimestamps.push(event.occurredAt);
    });

    progressRows.forEach((row) => {
      [row.lastViewedAt, row.completedAt, row.updatedAt, row.createdAt].forEach((timestamp) => {
        if (timestamp) activityTimestamps.push(timestamp);
      });
    });
    videoAttempts.forEach((attempt) => {
      [attempt.updatedAt, attempt.createdAt].forEach((timestamp) => {
        if (timestamp) activityTimestamps.push(timestamp);
      });
    });
    quizAttempts.forEach((attempt) => {
      [attempt.updatedAt, attempt.createdAt].forEach((timestamp) => {
        if (timestamp) activityTimestamps.push(timestamp);
      });
    });
    quizSessions.forEach((session) => {
      [session.updatedAt, session.startedAt, session.createdAt].forEach((timestamp) => {
        if (timestamp) activityTimestamps.push(timestamp);
      });
    });

    const continueItems = [];
    const upcomingItems = [];
    const notStartedItems = [];
    let videoCompleted = 0;
    let videoInProgress = 0;
    let watchedSeconds = 0;

    for (const video of videos) {
      const releaseAt = asDate(video.releaseDate);
      const progress = progressByVideo.get(String(video._id));
      const isUpcoming = Boolean(releaseAt && releaseAt > now);
      const completed = Boolean(progress?.completed);
      const started = Boolean(progress && ((Number(progress.watchedSeconds) || 0) > 0 || (Number(progress.positionSeconds) || 0) > 0));
      const status = isUpcoming ? 'upcoming' : completed ? 'completed' : started ? 'in-progress' : 'not-started';
      const item = todayItem({
        kind: 'video',
        id: video._id,
        title: video.title,
        status,
        subject: video.subject ? { _id: video.subject._id, name: video.subject.name } : null,
        releaseAt,
        percent: percentForProgress(progress, video.durationSeconds),
        estimatedMinutes: Number(video.durationSeconds) > 0 ? Number(video.durationSeconds) / 60 : null
      });

      if (isUpcoming) upcomingItems.push(item);
      else if (completed) videoCompleted += 1;
      else if (started) {
        videoInProgress += 1;
        continueItems.push(item);
      } else {
        notStartedItems.push(item);
      }
      watchedSeconds += Number(progress?.watchedSeconds) || 0;
    }

    // Only the quizzes the Quizzes screen shows this learner (class, finished video).
    const hasCompletedVideo = async () => progressRows.some((row) => row.completed);
    const access = await Promise.all(allQuizConfigs.map((quiz) => isAccessible(quiz, req.user, hasCompletedVideo)));
    const quizConfigs = allQuizConfigs.filter((_, i) => access[i]);

    let quizCompleted = 0;
    for (const quiz of quizConfigs) {
      const attempt = quizAttemptByQuiz.get(String(quiz._id));
      const session = quizSessionByQuiz.get(String(quiz._id));
      const startDate = asDate(quiz.startDate);
      const endDate = asDate(quiz.endDate);
      const status = attempt ? 'completed' : startDate && startDate > now ? 'upcoming' : 'live';
      const item = todayItem({
        kind: 'quiz',
        id: quiz._id,
        title: quiz.title,
        assessmentType: quiz.assessmentType || 'quiz',
        status,
        releaseAt: startDate,
        dueAt: endDate,
        percent: attempt?.percentage || 0,
        assessmentType: quiz.assessmentType || 'quiz',
        estimatedMinutes: Number(quiz.overallTimeLimit) > 0
          ? Number(quiz.overallTimeLimit) / 60
          : Number(quiz.perQuestionTimeLimit) > 0 && Number(quiz.numberOfQuestions) > 0
            ? (Number(quiz.perQuestionTimeLimit) * Number(quiz.numberOfQuestions)) / 60
            : null
      });

      if (attempt) quizCompleted += 1;
      else if (session && status === 'live') continueItems.push(item);
      else upcomingItems.push(item);
    }

    for (const schedule of schedules) {
      upcomingItems.push(todayItem({
        kind: 'schedule',
        id: schedule._id,
        title: schedule.title,
        status: 'upcoming',
        releaseAt: schedule.scheduleDate
      }));
    }

    for (const assignment of assignments) {
      const submission = assignmentSubmissionByAssignment.get(String(assignment._id));
      const dueAt = asDate(assignment.dueAt);
      const status = submission?.status || (dueAt && dueAt < now ? 'overdue' : 'upcoming');
      upcomingItems.push(todayItem({
        kind: 'assignment',
        id: assignment._id,
        title: assignment.title,
        status,
        releaseAt: assignment.releaseAt,
        dueAt,
        percent: submission?.status === 'graded' ? 100 : 0
      }));
    }

    const dateValue = (item, field) => {
      const parsed = asDate(item[field]);
      return parsed ? parsed.getTime() : Number.MAX_SAFE_INTEGER;
    };
    continueItems.sort((a, b) => {
      const aProgress = progressByVideo.get(String(a.id));
      const bProgress = progressByVideo.get(String(b.id));
      return (asDate(bProgress?.lastViewedAt)?.getTime() || 0) - (asDate(aProgress?.lastViewedAt)?.getTime() || 0);
    });
    const itemDateValue = (item) => {
      const release = dateValue(item, 'releaseAt');
      if (release !== Number.MAX_SAFE_INTEGER) return release;
      return dateValue(item, 'dueAt');
    };
    upcomingItems.sort((a, b) => itemDateValue(a) - itemDateValue(b));
    notStartedItems.sort((a, b) => dateValue(a, 'releaseAt') - dateValue(b, 'releaseAt'));
    const nextPriority = (item) => {
      if (item.status === 'overdue') return 0;
      if (item.status === 'live') return 1;
      if (item.status === 'upcoming') return 2;
      if (item.status === 'in-progress') return 3;
      if (item.kind === 'practice') return 4;
      if (item.status === 'not-started') return 5;
      return 6;
    };
    const nextCandidates = [...continueItems, ...upcomingItems, ...notStartedItems];
    nextCandidates.sort((a, b) => {
      const byPriority = nextPriority(a) - nextPriority(b);
      if (byPriority !== 0) return byPriority;
      return itemDateValue(a) - itemDateValue(b);
    });
    const next = nextCandidates[0] || null;
    const upcoming = upcomingItems.slice(0, parseUpcomingLimit(req.query.upcomingLimit));
    const videoTotal = videos.filter((video) => !(asDate(video.releaseDate) > now)).length;
    const quizRemaining = Math.max(0, quizConfigs.length - quizCompleted);
    const assignmentSubmitted = assignments.filter((assignment) => {
      const status = assignmentSubmissionByAssignment.get(String(assignment._id))?.status;
      // 'returned' means the teacher asked for changes: still to do.
      return status === 'submitted' || status === 'late' || status === 'graded';
    }).length;
    const assignmentOverdue = assignments.filter((assignment) => {
      const dueAt = asDate(assignment.dueAt);
      const status = assignmentSubmissionByAssignment.get(String(assignment._id))?.status;
      return Boolean(dueAt && dueAt < now && !status);
    }).length;

    return res.json({
      next,
      continue: continueItems.slice(0, 12),
      upcoming,
      streak: activityStreak(activityTimestamps, now, timezoneOffsetMinutes),
      summary: {
        videos: {
          total: videoTotal,
          completed: videoCompleted,
          inProgress: videoInProgress,
          remaining: Math.max(0, videoTotal - videoCompleted)
        },
        quizzes: {
          total: quizConfigs.length,
          completed: quizCompleted,
          remaining: quizRemaining
        },
        assignments: {
          total: assignments.length,
          submitted: assignmentSubmitted,
          overdue: assignmentOverdue,
          remaining: Math.max(0, assignments.length - assignmentSubmitted)
        },
        upcoming: upcomingItems.length,
        continue: continueItems.length,
        watchedSeconds
      }
    });
  } catch (error) {
    console.error('Error fetching today summary:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/prefs
router.get('/prefs', authenticateUser, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('seenGuides language');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({ seenGuides: user.seenGuides || [], language: user.language || 'en' });
  } catch (error) {
    console.error('Error fetching prefs:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// PUT /api/user/prefs
router.put('/prefs', authenticateUser, async (req, res) => {
  try {
    const { seenGuides, language } = req.body || {};
    const update = {};
    if (seenGuides !== undefined) {
      if (!Array.isArray(seenGuides)) {
        return res.status(400).json({ message: 'seenGuides must be an array' });
      }
      update.seenGuides = seenGuides.filter((id) => mongoose.Types.ObjectId.isValid(id));
    }
    if (language !== undefined) {
      if (!['en', 'ml'].includes(language)) {
        return res.status(400).json({ message: "language must be 'en' or 'ml'" });
      }
      update.language = language;
    }

    const user = await User.findByIdAndUpdate(req.user.id, update, { new: true }).select('seenGuides language');
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({ seenGuides: user.seenGuides || [], language: user.language || 'en' });
  } catch (error) {
    console.error('Error updating prefs:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/bookmarks - bare array of public video objects
router.get('/bookmarks', authenticateUser, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('bookmarks');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const videos = await Video.find({ _id: { $in: user.bookmarks || [] } })
      .populate('subject', 'name')
      .populate('speaker', 'name designation image');

    res.json(videos.map((video) => shapeVideo(video, 0, false)));
  } catch (error) {
    console.error('Error fetching bookmarks:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// PUT /api/user/bookmarks/:videoId - add
router.put('/bookmarks/:videoId', authenticateUser, async (req, res) => {
  try {
    const { videoId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(videoId)) {
      return res.status(400).json({ message: 'Invalid videoId' });
    }
    const video = await Video.findById(videoId).select('_id');
    if (!video) return res.status(404).json({ message: 'Video not found' });

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $addToSet: { bookmarks: videoId } },
      { new: true }
    ).select('bookmarks');

    res.json({ message: 'Bookmark added', bookmarks: user.bookmarks });
  } catch (error) {
    console.error('Error adding bookmark:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// DELETE /api/user/bookmarks/:videoId - remove
router.delete('/bookmarks/:videoId', authenticateUser, async (req, res) => {
  try {
    const { videoId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(videoId)) {
      return res.status(400).json({ message: 'Invalid videoId' });
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $pull: { bookmarks: videoId } },
      { new: true }
    ).select('bookmarks');

    res.json({ message: 'Bookmark removed', bookmarks: user.bookmarks });
  } catch (error) {
    console.error('Error removing bookmark:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/progress - aggregate progress across videos/subjects/courses/quizzes
router.get('/progress', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;

    // Totals count every lesson in the learner's courses, not only the ones
    // they have started (see services/progressSummary.js).
    const subjects = await learnerSubjects(userId);
    const [lessons, progressRows, quizAttempts, videoQuizAttempts] = await Promise.all([
      Video.find({ subject: { $in: subjects.map((subject) => subject._id) }, isPublished: { $ne: false } })
        .select('_id subject releaseDate')
        .lean(),
      VideoProgress.find({ userId }).select('videoId completed watchedSeconds positionSeconds').lean(),
      Quiz.find({ userId }).populate('quizId', 'title endDate').sort({ createdAt: -1 }),
      VideoQuizAttempt.find({ userId }).populate('videoId', 'title').sort({ createdAt: -1 })
    ]);
    // A quiz score stays hidden from the learner until the quiz has closed for
    // everyone, the same moment its answers show. A deleted quiz has closed.
    const now = new Date();
    const scoreShown = (attempt) => !attempt.quizId || answersRevealed(examAnswersAt(attempt.quizId), now);

    const courseIds = [...new Set(subjects.filter((subject) => subject.courseId).map((subject) => String(subject.courseId)))];
    const courses = courseIds.length > 0
      ? await Course.find({ _id: { $in: courseIds } }).select('title').lean()
      : [];
    const { videos, subjects: subjectRows, courses: courseRows } = buildProgressSummary({
      subjects,
      videos: lessons,
      progressRows,
      courseTitles: new Map(courses.map((course) => [String(course._id), course.title]))
    });

    res.json({
      videos,
      subjects: subjectRows,
      courses: courseRows,
      quizAttempts: quizAttempts.filter(scoreShown).map((a) => ({
        attemptId: a._id,
        quizId: a.quizId?._id || a.quizId,
        title: a.quizId?.title || 'Quiz',
        score: a.score,
        totalQuestions: a.totalQuestions,
        percentage: a.percentage,
        createdAt: a.createdAt
      })),
      videoQuizzes: videoQuizAttempts.map((a) => ({
        videoId: a.videoId?._id || a.videoId,
        title: a.videoId?.title || 'Video',
        score: a.score,
        totalQuestions: a.totalQuestions,
        percentage: a.percentage,
        createdAt: a.createdAt
      }))
    });
  } catch (error) {
    console.error('Error fetching user progress:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/quiz-attempts - bare array
router.get('/quiz-attempts', authenticateUser, async (req, res) => {
  try {
    const attempts = await Quiz.find({ userId: req.user.id }).populate('quizId', 'title').sort({ createdAt: -1 });
    res.json(attempts.map((a) => ({
      attemptId: a._id,
      quizId: a.quizId?._id || a.quizId,
      title: a.quizId?.title || 'Quiz',
      language: a.language,
      score: a.score,
      totalQuestions: a.totalQuestions,
      percentage: a.percentage,
      totalDuration: a.totalDuration,
      createdAt: a.createdAt
    })));
  } catch (error) {
    console.error('Error fetching quiz attempts:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/quiz-attempts/:id
router.get('/quiz-attempts/:id', authenticateUser, async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid attempt id' });
    }

    const attempt = await Quiz.findOne({ _id: id, userId: req.user.id }).populate('quizId', 'title endDate');
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });

    const QuizQuestion = require('../models/quizQuestions');
    const questions = await QuizQuestion.find({ _id: { $in: attempt.questionIds } });
    const byId = new Map(questions.map((q) => [String(q._id), q]));

    const results = attempt.answers.map((ans) => {
      const q = byId.get(String(ans.questionId));
      const optionsEn = readOptionsArray(q?.options_en);
      const optionsMl = readOptionsArray(q?.options_ml);
      const correctIndex = resolveCorrectIndex(q, optionsEn);
      return {
        questionId: ans.questionId,
        type: q?.type || 'Multiple Choice',
        question_en: q?.question_en || '',
        question_ml: q?.question_ml || '',
        options_en: optionsEn,
        options_ml: optionsMl,
        attemptedAnswer: ans.attemptedAnswer,
        correctAnswer: correctIndex,
        isCorrect: ans.isCorrect
      };
    });

    res.json({
      attemptId: attempt._id,
      quizId: attempt.quizId?._id || attempt.quizId,
      title: attempt.quizId?.title || 'Quiz',
      language: attempt.language,
      score: attempt.score,
      totalQuestions: attempt.totalQuestions,
      percentage: attempt.percentage,
      totalDuration: attempt.totalDuration,
      createdAt: attempt.createdAt,
      // Correct answers only once the exam has closed for everyone.
      ...revealFields(examAnswersAt(attempt.quizId), results)
    });
  } catch (error) {
    console.error('Error fetching quiz attempt:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Shared helpers for reading option arrays / resolving the correct index,
// used by the attempt-detail route above.
function readOptionsArray(value) {
  if (Array.isArray(value)) return value.map((v) => String(v).trim()).filter(Boolean);
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) return parsed.map((v) => String(v).trim()).filter(Boolean);
    } catch (e) {
      // fall through
    }
    return value.split(/\r?\n|,/).map((v) => v.trim()).filter(Boolean);
  }
  return [];
}

function resolveCorrectIndex(question, optionsEn) {
  if (!question) return -1;
  const expected = String(question.correct_answer ?? '').trim().toLowerCase();
  const found = optionsEn.findIndex((o) => o.toLowerCase() === expected);
  if (found >= 0) return found;
  const numeric = Number.parseInt(question.correct_answer, 10);
  return Number.isInteger(numeric) && numeric >= 0 && numeric < optionsEn.length ? numeric : -1;
}

// GET /api/user/my-questions - Get questions created by authenticated user
router.get('/my-questions', authenticateUser, async (req, res) => {
  try {
    const questions = await Question.find({ user: req.user.id })
      .populate('faculty', 'name designation')
      .populate('user', 'name')
      .sort({ createdAt: -1 });
    res.json(questions);
  } catch (error) {
    console.error('Error fetching user questions:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/user/my-questions/:id - Get user's own question with answer (if exists)
router.get('/my-questions/:id', authenticateUser, async (req, res) => {
  try {
    const question = await Question.findOne({
      _id: req.params.id,
      user: req.user.id
    })
      .populate('faculty', 'name designation')
      .populate('user', 'name');

    if (!question) {
      return res.status(404).json({ message: 'Question not found or you do not have access to it' });
    }

    res.json(question);
  } catch (error) {
    console.error('Error fetching user question:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;
