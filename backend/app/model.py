import numpy as np
import tensorflow as tf


class TFLiteModel:
    def __init__(self, model_path: str):
        try:
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
        except Exception as e:
            raise RuntimeError(f"Failed to load TFLite model from '{model_path}': {e}")

        self.interpreter.allocate_tensors()
        self.input_details  = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        self.input_shape    = tuple(self.input_details[0]["shape"])
        self.num_classes    = self.output_details[0]["shape"][-1]

        print(f"[NeuroScan] Model loaded ✓")
        print(f"[NeuroScan] Input  shape : {self.input_shape}")
        print(f"[NeuroScan] Output shape : {self.output_details[0]['shape']}")
        print(f"[NeuroScan] Classes      : {self.num_classes}")

    def predict(self, input_data: np.ndarray) -> np.ndarray:
        input_data = np.array(input_data, dtype=np.float32)
        if input_data.shape != self.input_shape:
            raise ValueError(
                f"Input shape mismatch: got {input_data.shape}, "
                f"model expects {self.input_shape}. "
                f"Fix IMG_SIZE in preprocess.py."
            )
        self.interpreter.set_tensor(self.input_details[0]["index"], input_data)
        self.interpreter.invoke()
        output = self.interpreter.get_tensor(self.output_details[0]["index"])
        return output[0]