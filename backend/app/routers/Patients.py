import random
import string
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models_db import User, Patient
from app.schemas import PatientCreate, PatientUpdate, PatientOut, PatientListOut, ScanSummary
from app.auth import require_doctor

router = APIRouter(prefix="/patients", tags=["Patients"])


# ── Helpers ───────────────────────────────────────────────────

def _generate_uid(db: Session) -> str:
    """Generate a unique patient UID like P-00284."""
    while True:
        uid = "P-" + "".join(random.choices(string.digits, k=5))
        if not db.query(Patient).filter(Patient.patient_uid == uid).first():
            return uid


def _own_patient_or_404(patient_id: int, doctor: User, db: Session) -> Patient:
    """Return patient if it belongs to this doctor, else 404."""
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == doctor.id,
    ).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Patient {patient_id} not found.",
        )
    return patient


# ── Routes ────────────────────────────────────────────────────

@router.post("/", response_model=PatientOut, status_code=status.HTTP_201_CREATED)
def create_patient(
    body: PatientCreate,
    db: Session = Depends(get_db),
    doctor: User = Depends(require_doctor),
):
    """Create a new patient record (doctors only)."""
    patient = Patient(
        patient_uid=_generate_uid(db),
        doctor_id=doctor.id,
        **body.model_dump(),
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


@router.get("/", response_model=list[PatientOut])
def list_patients(
    search: Optional[str] = Query(None, description="Search by name or patient UID"),
    skip: int  = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    doctor: User = Depends(require_doctor),
):
    """
    List all patients belonging to the logged-in doctor.
    Optionally filter by name or patient UID.
    """
    q = db.query(Patient).filter(Patient.doctor_id == doctor.id)

    if search:
        term = f"%{search.lower()}%"
        q = q.filter(
            Patient.full_name.ilike(term) |
            Patient.patient_uid.ilike(term)
        )

    return q.order_by(Patient.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/{patient_id}", response_model=PatientOut)
def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    doctor: User = Depends(require_doctor),
):
    """Get a single patient with full scan history."""
    return _own_patient_or_404(patient_id, doctor, db)


@router.put("/{patient_id}", response_model=PatientOut)
def update_patient(
    patient_id: int,
    body: PatientUpdate,
    db: Session = Depends(get_db),
    doctor: User = Depends(require_doctor),
):
    """Update patient details (partial update — only send fields you want to change)."""
    patient = _own_patient_or_404(patient_id, doctor, db)

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(patient, field, value)

    db.commit()
    db.refresh(patient)
    return patient


@router.delete("/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    doctor: User = Depends(require_doctor),
):
    """
    Delete a patient and all their scan records (cascade).
    This action is irreversible.
    """
    patient = _own_patient_or_404(patient_id, doctor, db)
    db.delete(patient)
    db.commit()