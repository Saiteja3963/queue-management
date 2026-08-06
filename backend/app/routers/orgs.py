from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import schemas
from ..auth import get_current_user, get_membership, require_org_role
from ..database import get_db
from ..models import Membership, Organization, User, UserRole

router = APIRouter(prefix="/api/organizations", tags=["organizations"])


@router.post("", response_model=schemas.OrganizationOut, status_code=status.HTTP_201_CREATED)
def create_organization(
    payload: schemas.OrganizationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    existing = db.query(Organization).filter(Organization.slug == payload.slug).first()
    if existing:
        raise HTTPException(status_code=400, detail="Organization slug already taken")
    org = Organization(
        name=payload.name,
        slug=payload.slug,
        description=payload.description or "",
    )
    db.add(org)
    db.flush()
    membership = Membership(
        user_id=current_user.id,
        organization_id=org.id,
        role=UserRole.owner,
    )
    db.add(membership)
    db.commit()
    db.refresh(org)
    return org


@router.get("", response_model=list[schemas.MembershipOut])
def list_my_organizations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    memberships = (
        db.query(Membership)
        .filter(Membership.user_id == current_user.id)
        .order_by(Membership.id.desc())
        .all()
    )
    return memberships


@router.get("/{org_id}", response_model=schemas.OrganizationOut)
def get_organization(
    org_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    org = db.query(Organization).filter(Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    if not get_membership(db, current_user.id, org_id):
        raise HTTPException(status_code=403, detail="Not a member of this organization")
    return org


@router.get("/by-slug/{slug}", response_model=schemas.OrganizationOut)
def get_organization_by_slug(slug: str, db: Session = Depends(get_db)):
    org = db.query(Organization).filter(Organization.slug == slug).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    return org


@router.post("/{org_id}/members", status_code=status.HTTP_201_CREATED)
def add_member(
    org_id: int,
    email: str,
    role: UserRole = UserRole.staff,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_org_role(db, current_user, org_id, {UserRole.owner, UserRole.admin})
    user = db.query(User).filter(User.email == email.lower()).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if get_membership(db, user.id, org_id):
        raise HTTPException(status_code=400, detail="User already a member")
    if role == UserRole.owner:
        raise HTTPException(status_code=400, detail="Cannot assign owner role")
    membership = Membership(user_id=user.id, organization_id=org_id, role=role)
    db.add(membership)
    db.commit()
    return {"ok": True, "user_id": user.id, "role": role}
