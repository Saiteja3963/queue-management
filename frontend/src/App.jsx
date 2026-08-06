import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import Dashboard from './pages/Dashboard'
import Home from './pages/Home'
import Insights from './pages/Insights'
import Login from './pages/Login'
import OrgDetail from './pages/OrgDetail'
import PublicQueue from './pages/PublicQueue'
import QueueAdmin from './pages/QueueAdmin'
import Register from './pages/Register'
import TicketView from './pages/TicketView'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/app" element={<Dashboard />} />
          <Route path="/app/orgs/:orgId" element={<OrgDetail />} />
          <Route path="/app/queues/:queueId" element={<QueueAdmin />} />
          <Route path="/app/queues/:queueId/insights" element={<Insights />} />
          <Route path="/q/:orgSlug/:queueSlug" element={<PublicQueue />} />
          <Route path="/ticket/:ticketId" element={<TicketView />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
