from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from .. import schemas
from ..auth import get_current_user, get_membership, require_org_role
from ..database import get_db
from ..models import Organization, Queue, Ticket, TicketStatus, User, UserRole
from ..services import enrich_queue, enrich_ticket, start_of_today

router = APIRouter(prefix="/api", tags=["queues"])


@router.post(
    "/organizations/{org_id}/queues",
    response_model=schemas.QueueOut,
    status_code=status.HTTP_201_CREATED,
)
def create_queue(
    org_id: int,
    payload: schemas.QueueCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_org_role(db, current_user, org_id, {UserRole.owner, UserRole.admin})
    org = db.query(Organization).filter(Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    existing = (
        db.query(Queue)
        .filter(Queue.organization_id == org_id, Queue.slug == payload.slug)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Queue slug already exists in this organization")
    queue = Queue(
        organization_id=org_id,
        name=payload.name,
        slug=payload.slug,
        description=payload.description or "",
        ticket_prefix=payload.ticket_prefix or "A",
        avg_service_minutes=payload.avg_service_minutes,
    )
    db.add(queue)
    db.commit()
    db.refresh(queue)
    queue = (
        db.query(Queue)
        .options(joinedload(Queue.organization))
        .filter(Queue.id == queue.id)
        .first()
    )
    return enrich_queue(db, queue)


@router.get("/organizations/{org_id}/queues", response_model=list[schemas.QueueOut])
def list_org_queues(
    org_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not get_membership(db, current_user.id, org_id):
        raise HTTPException(status_code=403, detail="Not a member of this organization")
    queues = (
        db.query(Queue)
        .options(joinedload(Queue.organization))
        .filter(Queue.organization_id == org_id)
        .order_by(Queue.created_at.desc())
        .all()
    )
    return [enrich_queue(db, q) for q in queues]


@router.get("/queues/{queue_id}", response_model=schemas.QueueOut)
def get_queue(queue_id: int, db: Session = Depends(get_db)):
    queue = (
        db.query(Queue)
        .options(joinedload(Queue.organization))
        .filter(Queue.id == queue_id)
        .first()
    )
    if not queue or not queue.is_active:
        raise HTTPException(status_code=404, detail="Queue not found")
    return enrich_queue(db, queue)


@router.get("/public/{org_slug}/{queue_slug}", response_model=schemas.QueueOut)
def get_public_queue(org_slug: str, queue_slug: str, db: Session = Depends(get_db)):
    org = db.query(Organization).filter(Organization.slug == org_slug).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    queue = (
        db.query(Queue)
        .options(joinedload(Queue.organization))
        .filter(
            Queue.organization_id == org.id,
            Queue.slug == queue_slug,
            Queue.is_active == True,  # noqa: E712
        )
        .first()
    )
    if not queue:
        raise HTTPException(status_code=404, detail="Queue not found")
    return enrich_queue(db, queue)


@router.patch("/queues/{queue_id}", response_model=schemas.QueueOut)
def update_queue(
    queue_id: int,
    payload: schemas.QueueUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    queue = (
        db.query(Queue)
        .options(joinedload(Queue.organization))
        .filter(Queue.id == queue_id)
        .first()
    )
    if not queue:
        raise HTTPException(status_code=404, detail="Queue not found")
    require_org_role(
        db, current_user, queue.organization_id, {UserRole.owner, UserRole.admin, UserRole.staff}
    )
    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(queue, key, value)
    db.commit()
    db.refresh(queue)
    return enrich_queue(db, queue)


@router.get("/queues/{queue_id}/tickets", response_model=list[schemas.TicketOut])
def list_tickets(
    queue_id: int,
    status_filter: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    queue = db.query(Queue).filter(Queue.id == queue_id).first()
    if not queue:
        raise HTTPException(status_code=404, detail="Queue not found")
    require_org_role(
        db, current_user, queue.organization_id, {UserRole.owner, UserRole.admin, UserRole.staff}
    )
    query = db.query(Ticket).filter(Ticket.queue_id == queue_id)
    if status_filter:
        try:
            statuses = [TicketStatus(s.strip()) for s in status_filter.split(",")]
            query = query.filter(Ticket.status.in_(statuses))
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="Invalid status filter") from exc
    tickets = query.order_by(Ticket.number.asc()).all()
    return [enrich_ticket(db, t, queue.avg_service_minutes) for t in tickets]


@router.post(
    "/public/{org_slug}/{queue_slug}/join",
    response_model=schemas.TicketOut,
    status_code=status.HTTP_201_CREATED,
)
def join_queue(
    org_slug: str,
    queue_slug: str,
    payload: schemas.TicketJoin,
    db: Session = Depends(get_db),
):
    org = db.query(Organization).filter(Organization.slug == org_slug).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    queue = (
        db.query(Queue)
        .filter(
            Queue.organization_id == org.id,
            Queue.slug == queue_slug,
            Queue.is_active == True,  # noqa: E712
        )
        .first()
    )
    if not queue:
        raise HTTPException(status_code=404, detail="Queue not found")
    if not queue.is_open:
        raise HTTPException(status_code=400, detail="Queue is currently closed")

    number = queue.next_number
    queue.next_number += 1
    ticket = Ticket(
        queue_id=queue.id,
        number=number,
        display_code=f"{queue.ticket_prefix}{number:03d}",
        customer_name=payload.customer_name,
        customer_phone=payload.customer_phone or "",
        status=TicketStatus.waiting,
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return enrich_ticket(db, ticket, queue.avg_service_minutes)


@router.get("/tickets/{ticket_id}", response_model=schemas.TicketOut)
def get_ticket(ticket_id: int, db: Session = Depends(get_db)):
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    queue = db.query(Queue).filter(Queue.id == ticket.queue_id).first()
    return enrich_ticket(db, ticket, queue.avg_service_minutes if queue else 5)


@router.post("/queues/{queue_id}/call-next", response_model=schemas.TicketOut)
def call_next(
    queue_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from datetime import datetime, timezone

    queue = db.query(Queue).filter(Queue.id == queue_id).first()
    if not queue:
        raise HTTPException(status_code=404, detail="Queue not found")
    require_org_role(
        db, current_user, queue.organization_id, {UserRole.owner, UserRole.admin, UserRole.staff}
    )
    ticket = (
        db.query(Ticket)
        .filter(Ticket.queue_id == queue_id, Ticket.status == TicketStatus.waiting)
        .order_by(Ticket.number.asc())
        .first()
    )
    if not ticket:
        raise HTTPException(status_code=404, detail="No waiting tickets")
    now = datetime.now(timezone.utc)
    ticket.status = TicketStatus.called
    ticket.called_at = now
    db.commit()
    db.refresh(ticket)
    return enrich_ticket(db, ticket, queue.avg_service_minutes)


@router.patch("/tickets/{ticket_id}/status", response_model=schemas.TicketOut)
def update_ticket_status(
    ticket_id: int,
    payload: schemas.TicketStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from datetime import datetime, timezone

    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    queue = db.query(Queue).filter(Queue.id == ticket.queue_id).first()
    require_org_role(
        db, current_user, queue.organization_id, {UserRole.owner, UserRole.admin, UserRole.staff}
    )
    now = datetime.now(timezone.utc)
    ticket.status = payload.status
    if payload.notes:
        ticket.notes = payload.notes
    if payload.status == TicketStatus.called and not ticket.called_at:
        ticket.called_at = now
    elif payload.status == TicketStatus.serving:
        if not ticket.called_at:
            ticket.called_at = now
        ticket.started_at = now
    elif payload.status in (TicketStatus.completed, TicketStatus.skipped, TicketStatus.cancelled):
        ticket.completed_at = now
        if payload.status == TicketStatus.completed and not ticket.started_at:
            ticket.started_at = ticket.called_at or now
    db.commit()
    db.refresh(ticket)
    return enrich_ticket(db, ticket, queue.avg_service_minutes)


@router.get("/queues/{queue_id}/insights", response_model=schemas.DashboardStats)
def queue_insights(
    queue_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from datetime import datetime, timezone

    queue = db.query(Queue).filter(Queue.id == queue_id).first()
    if not queue:
        raise HTTPException(status_code=404, detail="Queue not found")
    require_org_role(
        db, current_user, queue.organization_id, {UserRole.owner, UserRole.admin, UserRole.staff}
    )

    today = start_of_today()
    tickets_today = (
        db.query(Ticket)
        .filter(Ticket.queue_id == queue_id, Ticket.created_at >= today)
        .all()
    )
    all_active = (
        db.query(Ticket)
        .filter(
            Ticket.queue_id == queue_id,
            Ticket.status.in_(
                [TicketStatus.waiting, TicketStatus.called, TicketStatus.serving]
            ),
        )
        .all()
    )

    waiting = [t for t in all_active if t.status == TicketStatus.waiting]
    called = [t for t in all_active if t.status == TicketStatus.called]
    serving = [t for t in all_active if t.status == TicketStatus.serving]
    completed = [t for t in tickets_today if t.status == TicketStatus.completed]
    skipped = [t for t in tickets_today if t.status == TicketStatus.skipped]
    cancelled = [t for t in tickets_today if t.status == TicketStatus.cancelled]

    wait_samples = []
    service_samples = []
    for t in completed:
        if t.called_at and t.created_at:
            wait_samples.append((t.called_at - t.created_at).total_seconds() / 60)
        if t.completed_at and t.started_at:
            service_samples.append((t.completed_at - t.started_at).total_seconds() / 60)
        elif t.completed_at and t.called_at:
            service_samples.append((t.completed_at - t.called_at).total_seconds() / 60)

    avg_wait = sum(wait_samples) / len(wait_samples) if wait_samples else 0.0
    avg_service = (
        sum(service_samples) / len(service_samples)
        if service_samples
        else float(queue.avg_service_minutes)
    )

    hourly = {h: 0 for h in range(24)}
    peak_hour = None
    for t in completed:
        if t.completed_at:
            h = t.completed_at.hour
            hourly[h] += 1
    if any(hourly.values()):
        peak_hour = max(hourly, key=hourly.get)

    now = datetime.now(timezone.utc)
    hours_open = max((now - today).total_seconds() / 3600, 0.25)
    throughput = len(completed) / hours_open

    recent = (
        db.query(Ticket)
        .filter(Ticket.queue_id == queue_id)
        .order_by(Ticket.created_at.desc())
        .limit(12)
        .all()
    )

    status_breakdown = {
        "waiting": len(waiting),
        "called": len(called),
        "serving": len(serving),
        "completed_today": len(completed),
        "skipped_today": len(skipped),
        "cancelled_today": len(cancelled),
    }

    return {
        "queue_id": queue.id,
        "queue_name": queue.name,
        "currently_waiting": len(waiting),
        "currently_serving": len(serving),
        "currently_called": len(called),
        "completed_today": len(completed),
        "skipped_today": len(skipped),
        "cancelled_today": len(cancelled),
        "avg_wait_minutes": round(avg_wait, 1),
        "avg_service_minutes": round(avg_service, 1),
        "peak_hour": peak_hour,
        "throughput_per_hour": round(throughput, 2),
        "estimated_wait_for_new": len(waiting) * queue.avg_service_minutes,
        "recent_tickets": [enrich_ticket(db, t, queue.avg_service_minutes) for t in recent],
        "hourly_completed": [{"hour": h, "count": hourly[h]} for h in range(24)],
        "status_breakdown": status_breakdown,
    }
