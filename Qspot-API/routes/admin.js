const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/user');
const { authenticateToken } = require('../middlewares/auth');
const router = express.Router();

// Admin login route
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        // Check if credentials are provided
        if (!username || !password) {
            return res.status(400).json({ 
                message: 'Username and password are required' 
            });
        }

        // Get hardcoded credentials from environment variables
        const adminUsername = process.env.ADMIN_USERNAME;
        const adminPassword = process.env.ADMIN_PASSWORD;

        // Check if environment variables are set
        if (!adminUsername || !adminPassword) {
            return res.status(500).json({ 
                message: 'Admin credentials not configured' 
            });
        }

        // Verify credentials
        if (username !== adminUsername) {
            return res.status(401).json({ 
                message: 'Invalid credentials' 
            });
        }

        // Compare password (assuming it's hashed in env or plain text)
        const isPasswordValid = await bcrypt.compare(password, adminPassword) || password === adminPassword;

        if (!isPasswordValid) {
            return res.status(401).json({ 
                message: 'Invalid credentials' 
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            { 
                username: adminUsername,
                role: 'admin'
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            message: 'Login successful',
            token,
        });

    } catch (error) {
        console.error('Admin login error:', error);
        res.status(500).json({ 
            message: 'Internal server error' 
        });
    }
});

// GET /api/admin/users - Get all users (admin only)
router.get('/users', authenticateToken, async (req, res) => {
    try {
        const users = await User.find().sort({ createdAt: -1 });
        res.json({
            message: 'Users retrieved successfully',
            users,
            count: users.length
        });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ 
            message: 'Internal server error' 
        });
    }
});

// GET /api/admin/users/:id - Get single user (admin only)
router.get('/users/:id', authenticateToken, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({
            message: 'User retrieved successfully',
            user
        });
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ 
            message: 'Internal server error' 
        });
    }
});

// PUT /api/admin/users/:id - Update user (admin only)
router.put('/users/:id', authenticateToken, async (req, res) => {
    try {
        const { name, phone, email, class: userClass } = req.body;
        
        if (!name || !phone || !userClass) {
            return res.status(400).json({ 
                message: 'Name, phone, and class are required' 
            });
        }

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if phone number is being changed and if it already exists
        if (phone !== user.phone) {
            const existingUser = await User.findOne({ phone });
            if (existingUser) {
                return res.status(400).json({ 
                    message: 'Phone number already exists' 
                });
            }
        }

        const updatedUser = await User.findByIdAndUpdate(
            req.params.id,
            { name, phone, email: email || '', class: userClass },
            { new: true, runValidators: true }
        );

        res.json({
            message: 'User updated successfully',
            user: updatedUser
        });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ 
            message: 'Internal server error' 
        });
    }
});

// DELETE /api/admin/users/:id - Delete user (admin only)
router.delete('/users/:id', authenticateToken, async (req, res) => {
    try {
        const user = await User.findByIdAndDelete(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.json({
            message: 'User deleted successfully',
            user
        });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ 
            message: 'Internal server error' 
        });
    }
});

module.exports = router;
