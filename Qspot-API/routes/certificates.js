const express = require('express');
const crypto = require('crypto');
const mongoose = require('mongoose');
const QuizConfig = require('../models/quizConfig');
const Quiz = require('../models/quiz');
const Certificate = require('../models/certificate');
const { authenticateAdmin, authenticateUser } = require('../middlewares/auth');

const router = express.Router();

const isObjectId = (value) => mongoose.Types.ObjectId.isValid(String(value || ''));
const normalizeClasses = (value) => Array.isArray(value)
    ? value.map((item) => String(item).trim()).filter(Boolean).slice(0, 50)
    : String(value || '').split(',').map((item) => item.trim()).filter(Boolean).slice(0, 50);

const certificateNumber = () => {
    const year = new Date().getUTCFullYear();
    return `QSPOT-${year}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
};

const shapeCertificate = (certificate) => ({
    id: certificate._id,
    certificateNumber: certificate.certificateNumber,
    quizId: certificate.quizId,
    userId: certificate.userId?._id || certificate.userId,
    student: certificate.userId && certificate.userId.name
        ? {
            id: certificate.userId._id,
            name: certificate.userId.name,
            class: certificate.userId.class || '',
            phone: certificate.userId.phone || '',
            email: certificate.userId.email || ''
        }
        : null,
    percentage: certificate.percentage,
    score: certificate.score,
    totalQuestions: certificate.totalQuestions,
    issuedAt: certificate.issuedAt,
    status: certificate.status,
    revokedAt: certificate.revokedAt,
    snapshot: certificate.snapshot
});

const eligibleAttempts = async ({ quizId, mode, studentIds, minimumPercentage, classes }) => {
    const attempts = await Quiz.find({ quizId })
        .populate({ path: 'userId', select: 'name class phone email role' })
        .sort({ percentage: -1, createdAt: 1 });

    // A student may have more than one submission. Certificates are issued per
    // student, so keep the highest-scoring attempt before applying the batch.
    const bestAttemptByStudent = new Map();
    attempts.forEach((attempt) => {
        const userId = attempt.userId?._id || attempt.userId;
        if (!userId) return;
        const key = String(userId);
        if (!bestAttemptByStudent.has(key)) bestAttemptByStudent.set(key, attempt);
    });
    const uniqueAttempts = [...bestAttemptByStudent.values()];

    if (mode === 'selected') {
        const selected = new Set(studentIds.map((id) => String(id)));
        return uniqueAttempts.filter((attempt) => selected.has(String(attempt.userId?._id || attempt.userId)));
    }

    if (mode === 'criteria') {
        const threshold = Number.isFinite(Number(minimumPercentage))
            ? Math.max(0, Math.min(100, Number(minimumPercentage)))
            : 0;
        const classSet = new Set(normalizeClasses(classes).map((value) => value.toLowerCase()));
        return uniqueAttempts.filter((attempt) => {
            const inClass = classSet.size === 0 || classSet.has(String(attempt.userId?.class || '').toLowerCase());
            return inClass && Number(attempt.percentage) >= threshold;
        });
    }

    return uniqueAttempts;
};

// GET /api/certificates/quiz/:quizId - issued records for an exam (admin).
router.get('/quiz/:quizId', authenticateAdmin, async (req, res) => {
    try {
        if (!isObjectId(req.params.quizId)) return res.status(400).json({ message: 'Invalid quiz id' });
        const quiz = await QuizConfig.findById(req.params.quizId).lean();
        if (!quiz) return res.status(404).json({ message: 'Exam not found' });
        const certificates = await Certificate.find({ quizId: quiz._id })
            .populate({ path: 'userId', select: 'name class phone email' })
            .sort({ issuedAt: -1 })
            .lean();
        res.json({ quiz, items: certificates.map(shapeCertificate) });
    } catch (error) {
        console.error('Error fetching certificates:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/certificates/quiz/:quizId/issue - issue after an exam ends.
router.post('/quiz/:quizId/issue', authenticateAdmin, async (req, res) => {
    try {
        const { quizId } = req.params;
        if (!isObjectId(quizId)) return res.status(400).json({ message: 'Invalid quiz id' });
        const quiz = await QuizConfig.findById(quizId).lean();
        if (!quiz) return res.status(404).json({ message: 'Exam not found' });
        if (!quiz.certificate?.enabled) return res.status(400).json({ message: 'Enable certificate settings for this exam first' });
        if (new Date(quiz.endDate) > new Date()) return res.status(400).json({ message: 'Certificates can be issued after the exam ends' });

        const mode = ['all', 'selected', 'criteria'].includes(req.body?.mode) ? req.body.mode : 'criteria';
        const studentIds = Array.isArray(req.body?.studentIds) ? req.body.studentIds.map(String) : [];
        if (mode === 'selected') {
            if (!studentIds.length || studentIds.some((id) => !isObjectId(id))) {
                return res.status(400).json({ message: 'Select at least one valid student' });
            }
        }

        const attempts = await eligibleAttempts({
            quizId,
            mode,
            studentIds,
            minimumPercentage: req.body?.minimumPercentage ?? quiz.certificate.minimumPercentage,
            classes: req.body?.classes ?? quiz.certificate.eligibleClasses
        });
        if (!attempts.length) return res.status(400).json({ message: 'No eligible completed attempts were found' });

        let created = 0;
        let existing = 0;
        const issued = [];
        for (const attempt of attempts) {
            const userId = attempt.userId?._id || attempt.userId;
            if (!userId) continue;
            let result = await Certificate.findOne({ quizId, userId });
            if (result) {
                existing += 1;
            } else {
                try {
                    result = await Certificate.create({
                        certificateNumber: certificateNumber(),
                        quizId,
                        userId,
                        percentage: Math.max(0, Math.min(100, Number(attempt.percentage) || 0)),
                        score: Math.max(0, Number(attempt.score) || 0),
                        totalQuestions: Math.max(0, Number(attempt.totalQuestions) || 0),
                        snapshot: {
                            title: quiz.certificate.title || 'Certificate of Achievement',
                            issuerName: quiz.certificate.issuerName || '',
                            signatoryName: quiz.certificate.signatoryName || '',
                            description: quiz.certificate.description || '',
                            examTitle: quiz.title
                        }
                    });
                    created += 1;
                } catch (error) {
                    // A second admin can issue the same batch concurrently;
                    // the compound unique index makes that safe and idempotent.
                    if (error?.code !== 11000) throw error;
                    result = await Certificate.findOne({ quizId, userId });
                    if (!result) throw error;
                    existing += 1;
                }
            }
            const populated = await Certificate.findById(result._id)
                .populate({ path: 'userId', select: 'name class phone email' })
                .lean();
            issued.push(shapeCertificate(populated));
        }

        res.status(201).json({ message: 'Certificate issuance completed', created, existing, items: issued });
    } catch (error) {
        console.error('Error issuing certificates:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/certificates/:id/revoke - preserve the record but invalidate it.
router.post('/:id/revoke', authenticateAdmin, async (req, res) => {
    try {
        if (!isObjectId(req.params.id)) return res.status(400).json({ message: 'Invalid certificate id' });
        const certificate = await Certificate.findByIdAndUpdate(
            req.params.id,
            { status: 'revoked', revokedAt: new Date() },
            { new: true }
        );
        if (!certificate) return res.status(404).json({ message: 'Certificate not found' });
        res.json({ message: 'Certificate revoked', certificate: shapeCertificate(certificate) });
    } catch (error) {
        console.error('Error revoking certificate:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Students can see certificates issued to their account.
router.get('/mine', authenticateUser, async (req, res) => {
    try {
        const certificates = await Certificate.find({ userId: req.user.id, status: 'issued' })
            .populate({ path: 'quizId', select: 'title assessmentType endDate' })
            // The printed certificate needs the student's name.
            .populate({ path: 'userId', select: 'name class' })
            .sort({ issuedAt: -1 })
            .lean();
        res.json({ items: certificates.map((item) => ({
            ...shapeCertificate(item),
            exam: item.quizId
        })) });
    } catch (error) {
        console.error('Error fetching student certificates:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
