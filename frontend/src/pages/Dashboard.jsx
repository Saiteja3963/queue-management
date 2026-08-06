import { useEffect, useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
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

export default function Dashboard() {
  const { user, loading } = useAuth()
  const [memberships, setMemberships] = useState([])
  const [error, setError] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', slug: '', description: '' })
  const [busy, setBusy] = useState(false)

  async function load() {
    try {
      const data = await api.listOrgs()
      setMemberships(data)
    } catch (err) {
      setError(err.message)
    }
  }

  useEffect(() => {
    if (user) load()
  }, [user])

  if (loading) {
    return (
      <Layout>
        <p className="muted">Loading…</p>
      </Layout>
    )
  }

  if (!user) return <Navigate to="/login" replace />

  async function createOrg(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      await api.createOrg(form)
      setForm({ name: '', slug: '', description: '' })
      setShowForm(false)
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
          <h2>Your businesses</h2>
          <p className="muted" style={{ margin: 0 }}>
            Each organization has its own queues, staff, and insights.
          </p>
        </div>
        <button className="btn" onClick={() => setShowForm((v) => !v)} type="button">
          {showForm ? 'Cancel' : 'New organization'}
        </button>
      </div>

      {error && <div className="error" style={{ marginBottom: '1rem' }}>{error}</div>}

      {showForm && (
        <div className="panel" style={{ marginBottom: '1rem' }}>
          <form className="form" onSubmit={createOrg}>
            <label>
              Business name
              <input
                value={form.name}
                onChange={(e) =>
                  setForm({
                    name: e.target.value,
                    slug: slugify(e.target.value),
                    description: form.description,
                  })
                }
                required
              />
            </label>
            <label>
              URL slug
              <input
                value={form.slug}
                onChange={(e) => setForm({ ...form, slug: slugify(e.target.value) })}
                pattern="^[a-z0-9-]+$"
                required
              />
            </label>
            <label>
              Description
              <textarea
                rows={3}
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </label>
            <button className="btn" disabled={busy} type="submit">
              {busy ? 'Creating…' : 'Create organization'}
            </button>
          </form>
        </div>
      )}

      <div className="list">
        {memberships.length === 0 && (
          <div className="panel muted">No organizations yet. Create one to get started.</div>
        )}
        {memberships.map((m) => (
          <Link className="list-item" key={m.id} to={`/app/orgs/${m.organization.id}`}>
            <div className="stack">
              <strong>{m.organization.name}</strong>
              <span className="muted">/{m.organization.slug}</span>
            </div>
            <span className="badge">{m.role}</span>
          </Link>
        ))}
      </div>
    </Layout>
  )
}
