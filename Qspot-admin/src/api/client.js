import axios from 'axios';

// Single axios instance for the whole admin app. Every page should import
// this instead of calling axios directly, so auth headers, 401/403 handling
// and error messages are consistent everywhere.

const baseURL = import.meta.env.VITE_API_BASE_URL;

if (!baseURL) {
  console.error('VITE_API_BASE_URL is not set. Copy .env.example to .env.');
}

export const TOKEN_KEY = 'adminToken';

export const getToken = () => localStorage.getItem(TOKEN_KEY);
export const setToken = (token) => localStorage.setItem(TOKEN_KEY, token);
export const clearToken = () => localStorage.removeItem(TOKEN_KEY);
export const isLoggedIn = () => Boolean(getToken());

const apiClient = axios.create({ baseURL });

apiClient.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers = config.headers || {};
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    if (status === 401 || status === 403) {
      clearToken();
      if (typeof window !== 'undefined' && window.location.pathname !== '/admin/login') {
        window.location.href = '/admin/login';
      }
    }

    // Surface the API's { message } consistently as error.message so pages
    // can just do `catch (err) { setError(err.message) }`.
    const message =
      error.response?.data?.message ||
      (status ? `Request failed (${status})` : error.message || 'Network error');
    error.message = message;
    return Promise.reject(error);
  }
);

export default apiClient;
