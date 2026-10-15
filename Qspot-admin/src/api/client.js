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

const technicalMessage = (value) => {
  if (!value) return true;
  const message = String(value).trim();
  if (!message) return true;
  return /axios|network error|timeout|failed to fetch|socket|errno|uri=|exception|internal server error|bad gateway|service unavailable|request failed \(\d+\)/i.test(message);
};

/**
 * Converts transport and infrastructure errors into copy that admins can
 * understand and act on. Keep the original Axios error available for logs;
 * only this safe message is assigned to error.message for UI consumers.
 */
export const toUserMessage = (error, fallback = 'Something went wrong. Please try again.') => {
  const status = error?.response?.status;
  const serverMessage = error?.response?.data?.message;

  if (!status && (error?.code === 'ECONNABORTED' || /timeout/i.test(error?.message || ''))) {
    return 'The request is taking longer than usual. Please try again.';
  }
  if (!status && (error?.request || /network error|failed to fetch|socket/i.test(error?.message || ''))) {
    return 'We couldn’t reach the server. Check your connection and try again.';
  }
  if (status === 401) return 'Your session has expired. Please sign in again.';
  if (status === 403) return 'You don’t have permission to do that.';
  if (status === 404) return technicalMessage(serverMessage) ? 'We couldn’t find what you requested.' : serverMessage;
  if (status === 409) return technicalMessage(serverMessage) ? 'This action conflicts with existing data. Please review it and try again.' : serverMessage;
  if (status === 413) return 'That file is too large. Choose a smaller file and try again.';
  if (status === 429) return 'Too many requests. Please wait a moment and try again.';
  if (status >= 500) return 'Something went wrong on our side. Please try again in a moment.';
  if (serverMessage && !technicalMessage(serverMessage)) return serverMessage;
  return fallback;
};

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
    error.message = toUserMessage(error);
    return Promise.reject(error);
  }
);

export default apiClient;
