import React, { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import apiClient, { isLoggedIn, setToken } from '../api/client';
import usePageTitle from '../hooks/usePageTitle';
import logo from '../assets/Logo 01 Color.png';

const AdminLogin = () => {
    usePageTitle('Login');
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        username: '',
        password: ''
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    // Already logged in? Skip the form entirely.
    if (isLoggedIn()) {
        return <Navigate to="/admin/dashboard" replace />;
    }

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
        if (error) setError('');
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const response = await apiClient.post('/admin/login', formData);
            if (response.data.token) {
                setToken(response.data.token);
                navigate('/admin/dashboard', { replace: true });
            } else {
                setError('Login failed. Please try again.');
            }
        } catch (err) {
            setError(err.message || 'Login failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="relative min-h-screen bg-black flex items-center justify-center py-12 px-4 overflow-hidden">
            <div
                className="pointer-events-none absolute -bottom-36 -left-40 h-[110vh] w-[100vw] rounded-[28rem] bg-gradient-to-br from-[#11060d]/95 via-[#1c0b18]/85 to-[#12060f]/95 opacity-90 blur-[140px]"
            />

            <div className="relative z-10 flex w-full max-w-6xl flex-col items-center justify-between gap-8 md:flex-row md:gap-12">
                <div className="flex flex-1 justify-center md:justify-start">
                    <img
                        src={logo}
                        alt="QSPOT Logo"
                        className="h-auto w-40 max-w-full sm:w-56 md:w-auto md:-ml-28"
                    />
                </div>

                <div className="w-full max-w-sm flex-1 px-2 sm:px-0">
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
                                {loading ? 'Signing in...' : 'Sign in'}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default AdminLogin;
