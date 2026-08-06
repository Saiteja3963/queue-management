import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { api } from '../api'
import Layout from '../components/Layout'

export default function PublicQueue() {
  const { orgSlug, queueSlug } = useParams()
  const navigate = useNavigate()
  const [queue, setQueue] = useState(null)
  const [form, setForm] = useState({ customer_name: '', customer_phone: '' })
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    let alive = true
    async function load() {
      try {
        const data = await api.getPublicQueue(orgSlug, queueSlug)
        if (alive) setQueue(data)
      } catch (err) {
        if (alive) setError(err.message)
      }
    }
    load()
    const id = setInterval(load, 6000)
    return () => {
      alive = false
      clearInterval(id)
    }
  }, [orgSlug, queueSlug])

  async function join(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      const ticket = await api.joinQueue(orgSlug, queueSlug, form)
      navigate(`/ticket/${ticket.id}`)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Layout>
      <section className="hero" style={{ paddingTop: '2rem' }}>
        <p className="badge">{queue?.organization_name || 'Queue'}</p>
        <h1>{queue?.name || 'Join queue'}</h1>
        <p>{queue?.description || 'Take a number and track your place in line.'}</p>
      </section>

      <div className="grid two">
        <div className="panel">
          <div className="grid three">
            <div className="stat">
              <div className="label">Waiting</div>
              <div className="value">{queue?.waiting_count ?? '—'}</div>
            </div>
            <div className="stat">
              <div className="label">Serving</div>
              <div className="value">{queue?.serving_count ?? '—'}</div>
            </div>
            <div className="stat">
              <div className="label">Est. wait</div>
              <div className="value">
                {queue
                  ? `${queue.waiting_count * queue.avg_service_minutes}m`
                  : '—'}
              </div>
            </div>
          </div>
          <p className="muted" style={{ marginBottom: 0, marginTop: '1rem' }}>
            Status:{' '}
            <span className={`badge ${queue?.is_open ? 'serving' : 'cancelled'}`}>
              {queue?.is_open ? 'Open for new tickets' : 'Closed'}
            </span>
          </p>
        </div>

        <div className="panel">
          <h3 style={{ marginTop: 0 }}>Get your number</h3>
          <form className="form" onSubmit={join}>
            <label>
              Your name
              <input
                value={form.customer_name}
                onChange={(e) => setForm({ ...form, customer_name: e.target.value })}
                required
              />
            </label>
            <label>
              Phone (optional)
              <input
                value={form.customer_phone}
                onChange={(e) => setForm({ ...form, customer_phone: e.target.value })}
              />
            </label>
            {error && <div className="error">{error}</div>}
            <button className="btn" disabled={busy || !queue?.is_open} type="submit">
              {busy ? 'Joining…' : 'Join queue'}
            </button>
          </form>
          <p className="muted">
            Staff? <Link to="/login">Sign in to manage</Link>
          </p>
        </div>
      </div>
    </Layout>
  )
}
