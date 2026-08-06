from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, EmailStr, Field

from .models import TicketStatus, UserRole


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserCreate(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=120)
    password: str = Field(min_length=6, max_length=100)


class UserOut(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    is_active: bool

    class Config:
        from_attributes = True


class OrganizationCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    slug: str = Field(min_length=2, max_length=80, pattern=r"^[a-z0-9-]+$")
    description: str = ""


class OrganizationOut(BaseModel):
    id: int
    name: str
    slug: str
    description: str
    created_at: datetime

    class Config:
        from_attributes = True


class MembershipOut(BaseModel):
    id: int
    role: UserRole
    organization: OrganizationOut

    class Config:
        from_attributes = True


class QueueCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    slug: str = Field(min_length=2, max_length=80, pattern=r"^[a-z0-9-]+$")
    description: str = ""
    ticket_prefix: str = Field(default="A", max_length=10)
    avg_service_minutes: int = Field(default=5, ge=1, le=180)


class QueueUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=120)
    description: Optional[str] = None
    is_active: Optional[bool] = None
    is_open: Optional[bool] = None
    ticket_prefix: Optional[str] = Field(default=None, max_length=10)
    avg_service_minutes: Optional[int] = Field(default=None, ge=1, le=180)


class QueueOut(BaseModel):
    id: int
    organization_id: int
    name: str
    slug: str
    description: str
    is_active: bool
    is_open: bool
    ticket_prefix: str
    next_number: int
    avg_service_minutes: int
    created_at: datetime
    waiting_count: int = 0
    serving_count: int = 0
    completed_today: int = 0
    organization_name: Optional[str] = None
    organization_slug: Optional[str] = None

    class Config:
        from_attributes = True


class TicketJoin(BaseModel):
    customer_name: str = Field(min_length=2, max_length=120)
    customer_phone: str = ""


class TicketOut(BaseModel):
    id: int
    queue_id: int
    number: int
    display_code: str
    customer_name: str
    customer_phone: str
    status: TicketStatus
    created_at: datetime
    called_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    notes: str = ""
    position: Optional[int] = None
    estimated_wait_minutes: Optional[int] = None

    class Config:
        from_attributes = True


class TicketStatusUpdate(BaseModel):
    status: TicketStatus
    notes: str = ""


class DashboardStats(BaseModel):
    queue_id: int
    queue_name: str
    currently_waiting: int
    currently_serving: int
    currently_called: int
    completed_today: int
    skipped_today: int
    cancelled_today: int
    avg_wait_minutes: float
    avg_service_minutes: float
    peak_hour: Optional[int] = None
    throughput_per_hour: float
    estimated_wait_for_new: int
    recent_tickets: List[TicketOut]
    hourly_completed: List[dict]
    status_breakdown: dict
