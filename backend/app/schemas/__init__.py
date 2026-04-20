"""
Pydantic schemas — request bodies and response shapes.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, field_validator
from app.models_db.user import UserRole
from app.models_db.patient import Gender


# ═══════════════════════════════════════════
# AUTH
# ═══════════════════════════════════════════

class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: UserRole = UserRole.doctor

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters.")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    full_name: str
    email: str
    role: UserRole


class UserOut(BaseModel):
    id: int
    full_name: str
    email: str
    role: UserRole
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════
# PATIENTS
# ═══════════════════════════════════════════

class PatientCreate(BaseModel):
    full_name: str
    age: int
    gender: Gender
    phone: Optional[str] = None
    dob: Optional[str] = None      # "YYYY-MM-DD"
    notes: Optional[str] = None

    @field_validator("age")
    @classmethod
    def valid_age(cls, v: int) -> int:
        if not (0 < v < 130):
            raise ValueError("Age must be between 1 and 129.")
        return v


class PatientUpdate(BaseModel):
    full_name: Optional[str]  = None
    age: Optional[int]        = None
    gender: Optional[Gender]  = None
    phone: Optional[str]      = None
    dob: Optional[str]        = None
    notes: Optional[str]      = None


class ScanSummary(BaseModel):
    scan_uid: str
    predicted_class: str
    confidence: float
    is_tumor: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PatientOut(BaseModel):
    id: int
    patient_uid: str
    full_name: str
    age: int
    gender: Gender
    phone: Optional[str]
    dob: Optional[str]
    notes: Optional[str]
    doctor_id: int
    created_at: datetime
    updated_at: datetime
    scans: list[ScanSummary] = []

    model_config = {"from_attributes": True}


class PatientListOut(BaseModel):
    id: int
    patient_uid: str
    full_name: str
    age: int
    gender: Gender
    phone: Optional[str]
    total_scans: int
    last_diagnosis: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════
# SCANS
# ═══════════════════════════════════════════

class ScanOut(BaseModel):
    id: int
    scan_uid: str
    patient_id: int
    doctor_id: int
    predicted_class: str
    confidence: float
    is_tumor: bool
    probabilities: dict
    filename: Optional[str]
    model_input_size: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}