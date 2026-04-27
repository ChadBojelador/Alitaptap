import axios from 'axios';

const { hostname, port } = window.location;
const API = axios.create({
  baseURL: import.meta.env.VITE_API_URL || (port === '5173' ? `http://${hostname}:3000` : window.location.origin),
  withCredentials: true,
});

API.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) config.headers['Authorization'] = `Bearer ${token}`;
  return config;
});

export default API;