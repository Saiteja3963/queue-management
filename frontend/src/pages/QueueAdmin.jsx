import { useCallback, useEffect, useState } from 'react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { api } from '../api'
import Layout from '../components/Layout'
import { useAuth } from '../context/AuthContext'

export default function QueueAdmin() {
  const { queueId } = useParams()
  const { user, loading } = useAuth()
  const [queue, setQueue] = useState(null)
  const [tickets, setTickets] = useState([])
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    try {
      const [q, t] = await Promise.all([
        api.getQueue(queueId),
        api.listTickets(queueId, 'waiting,called,serving'),
      ])
      setQueue(q)
      setTickets(t)
    } catch (err) {
      setError(err.message)
    }
  }, [queueId])

  useEffect(() => {
    if (user) load()
    const id = setInterval(() => {
      if (user) load()
    }, 5000)
    return () => clearInterval(id)
  }, [user, load])

  if (loading) {
    return (
      <Layout>
        <p className="muted">Loading…</p>
      </Layout>
    )
  }
  if (!user) return <Navigate to="/login" replace />

  async function callNext() {
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const ticket = await api.callNext(queueId)
      setMessage(`Called ${ticket.display_code} — ${ticket.customer_name}`)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function setStatus(ticketId, status) {
    setBusy(true)
    setError('')
    try {
      await api.updateTicketStatus(ticketId, { status })
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function toggleOpen() {
    setBusy(true)
    try {
      const updated = await api.updateQueue(queueId, { is_open: !queue.is_open })
      setQueue(updated)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const waiting = tickets.filter((t) => t.status === 'waiting')
  const active = tickets.filter((t) => t.status === 'called' || t.status === 'serving')

  return (
    <Layout>
      <div className="section-title">
        <div>
          <p className="muted" style={{ margin: 0 }}>
            <Link to={`/app/orgs/${queue?.organization_id}`}>Back to org</Link>
          </p>
          <h2>{queue?.name || 'Queue'}</h2>
          <p className="muted" style={{ margin: 0 }}>
            {queue?.organization_name} · Staff console
          </p>
        </div>
        <div className="split">
          <Link className="btn secondary" to={`/app/queues/${queueId}/insights`}>
            Insights
          </Link>
          <button className="btn secondary" disabled={busy} onClick={toggleOpen} type="button">
            {queue?.is_open ? 'Close queue' : 'Open queue'}
          </button>
          <button className="btn pulse" disabled={busy} onClick={callNext} type="button">
            Call next
          </button>
        </div>
      </div>

      {error && <div className="error" style={{ marginBottom: '1rem' }}>{error}</div>}
      {message && <div className="success" style={{ marginBottom: '1rem' }}>{message}</div>}

      <div className="grid three" style={{ marginBottom: '1rem' }}>
        <div className="stat">
          <div className="label">Waiting</div>
          <div className="value">{waiting.length}</div>
        </div>
        <div className="stat">
          <div className="label">Now serving</div>
          <div className="value">{active.length}</div>
        </div>
        <div className="stat">
          <div className="label">Completed today</div>
          <div className="value">{queue?.completed_today ?? 0}</div>
        </div>
      </div>

      <div className="grid two">
        <div className="panel">
          <h3 style={{ marginTop: 0 }}>Active</h3>
          <div className="list">
            {active.length === 0 && <p className="muted">No tickets being served.</p>}
            {active.map((t) => (
              <div className="list-item" key={t.id}>
                <div className="stack">
                  <strong>
                    {t.display_code} · {t.customer_name}
                  </strong>
                  <span className={`badge ${t.status}`}>{t.status}</span>
                </div>
                <div className="split">
                  {t.status === 'called' && (
                    <button
                      className="btn small"
                      disabled={busy}
                      onClick={() => setStatus(t.id, 'serving')}
                      type="button"
                    >
                      Start
                    </button>
                  )}
                  <button
                    className="btn small"
                    disabled={busy}
                    onClick={() => setStatus(t.id, 'completed')}
                    type="button"
                  >
                    Complete
                  </button>
                  <button
                    className="btn small secondary"
                    disabled={busy}
                    onClick={() => setStatus(t.id, 'skipped')}
                    type="button"
                  >
                    Skip
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="panel">
          <h3 style={{ marginTop: 0 }}>Waiting line</h3>
          <div className="list">
            {waiting.length === 0 && <p className="muted">Queue is empty.</p>}
            {waiting.map((t) => (
              <div className="list-item" key={t.id}>
                <div className="stack">
                  <strong>
                    #{t.position} · {t.display_code}
                  </strong>
                  <span className="muted">{t.customer_name}</span>
                </div>
                <button
                  className="btn small danger"
                  disabled={busy}
                  onClick={() => setStatus(t.id, 'cancelled')}
                  type="button"
                >
                  Cancel
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  )
}
