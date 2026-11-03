const express = require('express');
const Schedule = require('../models/schedule');
const Speaker = require('../models/speakers');
const { authenticateAdmin } = require('../middlewares/auth');

const router = express.Router();

// GET /api/schedules?class= - Get all schedules, optionally filtered by class (public)
router.get('/', async (req, res) => {
    try {
        const filter = {};
        if (req.query.class) filter.class = req.query.class;
        const schedules = await Schedule.find(filter)
            .populate('faculty', 'name designation')
            .sort({ scheduleDate: 1, createdAt: -1 });
        res.json(schedules);
    } catch (error) {
        console.error('Error fetching schedules:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/schedules/:id - Get single schedule (public)
router.get('/:id', async (req, res) => {
    try {
        const schedule = await Schedule.findById(req.params.id)
            .populate('faculty', 'name designation');
        if (!schedule) {
            return res.status(404).json({ message: 'Schedule not found' });
        }
        res.json(schedule);
    } catch (error) {
        console.error('Error fetching schedule:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/schedules/faculty/:facultyId - Get schedules by faculty (public)
router.get('/faculty/:facultyId', async (req, res) => {
    try {
        const { facultyId } = req.params;
        const schedules = await Schedule.find({ faculty: facultyId })
            .populate('faculty', 'name designation')
            .sort({ scheduleDate: 1, createdAt: -1 });
        res.json(schedules);
    } catch (error) {
        console.error('Error fetching schedules by faculty:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/schedules - Create new schedule (admin only)
router.post('/', authenticateAdmin, async (req, res) => {
    try {
        const { class: className, scheduleDate, faculty, title } = req.body;

        if (!className || !scheduleDate || !faculty || !title) {
            return res.status(400).json({ message: 'class, scheduleDate, faculty, and title are required' });
        }


        // Validate faculty exists
        const existingFaculty = await Speaker.findById(faculty);
        if (!existingFaculty) {
            return res.status(404).json({ message: 'Faculty not found' });
        }

        const schedule = new Schedule({
            class: className,
            scheduleDate,
            faculty,
            title
        });

        const saved = await schedule.save();
        const populated = await Schedule.findById(saved._id)
            .populate('faculty', 'name designation');

        res.status(201).json({ message: 'Schedule created successfully', schedule: populated });
    } catch (error) {
        console.error('Error creating schedule:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/schedules/:id - Update schedule (admin only)
router.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { class: className, scheduleDate, faculty, title } = req.body;
        const old = await Schedule.findById(req.params.id);

        if (!old) {
            return res.status(404).json({ message: 'Schedule not found' });
        }

        if (!className || !scheduleDate || !faculty || !title) {
            return res.status(400).json({ message: 'class, scheduleDate, faculty, and title are required' });
        }


        // Validate faculty exists
        const existingFaculty = await Speaker.findById(faculty);
        if (!existingFaculty) {
            return res.status(404).json({ message: 'Faculty not found' });
        }

        const updated = await Schedule.findByIdAndUpdate(
            req.params.id,
            { class: className, scheduleDate, faculty, title },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation');

        res.json({ message: 'Schedule updated successfully', schedule: updated });
    } catch (error) {
        console.error('Error updating schedule:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/schedules/:id - Delete schedule (admin only)
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const deleted = await Schedule.findByIdAndDelete(req.params.id);
        if (!deleted) {
            return res.status(404).json({ message: 'Schedule not found' });
        }
        res.json({ message: 'Schedule deleted successfully', id: deleted._id });
    } catch (error) {
        console.error('Error deleting schedule:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;


