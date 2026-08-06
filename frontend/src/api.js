const TOKEN_KEY = 'qf_token'

export function getToken() {
  return localStorage.getItem(TOKEN_KEY)
}

export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token)
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY)
}

async function request(path, options = {}) {
  const headers = {
    ...(options.body instanceof URLSearchParams
      ? { 'Content-Type': 'application/x-www-form-urlencoded' }
      : options.body
        ? { 'Content-Type': 'application/json' }
        : {}),
    ...options.headers,
  }
  const token = getToken()
  if (token) headers.Authorization = `Bearer ${token}`

  const res = await fetch(path, {
    ...options,
    headers,
    body:
      options.body && !(options.body instanceof URLSearchParams)
        ? JSON.stringify(options.body)
        : options.body,
  })

  if (!res.ok) {
    let detail = 'Request failed'
    try {
      const data = await res.json()
      detail = data.detail || detail
    } catch {
      /* ignore */
    }
    throw new Error(typeof detail === 'string' ? detail : JSON.stringify(detail))
  }

  if (res.status === 204) return null
  return res.json()
}

export const api = {
  register: (body) => request('/api/auth/register', { method: 'POST', body }),
  login: (email, password) =>
    request('/api/auth/login', {
      method: 'POST',
      body: new URLSearchParams({ username: email, password }),
    }),
  me: () => request('/api/auth/me'),
  listOrgs: () => request('/api/organizations'),
  createOrg: (body) => request('/api/organizations', { method: 'POST', body }),
  getOrg: (id) => request(`/api/organizations/${id}`),
  listQueues: (orgId) => request(`/api/organizations/${orgId}/queues`),
  createQueue: (orgId, body) =>
    request(`/api/organizations/${orgId}/queues`, { method: 'POST', body }),
  getQueue: (id) => request(`/api/queues/${id}`),
  updateQueue: (id, body) => request(`/api/queues/${id}`, { method: 'PATCH', body }),
  getPublicQueue: (orgSlug, queueSlug) =>
    request(`/api/public/${orgSlug}/${queueSlug}`),
  joinQueue: (orgSlug, queueSlug, body) =>
    request(`/api/public/${orgSlug}/${queueSlug}/join`, { method: 'POST', body }),
  listTickets: (queueId, statusFilter) =>
    request(
      `/api/queues/${queueId}/tickets${statusFilter ? `?status_filter=${statusFilter}` : ''}`,
    ),
  callNext: (queueId) => request(`/api/queues/${queueId}/call-next`, { method: 'POST' }),
  updateTicketStatus: (ticketId, body) =>
    request(`/api/tickets/${ticketId}/status`, { method: 'PATCH', body }),
  getTicket: (id) => request(`/api/tickets/${id}`),
  insights: (queueId) => request(`/api/queues/${queueId}/insights`),
}
