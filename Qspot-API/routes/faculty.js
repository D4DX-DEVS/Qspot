const express = require('express');
const mongoose = require('mongoose');
const Question = require('../models/question');
const Speaker = require('../models/speakers');
const Video = require('../models/videos');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');
const { authenticateFaculty } = require('../middlewares/auth');

const router = express.Router();
router.use(authenticateFaculty);

const populate = (query) => query.populate('faculty', 'name designation image').populate('user', 'name class');

router.get('/me', async (req, res) => {
  const profile = await Speaker.findById(req.user.facultyProfile).select('name designation image order');
  res.json({ user: req.user, profile });
});

router.get('/dashboard', async (req, res) => {
  const filter = { faculty: req.user.facultyProfile, status: { $ne: 'hidden' } };
  const profile = await Speaker.findById(req.user.facultyProfile).select('name');
  const assignmentFilter = { $or: [{ createdBy: profile?.name || '' }, { videoId: { $in: (await Video.find({ speaker: req.user.facultyProfile }).distinct('_id')) } }] };
  const [total, pending, answered, recent, assignments, submissions] = await Promise.all([
    Question.countDocuments(filter),
    Question.countDocuments({ ...filter, answer: null, status: { $ne: 'hidden' } }),
    Question.countDocuments({ ...filter, answer: { $ne: null } }),
    populate(Question.find(filter).sort({ createdAt: -1 }).limit(10)),
    Assignment.countDocuments(assignmentFilter),
    AssignmentSubmission.countDocuments({ assignmentId: { $in: await Assignment.find(assignmentFilter).distinct('_id') }, status: { $in: ['submitted', 'late', 'returned'] } })
  ]);
  res.json({ total, pending, answered, assignments, pendingSubmissions: submissions, recent });
});

const facultyAssignmentFilter = async (facultyProfile) => {
  const profile = await Speaker.findById(facultyProfile).select('name');
  const videoIds = await Video.find({ speaker: facultyProfile }).distinct('_id');
  return { $or: [{ facultyProfile }, { createdBy: profile?.name || '' }, { videoId: { $in: videoIds } }] };
};

router.get('/content', async (req, res) => {
  const videos = await Video.find({ speaker: req.user.facultyProfile }).populate('subject', 'name').sort({ order: 1, createdAt: -1 }).lean();
  res.json(videos);
});

router.get('/assignments', async (req, res) => {
  const assignments = await Assignment.find(await facultyAssignmentFilter(req.user.facultyProfile))
    .populate('subjectId', 'name').populate('videoId', 'title').sort({ dueAt: 1, createdAt: -1 }).lean();
  const counts = await AssignmentSubmission.aggregate([
    { $match: { assignmentId: { $in: assignments.map((item) => item._id) } } },
    { $group: { _id: '$assignmentId', count: { $sum: 1 }, pending: { $sum: { $cond: [{ $in: ['$status', ['submitted', 'late', 'returned']] }, 1, 0] } } } }
  ]);
  const countMap = new Map(counts.map((item) => [String(item._id), item]));
  res.json(assignments.map((item) => ({ ...item, submissionCount: countMap.get(String(item._id))?.count || 0, pendingSubmissions: countMap.get(String(item._id))?.pending || 0 })));
});

router.get('/assignments/:id/submissions', async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid assignment id' });
  const owned = await Assignment.findOne({ _id: req.params.id, ...(await facultyAssignmentFilter(req.user.facultyProfile)) }).select('_id title maxPoints');
  if (!owned) return res.status(404).json({ message: 'Assignment not found' });
  const submissions = await AssignmentSubmission.find({ assignmentId: owned._id }).populate('userId', 'name class').sort({ submittedAt: -1 }).lean();
  res.json({ assignment: owned, submissions });
});

router.put('/submissions/:id/grade', async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid submission id' });
  const grade = Number(req.body?.grade);
  if (!Number.isFinite(grade) || grade < 0) return res.status(400).json({ message: 'grade must be a non-negative number' });
  const feedback = String(req.body?.feedback || '').slice(0, 10000);
  const submission = await AssignmentSubmission.findById(req.params.id).populate('assignmentId', 'title maxPoints videoId createdBy');
  if (!submission) return res.status(404).json({ message: 'Submission not found' });
  const assignment = await Assignment.findOne({ _id: submission.assignmentId._id, ...(await facultyAssignmentFilter(req.user.facultyProfile)) });
  if (!assignment) return res.status(403).json({ message: 'This submission is outside your faculty scope' });
  if (grade > assignment.maxPoints) return res.status(400).json({ message: `grade cannot exceed ${assignment.maxPoints}` });
  submission.grade = grade;
  submission.feedback = feedback;
  submission.status = 'graded';
  submission.gradedAt = new Date();
  submission.gradedBy = req.user.name;
  await submission.save();
  res.json({ message: 'Submission graded', submission });
});

router.get('/questions', async (req, res) => {
  const filter = { faculty: req.user.facultyProfile, status: { $ne: 'hidden' } };
  if (req.query.status === 'pending') filter.answer = null;
  if (req.query.status === 'answered') filter.answer = { $ne: null };
  const questions = await populate(Question.find(filter).sort({ createdAt: -1 }));
  res.json(questions);
});

router.get('/questions/:id', async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid question id' });
  const question = await populate(Question.findOne({ _id: req.params.id, faculty: req.user.facultyProfile, status: { $ne: 'hidden' } }));
  if (!question) return res.status(404).json({ message: 'Question not found' });
  res.json(question);
});

router.put('/questions/:id/answer', async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid question id' });
  const answer = String(req.body?.answer || '').trim();
  if (!answer) return res.status(400).json({ message: 'Answer is required' });
  const question = await Question.findOneAndUpdate(
    { _id: req.params.id, faculty: req.user.facultyProfile, status: { $ne: 'hidden' } },
    { answer, answeredBy: req.user.name, answeredAt: new Date() },
    { new: true, runValidators: true }
  );
  if (!question) return res.status(404).json({ message: 'Question not found' });
  res.json({ message: 'Answer saved', question: await populate(Question.findById(question._id)) });
});

router.delete('/questions/:id/answer', async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid question id' });
  const question = await Question.findOneAndUpdate(
    { _id: req.params.id, faculty: req.user.facultyProfile, status: { $ne: 'hidden' } },
    { answer: null, answeredBy: null, answeredAt: null },
    { new: true }
  );
  if (!question) return res.status(404).json({ message: 'Question not found' });
  res.json({ message: 'Answer removed', question });
});

module.exports = router;
