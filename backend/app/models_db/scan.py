from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship

from app.database import Base


class ScanResult(Base):
    __tablename__ = "scan_results"

    id               = Column(Integer, primary_key=True, index=True)
    scan_uid         = Column(String(20), unique=True, index=True, nullable=False)

    # Foreign keys
    patient_id       = Column(Integer, ForeignKey("patients.id"), nullable=False)
    doctor_id        = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Inference results
    predicted_class  = Column(String(50), nullable=False)
    confidence       = Column(Float, nullable=False)
    is_tumor         = Column(Boolean, nullable=False)
    probabilities    = Column(JSON, nullable=False)   # {"glioma": 0.94, ...}

    # Image metadata
    filename         = Column(String(255), nullable=True)
    model_input_size = Column(String(20), nullable=True)   # "380x380"

    # Timestamps
    created_at       = Column(DateTime, default=datetime.utcnow)

    # Relationships
    patient          = relationship("Patient", back_populates="scans")
    doctor           = relationship("User", back_populates="scans")