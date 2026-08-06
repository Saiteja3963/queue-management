import { Link } from 'react-router-dom'
import Layout from '../components/Layout'
import { useAuth } from '../context/AuthContext'

export default function Home() {
  const { user } = useAuth()

  return (
    <Layout>
      <section className="hero">
        <p className="badge">Multi-business queue platform</p>
        <h1>QueueFlow</h1>
        <p>
          Create queues for any business, manage them from a staff console, and
          let customers join with a simple public link — plus live insights per queue.
        </p>
        <div className="cta-row">
          {user ? (
            <Link className="btn" to="/app">
              Open dashboard
            </Link>
          ) : (
            <>
              <Link className="btn" to="/register">
                Create account
              </Link>
              <Link className="btn secondary" to="/login">
                Sign in
              </Link>
            </>
          )}
          <Link className="btn secondary" to="/q/city-care/general-practice">
            Try public queue
          </Link>
        </div>
        <div className="demo-hint">
          Demo login: <strong>admin@demo.com</strong> / <strong>password123</strong>
        </div>
      </section>

      <div className="grid three" style={{ marginTop: '2rem' }}>
        <div className="panel">
          <h3>Per-business isolation</h3>
          <p className="muted">
            Organizations own their queues, staff, and tickets — ready for clinics,
            banks, retail, and more.
          </p>
        </div>
        <div className="panel">
          <h3>Admin & customer views</h3>
          <p className="muted">
            Staff call the next ticket and update status. Customers join and track
            position without an account.
          </p>
        </div>
        <div className="panel">
          <h3>Queue insights</h3>
          <p className="muted">
            Waiting counts, average wait, throughput, peak hour, and status
            breakdown for each queue.
          </p>
        </div>
      </div>
    </Layout>
  )
}
