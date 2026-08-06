import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'
import { useAuth } from '../context/AuthContext'

export default function Register() {
  const { register } = useAuth()
  const navigate = useNavigate()
  const [form, setForm] = useState({
    full_name: '',
    email: '',
    password: '',
  })
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  function update(key, value) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function onSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    try {
      await register(form)
      navigate('/app')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Layout>
      <div className="panel" style={{ maxWidth: 440, margin: '2rem auto' }}>
        <h2 style={{ marginTop: 0 }}>Create account</h2>
        <p className="muted">Start managing queues for your business.</p>
        <form className="form" onSubmit={onSubmit}>
          <label>
            Full name
            <input
              value={form.full_name}
              onChange={(e) => update('full_name', e.target.value)}
              required
            />
          </label>
          <label>
            Email
            <input
              value={form.email}
              onChange={(e) => update('email', e.target.value)}
              type="email"
              required
            />
          </label>
          <label>
            Password
            <input
              value={form.password}
              onChange={(e) => update('password', e.target.value)}
              type="password"
              minLength={6}
              required
            />
          </label>
          {error && <div className="error">{error}</div>}
          <button className="btn" disabled={busy} type="submit">
            {busy ? 'Creating…' : 'Create account'}
          </button>
        </form>
        <p className="muted" style={{ marginBottom: 0 }}>
          Already registered? <Link to="/login">Sign in</Link>
        </p>
      </div>
    </Layout>
  )
}
