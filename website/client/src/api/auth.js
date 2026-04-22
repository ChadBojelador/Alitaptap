import axios from 'axios';

const API = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  withCredentials: true
});

export const getProfile = () => API.get('/profile');
export const logoutUser = () => API.get('/logout');