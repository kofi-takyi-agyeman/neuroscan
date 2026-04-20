from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
import json
import os

from app.preprocess import preprocess_image, validate_image
from app.model import TFLiteModel

app = FastAPI(title="Brain Tumor API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_PATH  = "models/brain_tumor_model.tflite"
LABELS_PATH = "models/labels.json"

model = TFLiteModel(MODEL_PATH)

# Load labels.json saved during training
# flow_from_dataframe sorts labels alphabetically:
# index 0=glioma, 1=meningioma, 2=notumor, 3=pituitary
if os.path.exists(LABELS_PATH):
    with open(LABELS_PATH, "r") as f:
        CLASS_NAMES = json.load(f)
    print(f"[NeuroScan] Loaded labels.json: {CLASS_NAMES}")
else:
    CLASS_NAMES = ["glioma", "meningioma", "notumor", "pituitary"]
    print(f"[NeuroScan] labels.json missing, using default: {CLASS_NAMES}")

print(f"[NeuroScan] Index mapping: { {i: c for i, c in enumerate(CLASS_NAMES)} }")

@app.get("/")
def home():
    return {
        "message": "Brain Tumor API is running",
        "classes": CLASS_NAMES,
        "class_indices": {i: c for i, c in enumerate(CLASS_NAMES)},
    }

@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    try:
        file_bytes = await image.read()
        validate_image(file_bytes, image.content_type)
        processed_img = preprocess_image(file_bytes)
        predictions = model.predict(processed_img)

        # Always flatten — handles both (1,4) and (4,) output shapes
        flat_preds = np.array(predictions).flatten()

        predicted_index = int(np.argmax(flat_preds))
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = float(np.max(flat_preds))

        print(f"[NeuroScan] Raw output: {flat_preds.tolist()}")
        print(f"[NeuroScan] Predicted:  index={predicted_index} class={predicted_class} conf={confidence:.4f}")

        return {
            "class":             predicted_class,          # e.g. "notumor"
            "confidence":        round(confidence, 4),
            "all_probabilities": flat_preds.tolist(),      # flat [p0,p1,p2,p3]
        }

    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        print(f"[NeuroScan] ERROR: {e}")
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
