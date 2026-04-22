import { Routes, Route, Navigate } from 'react-router-dom';
import LoginRegister from '../pages/LoginRegister';
import Dashboard from '../pages/Dashboard';
import PrivateRoute from '../components/PrivateRoute';

export default function AppRoutes({ user, loading }) {
  // 1. Loading State (Prevents flickering while checking MySQL)
  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', marginTop: '100px' }}>
        <h2>Checking authentication...</h2>
      </div>
    );
  }

  return (
    <Routes>
      {/* Public Route: Login/Signup */}
      <Route path="/login" element={
        user ? <Navigate to="/dashboard" replace /> : <LoginRegister />
      } />

      {/* PROTECTED ROUTE: Dashboard */}
      <Route 
        path="/dashboard" 
        element={
          <PrivateRoute user={user}>
            <Dashboard user={user} />
          </PrivateRoute>
        } 
      />

      {/* Default Redirects */}
      <Route path="/" element={<Navigate to={user ? "/dashboard" : "/login"} replace />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}