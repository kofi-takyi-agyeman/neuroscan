"""
Run this directly in your Brain_Tumor_Backend folder:
  cd D:\tuumor\Brain_Tumor_Backend
  venv\Scripts\activate
  python test_model.py
"""
import numpy as np
import json
import os

# ── Load labels ───────────────────────────────────────────────
with open("models/labels.json") as f:
    CLASS_NAMES = json.load(f)
print(f"CLASS_NAMES from labels.json: {CLASS_NAMES}")
print(f"Index mapping: { {i:c for i,c in enumerate(CLASS_NAMES)} }")

# ── Load TFLite model ─────────────────────────────────────────
import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path="models/brain_tumor_model.tflite")
interpreter.allocate_tensors()
input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print(f"\nInput  shape: {input_details[0]['shape']}")
print(f"Output shape: {output_details[0]['shape']}")
print(f"Input  dtype: {input_details[0]['dtype']}")

# ── Test with a PURE BLACK image (should predict notumor or be uncertain) ──
black = np.zeros((1, 380, 380, 3), dtype=np.float32)
interpreter.set_tensor(input_details[0]['index'], black)
interpreter.invoke()
out = interpreter.get_tensor(output_details[0]['index'])
flat = out.flatten()
print(f"\n--- Black image test ---")
print(f"Raw output: {flat}")
print(f"Predicted:  {CLASS_NAMES[np.argmax(flat)]} (index {np.argmax(flat)})")

# ── Test with a PURE WHITE image ──────────────────────────────
white = np.ones((1, 380, 380, 3), dtype=np.float32) * 255.0
interpreter.set_tensor(input_details[0]['index'], white)
interpreter.invoke()
out2 = interpreter.get_tensor(output_details[0]['index'])
flat2 = out2.flatten()
print(f"\n--- White image test ---")
print(f"Raw output: {flat2}")
print(f"Predicted:  {CLASS_NAMES[np.argmax(flat2)]} (index {np.argmax(flat2)})")

# ── Test with RANDOM NOISE image ─────────────────────────────
np.random.seed(42)
noise = np.random.uniform(0, 255, (1, 380, 380, 3)).astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], noise)
interpreter.invoke()
out3 = interpreter.get_tensor(output_details[0]['index'])
flat3 = out3.flatten()
print(f"\n--- Random noise test ---")
print(f"Raw output: {flat3}")
print(f"Predicted:  {CLASS_NAMES[np.argmax(flat3)]} (index {np.argmax(flat3)})")

# ── Check if model is stuck on glioma for everything ─────────
print(f"\n--- Diagnosis ---")
if np.argmax(flat) == 0 and np.argmax(flat2) == 0 and np.argmax(flat3) == 0:
    print("❌ MODEL IS BROKEN — predicts glioma (index 0) for everything")
    print("   Possible causes:")
    print("   1. Model was not properly converted to TFLite")
    print("   2. Wrong model file is loaded")
    print("   3. Preprocessing mismatch (model expects EfficientNetB4 preprocess_input)")
else:
    print("✅ Model gives different predictions — preprocessing may be the issue")
    print("   Check that preprocess_image() uses EfficientNetB4 preprocess_input")

