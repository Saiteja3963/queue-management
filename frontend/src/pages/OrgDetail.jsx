import { useEffect, useState } from 'react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { api } from '../api'
import Layout from '../components/Layout'
import { useAuth } from '../context/AuthContext'

function slugify(value) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}

export default function OrgDetail() {
  const { orgId } = useParams()
  const { user, loading } = useAuth()
  const [org, setOrg] = useState(null)
  const [queues, setQueues] = useState([])
  const [error, setError] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    name: '',
    slug: '',
    description: '',
    ticket_prefix: 'A',
    avg_service_minutes: 5,
  })
  const [busy, setBusy] = useState(false)

  async function load() {
    try {
      const [orgData, queueData] = await Promise.all([
        api.getOrg(orgId),
        api.listQueues(orgId),
      ])
      setOrg(orgData)
      setQueues(queueData)
    } catch (err) {
      setError(err.message)
    }
  }

  useEffect(() => {
    if (user) load()
  }, [user, orgId])

  if (loading) {
    return (
      <Layout>
        <p className="muted">Loading…</p>
      </Layout>
    )
  }
  if (!user) return <Navigate to="/login" replace />

  async function createQueue(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      await api.createQueue(orgId, {
        ...form,
        avg_service_minutes: Number(form.avg_service_minutes),
      })
      setShowForm(false)
      setForm({
        name: '',
        slug: '',
        description: '',
        ticket_prefix: 'A',
        avg_service_minutes: 5,
      })
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Layout>
      <div className="section-title">
        <div>
          <p className="muted" style={{ margin: 0 }}>
            <Link to="/app">Businesses</Link> / {org?.name || '…'}
          </p>
          <h2>{org?.name || 'Organization'}</h2>
          <p className="muted" style={{ margin: 0 }}>{org?.description}</p>
        </div>
        <button className="btn" onClick={() => setShowForm((v) => !v)} type="button">
          {showForm ? 'Cancel' : 'New queue'}
        </button>
      </div>

      {error && <div className="error" style={{ marginBottom: '1rem' }}>{error}</div>}

      {showForm && (
        <div className="panel" style={{ marginBottom: '1rem' }}>
          <form className="form" onSubmit={createQueue}>
            <div className="grid two">
              <label>
                Queue name
                <input
                  value={form.name}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      name: e.target.value,
                      slug: slugify(e.target.value),
                    })
                  }
                  required
                />
              </label>
              <label>
                Slug
                <input
                  value={form.slug}
                  onChange={(e) => setForm({ ...form, slug: slugify(e.target.value) })}
                  required
                />
              </label>
              <label>
                Ticket prefix
                <input
                  value={form.ticket_prefix}
                  maxLength={10}
                  onChange={(e) => setForm({ ...form, ticket_prefix: e.target.value })}
                  required
                />
              </label>
              <label>
                Avg service (minutes)
                <input
                  type="number"
                  min={1}
                  max={180}
                  value={form.avg_service_minutes}
                  onChange={(e) =>
                    setForm({ ...form, avg_service_minutes: e.target.value })
                  }
                  required
                />
              </label>
            </div>
            <label>
              Description
              <textarea
                rows={3}
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </label>
            <button className="btn" disabled={busy} type="submit">
              {busy ? 'Creating…' : 'Create queue'}
            </button>
          </form>
        </div>
      )}

      <div className="list">
        {queues.map((q) => (
          <div className="list-item" key={q.id}>
            <div className="stack">
              <strong>{q.name}</strong>
              <span className="muted">
                Waiting {q.waiting_count} · Serving {q.serving_count} · Done today{' '}
                {q.completed_today}
              </span>
              <span className="muted">
                Public link: /q/{org?.slug}/{q.slug}
              </span>
            </div>
            <div className="split">
              <span className={`badge ${q.is_open ? 'serving' : 'cancelled'}`}>
                {q.is_open ? 'Open' : 'Closed'}
              </span>
              <Link className="btn small secondary" to={`/app/queues/${q.id}`}>
                Manage
              </Link>
              <Link className="btn small" to={`/app/queues/${q.id}/insights`}>
                Insights
              </Link>
              <Link
                className="btn small ghost"
                to={`/q/${org?.slug}/${q.slug}`}
                target="_blank"
                rel="noreferrer"
              >
                User view
              </Link>
            </div>
          </div>
        ))}
        {queues.length === 0 && (
          <div className="panel muted">No queues yet. Create the first one.</div>
        )}
      </div>
    </Layout>
  )
}
