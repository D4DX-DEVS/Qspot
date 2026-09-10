const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const Question = require('../models/question');
const { requestWhatsappOtp, verifyWhatsappOtp } = require('../services/otpWhatsapp');
const { authenticateUser } = require('../middlewares/auth');

const router = express.Router();

// POST /api/user/register
router.post('/register', async (req, res) => {
  try {
    const { name, phone, class: userClass, email } = req.body || {};
    
    // Validate required fields
    if (!name || !phone || !userClass) {
      return res.status(400).json({ 
        ok: false, 
        error: 'Name, phone, and class are required' 
      });
    }
    
    // Check if user already exists
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ 
        ok: false, 
        error: 'User with this phone number already exists' 
      });
    }
    
    // Create new user
    const user = await User.create({
      name,
      phone,
      class: userClass,
      email: email || ''
    });
    
    return res.json({ 
      ok: true, 
      message: 'User registered successfully',
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        class: user.class,
        email: user.email
      }
    });
    
  } catch (err) {
    console.error('User registration error:', err?.message || err);
    return res.status(500).json({ ok: false, error: 'Registration failed' });
  }
});

// POST /api/user/login/request-otp
router.post('/login/request-otp', async (req, res) => {
  try {
    const { phone } = req.body || {};
    if (!phone) return res.status(400).json({ ok: false, error: 'Phone is required' });

    // Check if user is registered
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ 
        ok: false, 
        error: 'User not registered. Please register first.' 
      });
    }

    const result = await requestWhatsappOtp(phone);
    return res.json(result);
  } catch (err) {
    console.error('request-otp error:', err?.message || err);
    return res.status(500).json({ ok: false, error: 'Failed to send OTP' });
  }
});

// POST /api/users/login/verify
router.post('/login/verify', async (req, res) => {
  try {
    const { phone, code } = req.body || {};
    if (!phone || !code) return res.status(400).json({ ok: false, error: 'Phone and code are required' });

    // Check for test login credentials
    const testLogin = process.env.TEST_LOGIN;
    const testOtp = process.env.TEST_OTP;
    const isTestLogin = testLogin && testOtp && phone === testLogin && code === testOtp;
    
    let verify = { ok: false };
    
    // If test credentials match, bypass OTP verification
    if (isTestLogin) {
      console.log('Test login credentials used');
      verify = { ok: true };
    } else {
      // Normal OTP verification flow
      verify = await verifyWhatsappOtp(phone, code);
      if (!verify.ok) return res.status(400).json(verify);
    }

    // Find existing user or create for test login
    let user = await User.findOne({ phone });
    if (!user) {
      // For test login, auto-create user with default values
      if (isTestLogin) {
        console.log('Auto-creating test user');
        user = await User.create({
          name: 'Test User',
          phone: phone,
          class: 'Test Class',
          email: ''
        });
      } else {
        return res.status(404).json({ 
          ok: false, 
          error: 'User not found. Please register first.' 
        });
      }
    }

    const token = jwt.sign(
      { userId: user._id, phone: user.phone, role: 'user' },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.json({ ok: true, token, user });
  } catch (err) {
    console.error('verify-otp error:', err?.message || err);
    return res.status(500).json({ ok: false, error: 'Verification failed' });
  }
});

// GET /api/users/my-questions - Get questions created by authenticated user
router.get('/my-questions', authenticateUser, async (req, res) => {
  try {
    const questions = await Question.find({ user: req.user.id })
      .populate('faculty', 'name designation')
      .populate('user', 'name class')
      .sort({ createdAt: -1 });
    res.json(questions);
  } catch (error) {
    console.error('Error fetching user questions:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /api/users/my-questions/:id - Get user's own question with answer (if exists)
router.get('/my-questions/:id', authenticateUser, async (req, res) => {
  try {
    const question = await Question.findOne({ 
      _id: req.params.id, 
      user: req.user.id 
    })
    .populate('faculty', 'name designation')
    .populate('user', 'name class');
    
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