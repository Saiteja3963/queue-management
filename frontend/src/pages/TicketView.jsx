import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '../api'
import Layout from '../components/Layout'

export default function TicketView() {
  const { ticketId } = useParams()
  const [ticket, setTicket] = useState(null)
  const [queue, setQueue] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    let alive = true
    async function load() {
      try {
        const t = await api.getTicket(ticketId)
        if (!alive) return
        setTicket(t)
        const q = await api.getQueue(t.queue_id)
        if (alive) setQueue(q)
      } catch (err) {
        if (alive) setError(err.message)
      }
    }
    load()
    const id = setInterval(load, 4000)
    return () => {
      alive = false
      clearInterval(id)
    }
  }, [ticketId])

  return (
    <Layout>
      <div className="panel" style={{ maxWidth: 520, margin: '2rem auto', textAlign: 'center' }}>
        {error && <div className="error">{error}</div>}
        {ticket && (
          <>
            <p className="muted" style={{ marginTop: 0 }}>
              {queue?.organization_name} · {queue?.name}
            </p>
            <div className="ticket-code pulse">{ticket.display_code}</div>
            <p>
              <span className={`badge ${ticket.status}`}>{ticket.status}</span>
            </p>
            <h3 style={{ marginBottom: 0 }}>{ticket.customer_name}</h3>
            {ticket.status === 'waiting' && (
              <p className="muted">
                Position {ticket.position} · Est. wait {ticket.estimated_wait_minutes} min
              </p>
            )}
            {ticket.status === 'called' && (
              <div className="success">You have been called. Please proceed.</div>
            )}
            {ticket.status === 'serving' && (
              <div className="success">You are being served now.</div>
            )}
            {ticket.status === 'completed' && (
              <p className="muted">Service completed. Thank you.</p>
            )}
            {['skipped', 'cancelled'].includes(ticket.status) && (
              <p className="muted">This ticket is no longer active.</p>
            )}
            {queue && (
              <p style={{ marginBottom: 0 }}>
                <Link to={`/q/${queue.organization_slug}/${queue.slug}`}>
                  Back to queue
                </Link>
              </p>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}
