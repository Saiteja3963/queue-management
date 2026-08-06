from datetime import datetime, timezone

from sqlalchemy.orm import Session

from .models import Queue, Ticket, TicketStatus


def start_of_today() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def waiting_position(db: Session, ticket: Ticket) -> int | None:
    if ticket.status != TicketStatus.waiting:
        return None
    ahead = (
        db.query(Ticket)
        .filter(
            Ticket.queue_id == ticket.queue_id,
            Ticket.status == TicketStatus.waiting,
            Ticket.number < ticket.number,
        )
        .count()
    )
    return ahead + 1


def enrich_ticket(db: Session, ticket: Ticket, avg_service: int) -> dict:
    position = waiting_position(db, ticket)
    data = {
        "id": ticket.id,
        "queue_id": ticket.queue_id,
        "number": ticket.number,
        "display_code": ticket.display_code,
        "customer_name": ticket.customer_name,
        "customer_phone": ticket.customer_phone,
        "status": ticket.status,
        "created_at": ticket.created_at,
        "called_at": ticket.called_at,
        "started_at": ticket.started_at,
        "completed_at": ticket.completed_at,
        "notes": ticket.notes or "",
        "position": position,
        "estimated_wait_minutes": (position - 1) * avg_service if position else None,
    }
    return data


def enrich_queue(db: Session, queue: Queue) -> dict:
    today = start_of_today()
    waiting = (
        db.query(Ticket)
        .filter(Ticket.queue_id == queue.id, Ticket.status == TicketStatus.waiting)
        .count()
    )
    serving = (
        db.query(Ticket)
        .filter(
            Ticket.queue_id == queue.id,
            Ticket.status.in_([TicketStatus.called, TicketStatus.serving]),
        )
        .count()
    )
    completed_today = (
        db.query(Ticket)
        .filter(
            Ticket.queue_id == queue.id,
            Ticket.status == TicketStatus.completed,
            Ticket.completed_at >= today,
        )
        .count()
    )
    return {
        "id": queue.id,
        "organization_id": queue.organization_id,
        "name": queue.name,
        "slug": queue.slug,
        "description": queue.description or "",
        "is_active": queue.is_active,
        "is_open": queue.is_open,
        "ticket_prefix": queue.ticket_prefix,
        "next_number": queue.next_number,
        "avg_service_minutes": queue.avg_service_minutes,
        "created_at": queue.created_at,
        "waiting_count": waiting,
        "serving_count": serving,
        "completed_today": completed_today,
        "organization_name": queue.organization.name if queue.organization else None,
        "organization_slug": queue.organization.slug if queue.organization else None,
    }
