import numpy as np
import cv2
from PIL import Image
import io
from tensorflow.keras.applications.efficientnet import preprocess_input

IMG_SIZE = 380  

ALLOWED_CONTENT_TYPES = {
    "image/jpeg", "image/jpg", "image/png",
    "image/bmp", "image/tiff",
}

MAX_FILE_SIZE_BYTES = 20 * 1024 * 1024


def validate_image(file_bytes: bytes, content_type: str) -> None:
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError(
            f"Unsupported file type '{content_type}'. "
            f"Allowed: {', '.join(ALLOWED_CONTENT_TYPES)}"
        )

    if len(file_bytes) == 0:
        raise ValueError("Uploaded file is empty.")

    if len(file_bytes) > MAX_FILE_SIZE_BYTES:
        raise ValueError(
            f"File too large ({len(file_bytes)/1024/1024:.1f} MB). Max 20 MB."
        )


def preprocess_image(file_bytes: bytes) -> np.ndarray:
    np_arr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if img is None:
        try:
            pil_img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
            img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        except Exception:
            raise ValueError("Could not decode image.")

    # BGR → RGB
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    # Resize
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))

    # 🔥 EXACT SAME AS TRAINING
    img = preprocess_input(img)

    # Add batch dimension
    img = np.expand_dims(img, axis=0)

    # Debug
    print("Shape:", img.shape)
    print("Min:", img.min(), "Max:", img.max())

    return img