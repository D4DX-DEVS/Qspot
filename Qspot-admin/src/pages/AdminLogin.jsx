import React, { useState } from 'react';
import axios from 'axios';
import logo from '../assets/Logo 01 Color.png';

const AdminLogin = () => {
    const [formData, setFormData] = useState({
        username: '',
        password: ''
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
        // Clear error when user starts typing
        if (error) setError('');
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setSuccess('');

         try {
             const baseURL = import.meta.env.VITE_API_BASE_URL;
             const response = await axios.post(`${baseURL}/admin/login`, formData);

            if (response.data.token) {
                // Store token in localStorage
                localStorage.setItem('adminToken', response.data.token);
                setSuccess('Login successful!');

                // Redirect to admin dashboard or home page
                setTimeout(() => {
                    window.location.href = '/admin/dashboard';
                }, 1500);
            }
        } catch (err) {
            if (err.response?.data?.message) {
                setError(err.response.data.message);
            } else {
                setError('Login failed. Please try again.');
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="relative min-h-screen bg-black flex items-center justify-center py-12 px-4 overflow-hidden">
            <div
                className="pointer-events-none absolute -bottom-36 -left-40 h-[110vh] w-[100vw] rounded-[28rem] bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 opacity-90 blur-[140px]"
                //  "
            />

            <div className="relative z-10 w-full max-w-6xl flex items-center justify-between gap-12">
                {/* Logo Section - Left Side */}
                <div className="flex-1 flex justify-start">
                    <img
                        src={logo}
                        alt="QSPOT Logo"
                        className="h-auto w-auto -ml-28"
                    />
                </div>

                {/* Form Section - Right Side */}
                <div className="flex-1 max-w-sm">
                    <form className="space-y-6" onSubmit={handleSubmit}>
                        <div>
                            <div className="mt-1">
                                <input
                                    id="username"
                                    name="username"
                                    type="text"
                                    required
                                    value={formData.username}
                                    onChange={handleChange}
                                    className="appearance-none block w-full px-4 py-3 border border-gray-600 bg-black text-white rounded-full placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#701845] focus:border-transparent sm:text-sm transition-all duration-200"
                                    placeholder="Enter your username"
                                />
                            </div>
                        </div>

                        <div>

                            <div className="mt-1">
                                <input
                                    id="password"
                                    name="password"
                                    type="password"
                                    required
                                    value={formData.password}
                                    onChange={handleChange}
                                    className="appearance-none block w-full px-4 py-3 border border-gray-600 bg-black text-white rounded-full placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#701845] focus:border-transparent sm:text-sm transition-all duration-200"
                                    placeholder="Enter your password"
                                />
                            </div>
                        </div>

                        {error && (
                            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
                                {error}
                            </div>
                        )}

                        <div className="pt-4">
                            <button
                                type="submit"
                                disabled={loading}
                                className="w-3/4 mx-auto flex justify-center py-3 px-6 rounded-full text-sm font-medium text-white bg-gradient-to-r from-[#701845] to-[#EFB078] hover:from-[#5a1538] hover:to-[#d49a6a] focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 shadow-lg hover:shadow-xl"
                            >
                                {loading ? 'Signing in...' : success ? success : 'Sign in'}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default AdminLogin;
