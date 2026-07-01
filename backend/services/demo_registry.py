import os
import json

class DemoRegistry:
    def __init__(self, config_path: str = None):
        if config_path is None:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            config_path = os.path.join(current_dir, "..", "config", "anomalies.json")
        self.config_path = config_path
        self._load_config()

    def _load_config(self):
        if not os.path.exists(self.config_path):
            raise FileNotFoundError(f"Configuration file not found: {self.config_path}")
        with open(self.config_path, "r", encoding="utf-8") as f:
            self.anomalies = json.load(f)

    def get_anomaly(self, key: str) -> dict:
        return self.anomalies.get(key)

    def get_all(self) -> dict:
        return self.anomalies
