"""
Prediction and scan history endpoints.
"""
import random
import string
import traceback
from typing import Optional

import numpy as np
from fastapi import APIRouter, Depends, File, HTTPException, Query, Request, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models_db import User, Patient, ScanResult
from app.schemas import ScanOut
from app.auth import get_current_user
from app.preprocess import preprocess_image, validate_image

router = APIRouter(tags=["Inference & Scan History"])


def _uid(db: Session) -> str:
    while True:
        uid = "SCN-" + "".join(random.choices(string.digits, k=4))
        if not db.query(ScanResult).filter(ScanResult.scan_uid == uid).first():
            return uid


def _build_probs(raw: np.ndarray, labels: dict) -> dict:
    return {labels[i]: round(float(raw[i]), 6) for i in range(len(raw)) if i in labels}


@router.post("/predict", response_model=ScanOut)
async def predict(
    request: Request,
    file: UploadFile = File(...),
    patient_id: Optional[int] = Query(None, description="Link scan to a patient"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Classify a brain MRI scan and save the result to history."""
    model  = request.app.state.model
    labels = request.app.state.labels

    if model is None or not labels:
        raise HTTPException(status_code=503, detail="Model not ready.")

    try:
        file_bytes = await file.read()
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read uploaded file.")

    try:
        validate_image(file_bytes, file.content_type or "")
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    try:
        img = preprocess_image(file_bytes)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except Exception:
        raise HTTPException(status_code=500, detail="Image preprocessing failed.")

    try:
        raw_output = model.predict(img)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except Exception:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail="Model inference failed.")

    class_index     = int(np.argmax(raw_output))
    confidence      = float(np.max(raw_output))
    predicted_class = labels.get(class_index, f"class_{class_index}")
    probabilities   = _build_probs(raw_output, labels)
    is_tumor        = predicted_class.lower() not in ("no_tumor", "no tumor")

    linked_patient_id = None
    if patient_id is not None:
        patient = db.query(Patient).filter(
            Patient.id == patient_id,
            Patient.doctor_id == current_user.id,
        ).first()
        if not patient:
            raise HTTPException(status_code=404, detail=f"Patient {patient_id} not found.")
        linked_patient_id = patient.id

    scan = ScanResult(
        scan_uid         = _uid(db),
        patient_id       = linked_patient_id,
        doctor_id        = current_user.id,
        predicted_class  = predicted_class,
        confidence       = confidence,
        is_tumor         = is_tumor,
        probabilities    = probabilities,
        filename         = file.filename,
        model_input_size = f"{img.shape[1]}x{img.shape[2]}",
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)
    return scan


@router.get("/scans", response_model=list[ScanOut])
def list_scans(
    patient_id: Optional[int] = Query(None),
    skip:  int = Query(0,  ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List scan history for the logged-in doctor, newest first."""
    q = db.query(ScanResult).filter(ScanResult.doctor_id == current_user.id)
    if patient_id is not None:
        q = q.filter(ScanResult.patient_id == patient_id)
    return q.order_by(ScanResult.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/scans/{scan_id}", response_model=ScanOut)
def get_scan(
    scan_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single scan result."""
    scan = db.query(ScanResult).filter(
        ScanResult.id == scan_id,
        ScanResult.doctor_id == current_user.id,
    ).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found.")
    return scan


@router.delete("/scans/{scan_id}", status_code=204)
def delete_scan(
    scan_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a scan record."""
    scan = db.query(ScanResult).filter(
        ScanResult.id == scan_id,
        ScanResult.doctor_id == current_user.id,
    ).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found.")
    db.delete(scan)
    db.commit()