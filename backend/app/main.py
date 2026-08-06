from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
import random

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .auth import hash_password
from .database import Base, SessionLocal, engine
from .models import Membership, Organization, Queue, Ticket, TicketStatus, User, UserRole
from .routers import auth, orgs, queues


def seed_demo_data(db: Session) -> None:
    if db.query(User).first():
        return

    admin = User(
        email="admin@demo.com",
        full_name="Demo Admin",
        hashed_password=hash_password("password123"),
    )
    staff = User(
        email="staff@demo.com",
        full_name="Demo Staff",
        hashed_password=hash_password("password123"),
    )
    customer = User(
        email="customer@demo.com",
        full_name="Demo Customer",
        hashed_password=hash_password("password123"),
    )
    db.add_all([admin, staff, customer])
    db.flush()

    clinic = Organization(
        name="City Care Clinic",
        slug="city-care",
        description="Multi-specialty outpatient clinic",
    )
    bank = Organization(
        name="Northstar Bank",
        slug="northstar-bank",
        description="Retail banking branch services",
    )
    db.add_all([clinic, bank])
    db.flush()

    db.add_all(
        [
            Membership(user_id=admin.id, organization_id=clinic.id, role=UserRole.owner),
            Membership(user_id=staff.id, organization_id=clinic.id, role=UserRole.staff),
            Membership(user_id=admin.id, organization_id=bank.id, role=UserRole.owner),
        ]
    )

    gp = Queue(
        organization_id=clinic.id,
        name="General Practice",
        slug="general-practice",
        description="Walk-in GP consultations",
        ticket_prefix="G",
        avg_service_minutes=8,
        next_number=1,
    )
    lab = Queue(
        organization_id=clinic.id,
        name="Lab Samples",
        slug="lab-samples",
        description="Blood and sample collection",
        ticket_prefix="L",
        avg_service_minutes=4,
        next_number=1,
    )
    teller = Queue(
        organization_id=bank.id,
        name="Teller Services",
        slug="teller",
        description="Cash deposits, withdrawals, and inquiries",
        ticket_prefix="T",
        avg_service_minutes=6,
        next_number=1,
    )
    db.add_all([gp, lab, teller])
    db.flush()

    now = datetime.now(timezone.utc)
    names = [
        "Ava Chen",
        "Noah Patel",
        "Mia Santos",
        "Liam Brooks",
        "Zoe Nguyen",
        "Owen Kim",
        "Isla Reed",
        "Ethan Cole",
        "Chloe Diaz",
        "Lucas Park",
        "Hannah Lee",
        "Mason Ali",
    ]

    def add_ticket(queue: Queue, name: str, status: TicketStatus, minutes_ago: int):
        number = queue.next_number
        queue.next_number += 1
        created = now - timedelta(minutes=minutes_ago)
        called = created + timedelta(minutes=random.randint(3, 12)) if status != TicketStatus.waiting else None
        started = (
            called + timedelta(minutes=1)
            if called and status in (TicketStatus.serving, TicketStatus.completed)
            else None
        )
        completed = (
            started + timedelta(minutes=random.randint(3, 10))
            if started and status == TicketStatus.completed
            else (called + timedelta(minutes=2) if status == TicketStatus.skipped else None)
        )
        ticket = Ticket(
            queue_id=queue.id,
            number=number,
            display_code=f"{queue.ticket_prefix}{number:03d}",
            customer_name=name,
            customer_phone=f"555-{1000 + number}",
            status=status,
            created_at=created,
            called_at=called,
            started_at=started,
            completed_at=completed,
        )
        db.add(ticket)

    # GP queue history + live state
    for i, name in enumerate(names[:6]):
        add_ticket(gp, name, TicketStatus.completed, minutes_ago=120 - i * 15)
    add_ticket(gp, names[6], TicketStatus.serving, minutes_ago=18)
    add_ticket(gp, names[7], TicketStatus.called, minutes_ago=12)
    add_ticket(gp, names[8], TicketStatus.waiting, minutes_ago=10)
    add_ticket(gp, names[9], TicketStatus.waiting, minutes_ago=7)
    add_ticket(gp, names[10], TicketStatus.waiting, minutes_ago=4)
    add_ticket(gp, names[11], TicketStatus.skipped, minutes_ago=40)

    for i, name in enumerate(names[:4]):
        add_ticket(lab, name, TicketStatus.completed, minutes_ago=90 - i * 12)
    add_ticket(lab, names[4], TicketStatus.waiting, minutes_ago=8)
    add_ticket(lab, names[5], TicketStatus.waiting, minutes_ago=3)

    for i, name in enumerate(names[:5]):
        add_ticket(teller, name, TicketStatus.completed, minutes_ago=100 - i * 14)
    add_ticket(teller, names[5], TicketStatus.serving, minutes_ago=9)
    add_ticket(teller, names[6], TicketStatus.waiting, minutes_ago=6)
    add_ticket(teller, names[7], TicketStatus.waiting, minutes_ago=2)

    db.commit()


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_demo_data(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title="Queue Management API",
    description="Multi-tenant queue management for businesses and systems",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(orgs.router)
app.include_router(queues.router)


@app.get("/api/health")
def health():
    return {"status": "ok"}
