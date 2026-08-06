import { useEffect, useState } from 'react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { api } from '../api'
import Layout from '../components/Layout'
import { useAuth } from '../context/AuthContext'

export default function Insights() {
  const { queueId } = useParams()
  const { user, loading } = useAuth()
  const [stats, setStats] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user) return
    let alive = true
    async function load() {
      try {
        const data = await api.insights(queueId)
        if (alive) setStats(data)
      } catch (err) {
        if (alive) setError(err.message)
      }
    }
    load()
    const id = setInterval(load, 8000)
    return () => {
      alive = false
      clearInterval(id)
    }
  }, [user, queueId])

  if (loading) {
    return (
      <Layout>
        <p className="muted">Loading…</p>
      </Layout>
    )
  }
  if (!user) return <Navigate to="/login" replace />

  const maxHour = Math.max(1, ...(stats?.hourly_completed.map((h) => h.count) || [1]))

  return (
    <Layout>
      <div className="section-title">
        <div>
          <p className="muted" style={{ margin: 0 }}>
            <Link to={`/app/queues/${queueId}`}>Back to queue</Link>
          </p>
          <h2>{stats?.queue_name || 'Insights'}</h2>
          <p className="muted" style={{ margin: 0 }}>Live management dashboard</p>
        </div>
      </div>

      {error && <div className="error">{error}</div>}

      {stats && (
        <>
          <div className="grid four" style={{ marginBottom: '1rem' }}>
            <div className="stat">
              <div className="label">Waiting</div>
              <div className="value">{stats.currently_waiting}</div>
            </div>
            <div className="stat">
              <div className="label">Serving / called</div>
              <div className="value">
                {stats.currently_serving + stats.currently_called}
              </div>
            </div>
            <div className="stat">
              <div className="label">Completed today</div>
              <div className="value">{stats.completed_today}</div>
            </div>
            <div className="stat">
              <div className="label">Est. wait (new)</div>
              <div className="value">{stats.estimated_wait_for_new}m</div>
            </div>
          </div>

          <div className="grid three" style={{ marginBottom: '1rem' }}>
            <div className="stat">
              <div className="label">Avg wait</div>
              <div className="value">{stats.avg_wait_minutes}m</div>
            </div>
            <div className="stat">
              <div className="label">Avg service</div>
              <div className="value">{stats.avg_service_minutes}m</div>
            </div>
            <div className="stat">
              <div className="label">Throughput / hour</div>
              <div className="value">{stats.throughput_per_hour}</div>
            </div>
          </div>

          <div className="grid two">
            <div className="panel">
              <h3 style={{ marginTop: 0 }}>Completions by hour (UTC)</h3>
              <p className="muted">
                Peak hour:{' '}
                {stats.peak_hour === null || stats.peak_hour === undefined
                  ? 'n/a'
                  : `${stats.peak_hour}:00`}
              </p>
              <div className="bar-chart">
                {stats.hourly_completed.map((h) => (
                  <div
                    className="bar"
                    key={h.hour}
                    title={`${h.hour}:00 — ${h.count}`}
                    style={{ height: `${Math.max(8, (h.count / maxHour) * 120)}px` }}
                  />
                ))}
              </div>
            </div>

            <div className="panel">
              <h3 style={{ marginTop: 0 }}>Status breakdown</h3>
              <div className="list">
                {Object.entries(stats.status_breakdown).map(([key, value]) => (
                  <div className="list-item" key={key}>
                    <span>{key.replaceAll('_', ' ')}</span>
                    <strong>{value}</strong>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="panel" style={{ marginTop: '1rem' }}>
            <h3 style={{ marginTop: 0 }}>Recent tickets</h3>
            <div className="list">
              {stats.recent_tickets.map((t) => (
                <div className="list-item" key={t.id}>
                  <div className="stack">
                    <strong>
                      {t.display_code} · {t.customer_name}
                    </strong>
                    <span className="muted">
                      {new Date(t.created_at).toLocaleString()}
                    </span>
                  </div>
                  <span className={`badge ${t.status}`}>{t.status}</span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </Layout>
  )
}
