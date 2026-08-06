import enum
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from .database import Base


def utcnow():
    return datetime.now(timezone.utc)


class UserRole(str, enum.Enum):
    owner = "owner"
    admin = "admin"
    staff = "staff"
    customer = "customer"


class TicketStatus(str, enum.Enum):
    waiting = "waiting"
    called = "called"
    serving = "serving"
    completed = "completed"
    skipped = "skipped"
    cancelled = "cancelled"


class Organization(Base):
    __tablename__ = "organizations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False)
    slug = Column(String(80), unique=True, nullable=False, index=True)
    description = Column(Text, default="")
    created_at = Column(DateTime, default=utcnow)

    memberships = relationship("Membership", back_populates="organization", cascade="all, delete-orphan")
    queues = relationship("Queue", back_populates="organization", cascade="all, delete-orphan")


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    full_name = Column(String(120), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utcnow)

    memberships = relationship("Membership", back_populates="user", cascade="all, delete-orphan")
    tickets = relationship("Ticket", back_populates="customer")


class Membership(Base):
    __tablename__ = "memberships"
    __table_args__ = (UniqueConstraint("user_id", "organization_id", name="uq_user_org"),)

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.staff)
    created_at = Column(DateTime, default=utcnow)

    user = relationship("User", back_populates="memberships")
    organization = relationship("Organization", back_populates="memberships")


class Queue(Base):
    __tablename__ = "queues"
    __table_args__ = (UniqueConstraint("organization_id", "slug", name="uq_org_queue_slug"),)

    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False)
    name = Column(String(120), nullable=False)
    slug = Column(String(80), nullable=False, index=True)
    description = Column(Text, default="")
    is_active = Column(Boolean, default=True)
    is_open = Column(Boolean, default=True)
    ticket_prefix = Column(String(10), default="A")
    next_number = Column(Integer, default=1)
    avg_service_minutes = Column(Integer, default=5)
    created_at = Column(DateTime, default=utcnow)

    organization = relationship("Organization", back_populates="queues")
    tickets = relationship("Ticket", back_populates="queue", cascade="all, delete-orphan")


class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(Integer, primary_key=True, index=True)
    queue_id = Column(Integer, ForeignKey("queues.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    number = Column(Integer, nullable=False)
    display_code = Column(String(20), nullable=False)
    customer_name = Column(String(120), nullable=False)
    customer_phone = Column(String(40), default="")
    status = Column(Enum(TicketStatus), default=TicketStatus.waiting, nullable=False)
    created_at = Column(DateTime, default=utcnow)
    called_at = Column(DateTime, nullable=True)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    notes = Column(Text, default="")

    queue = relationship("Queue", back_populates="tickets")
    customer = relationship("User", back_populates="tickets")
