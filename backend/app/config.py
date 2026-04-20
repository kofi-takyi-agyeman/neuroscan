"""
Central configuration.
Values are read from environment variables (or .env file locally).
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    # ── App ──────────────────────────────────────────────────
    APP_NAME: str    = "NeuroScan AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool      = os.getenv("DEBUG", "false").lower() == "true"

    # ── Database ─────────────────────────────────────────────
    # Locally: SQLite  →  sqlite:///./neuroscan.db
    # Render:  Render injects DATABASE_URL automatically (PostgreSQL)
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite:///./neuroscan.db"
    )
    # SQLAlchemy requires "postgresql://" not "postgres://"
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

    # ── JWT ──────────────────────────────────────────────────
    SECRET_KEY: str       = os.getenv("SECRET_KEY", "CHANGE_ME_IN_PRODUCTION_use_openssl_rand")
    ALGORITHM: str        = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

    # ── ML Model ─────────────────────────────────────────────
    MODEL_PATH:  str = os.getenv("MODEL_PATH",  "models/brain_tumor_model.tflite")
    LABELS_PATH: str = os.getenv("LABELS_PATH", "models/labels.json")

    # ── CORS ─────────────────────────────────────────────────
    # Comma-separated list of allowed origins.
    # Set to "*" during development; restrict in production.
    ALLOWED_ORIGINS: list[str] = os.getenv("ALLOWED_ORIGINS", "*").split(",")


settings = Settings()