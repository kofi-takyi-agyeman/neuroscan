from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
import enum

from app.database import Base


class Gender(str, enum.Enum):
    male   = "male"
    female = "female"
    other  = "other"


class Patient(Base):
    __tablename__ = "patients"

    id          = Column(Integer, primary_key=True, index=True)
    patient_uid = Column(String(20), unique=True, index=True, nullable=False)
    full_name   = Column(String(120), nullable=False)
    age         = Column(Integer, nullable=False)
    gender      = Column(Enum(Gender), nullable=False)
    phone       = Column(String(30), nullable=True)
    dob         = Column(String(20), nullable=True)   # stored as ISO string
    notes       = Column(String(500), nullable=True)

    doctor_id   = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at  = Column(DateTime, default=datetime.utcnow)
    updated_at  = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    doctor      = relationship("User", back_populates="patients")
    scans       = relationship("ScanResult", back_populates="patient",
                               cascade="all, delete-orphan")