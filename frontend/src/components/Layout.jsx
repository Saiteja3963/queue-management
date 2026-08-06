import { Link, NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Layout({ children }) {
  const { user, logout } = useAuth()

  return (
    <div className="app-shell">
      <header className="topbar">
        <Link to="/" className="brand">
          QueueFlow <span>Management</span>
        </Link>
        <div className="nav-actions">
          {user ? (
            <>
              <NavLink to="/app" className="btn ghost small">
                Dashboard
              </NavLink>
              <span className="muted">{user.full_name}</span>
              <button className="btn secondary small" onClick={logout} type="button">
                Sign out
              </button>
            </>
          ) : (
            <>
              <NavLink to="/login" className="btn secondary small">
                Sign in
              </NavLink>
              <NavLink to="/register" className="btn small">
                Get started
              </NavLink>
            </>
          )}
        </div>
      </header>
      <main className="container">{children}</main>
    </div>
  )
}
