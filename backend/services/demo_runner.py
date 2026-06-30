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
        
        if key == "phantom":
            import urllib.request
            import json
            
            url = "http://host.docker.internal:9000/run"
            payload = {"demo": "phantom", "mode": type}
            headers = {"Content-Type": "application/json"}
            data = json.dumps(payload).encode("utf-8")
            
            print(f"[DemoRunner] Delegating Playwright execution to Demo Agent at {url}...")
            req = urllib.request.Request(url, data=data, headers=headers, method="POST")
            
            try:
                # Set a high timeout (60 seconds) to accommodate Playwright execution
                with urllib.request.urlopen(req, timeout=60) as response:
                    res_body = response.read().decode("utf-8")
                    print(f"[DemoRunner] Demo Agent responded: {res_body}")
                return
            except Exception as e:
                print(f"[DemoRunner] Failed to communicate with Demo Agent: {e}")
                raise RuntimeError(f"Communication with Demo Agent failed: {e}")

        proc = anomaly["procedures"][type]
        
        import threading
        import time
        
        def run_session(delay_str: str):
            conn = get_conn()
            cursor = conn.cursor()
            try:
                cursor.execute(f"EXEC {proc} @Delay = ?", delay_str)
                conn.commit()
            except Exception as e:
                print(f"Error in concurrent session with delay {delay_str}: {e}")
            finally:
                cursor.close()
                conn.close()
                
        # Start Session 1 (slow transaction: 8 seconds delay)
        t1 = threading.Thread(target=run_session, args=('00:00:08',))
        
        # Start Session 2 (fast transaction: 2 seconds delay) after a 2-second offset
        def start_session2():
            time.sleep(2)
            run_session('00:00:02')
            
        t2 = threading.Thread(target=start_session2)
        
        t1.start()
        t2.start()
        
        t1.join()
        t2.join()

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
