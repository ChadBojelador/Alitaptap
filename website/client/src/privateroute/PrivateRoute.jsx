import { Navigate } from 'react-router-dom';

const PrivateRoute = ({ user, children }) => {
  if (!user) {
    // If no user is logged in, send them to /login
    return <Navigate to="/login" replace />;
  }
  return children;
};

export default PrivateRoute;