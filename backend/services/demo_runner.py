from database import get_conn
from services.demo_registry import DemoRegistry

class DemoRunner:
    def __init__(self, registry: DemoRegistry):
        self.registry = registry

    def reset(self, key: str):
        anomaly = self.registry.get_anomaly(key)
        if not anomaly:
            raise ValueError(f"Anomaly key '{key}' not found in registry.")
        
        proc = anomaly["procedures"]["reset"]
        conn = get_conn()
        cursor = conn.cursor()
        try:
            cursor.execute(f"EXEC {proc}")
            conn.commit()
        finally:
            cursor.close()
            conn.close()

    def run(self, key: str, type: str):
        anomaly = self.registry.get_anomaly(key)
        if not anomaly:
            raise ValueError(f"Anomaly key '{key}' not found in registry.")
        
        if type not in ("bad", "fix"):
            raise ValueError(f"Invalid run type '{type}'. Must be 'bad' or 'fix'.")
        
        if key in ("phantom", "register", "statuslock"):
            import urllib.request
            import json
            
            url = "http://host.docker.internal:9000/run"
            payload = {"demo": key, "mode": type}
            headers = {"Content-Type": "application/json"}
            data = json.dumps(payload).encode("utf-8")
            
            print(f"[DemoRunner] Delegating {key} Playwright execution to Demo Agent at {url}...")
            req = urllib.request.Request(url, data=data, headers=headers, method="POST")
            
            try:
                with urllib.request.urlopen(req, timeout=60) as response:
                    res_body = response.read().decode("utf-8")
                    print(f"[DemoRunner] Demo Agent responded: {res_body}")
            except Exception as e:
                print(f"[DemoRunner] Failed to communicate with Demo Agent for {key}: {e}")
                # For register and statuslock we might want to just skip browser or raise.
                # For phantom we raised. Let's raise for consistency if agent is down.
                if key == "phantom":
                    raise RuntimeError(f"Communication with Demo Agent failed: {e}")
            return
            
        # Các demo khác nếu còn sẽ chạy SP trực tiếp
        proc = anomaly["procedures"][type]
        conn = get_conn()
        cursor = conn.cursor()
        try:
            cursor.execute(f"EXEC {proc}")
            conn.commit()
        finally:
            cursor.close()
            conn.close()



    def logs(self, key: str):
        anomaly = self.registry.get_anomaly(key)
        if not anomaly:
            raise ValueError(f"Anomaly key '{key}' not found in registry.")
        
        proc = anomaly["procedures"]["logs"]
        conn = get_conn()
        cursor = conn.cursor()
        try:
            # We filter by Scenario (e.g. 'PHANTOM')
            scenario_name = key.upper()
            cursor.execute(f"EXEC {proc} @Scenario = ?", scenario_name)
            
            # Dynamically retrieve column names from the cursor description
            columns = [column[0] for column in cursor.description]
            logs_list = []
            for row in cursor.fetchall():
                log_dict = {}
                for col, val in zip(columns, row):
                    if hasattr(val, "isoformat"):
                        log_dict[col] = val.isoformat()
                    elif isinstance(val, (int, float, str)) or val is None:
                        log_dict[col] = val
                    else:
                        log_dict[col] = str(val)
                logs_list.append(log_dict)
            return logs_list
        finally:
            cursor.close()
            conn.close()
