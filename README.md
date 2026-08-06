# QueueFlow — Multi-Business Queue Management

Scalable queue management for different businesses and systems. Each organization owns its queues, with separate **admin/staff** and **customer** perspectives, plus live insights per queue.

## Stack

- **Backend:** Python FastAPI + SQLAlchemy (SQLite)
- **Frontend:** React (Vite) + React Router

## Features

- Multi-tenant organizations (businesses)
- Queues per organization with public join links
- Staff console: call next, start, complete, skip, cancel
- Customer view: join queue, live ticket status & position
- Insights dashboard: wait times, throughput, peak hour, status breakdown

## Quick start

### Backend

```bash
cd backend
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --reload --port 8000
```

API docs: http://127.0.0.1:8000/docs

### Frontend

```bash
cd frontend
npm install
npm run dev
```

App: http://127.0.0.1:5173

## Demo accounts

Seeded automatically on first backend start:

| Email | Password | Role |
|-------|----------|------|
| admin@demo.com | password123 | Owner of City Care Clinic & Northstar Bank |
| staff@demo.com | password123 | Staff at City Care Clinic |
| customer@demo.com | password123 | Customer account |

Demo public queue: `/q/city-care/general-practice`

## Architecture

```
Organization (business)
  └── Memberships (owner / admin / staff)
  └── Queues
        └── Tickets (waiting → called → serving → completed)
```

Public customers join via `/q/{org-slug}/{queue-slug}` without needing staff login.
