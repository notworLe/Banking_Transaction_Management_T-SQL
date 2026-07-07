from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.demo_registry import DemoRegistry
from services.demo_runner import DemoRunner

router = APIRouter(prefix="/api/demo", tags=["demo"])

# Initialize registry and runner
try:
    registry = DemoRegistry()
    runner = DemoRunner(registry)
except Exception as e:
    # Fallback or log if loading configuration fails initially
    registry = None
    runner = None

class RunBody(BaseModel):
    type: str  # "bad" or "fix"

@router.get("/anomalies")
def get_anomalies():
    if not registry:
        raise HTTPException(status_code=500, detail="Registry not initialized")
    return registry.get_all()

@router.post("/{key}/reset")
def reset_anomaly(key: str):
    if not registry or not runner:
        raise HTTPException(status_code=500, detail="Services not initialized")
    
    anomaly = registry.get_anomaly(key)
    if not anomaly:
        raise HTTPException(status_code=404, detail=f"Anomaly '{key}' not found")
        
    try:
        runner.reset(key)
        return {"status": "success", "message": f"Reset for '{key}' completed successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{key}/run")
def run_anomaly(key: str, body: RunBody):
    if not registry or not runner:
        raise HTTPException(status_code=500, detail="Services not initialized")
    
    anomaly = registry.get_anomaly(key)
    if not anomaly:
        raise HTTPException(status_code=404, detail=f"Anomaly '{key}' not found")
        
    if body.type not in ("bad", "fix"):
        raise HTTPException(status_code=400, detail="Type must be 'bad' or 'fix'")
        
    try:
        runner.run(key, body.type)
        return {"status": "success", "message": f"Run '{body.type}' for '{key}' completed successfully."}
    except RuntimeError as e:
        # Demo Agent chưa chạy hoặc không thể kết nối
        if "Communication with Demo Agent failed" in str(e):
            raise HTTPException(
                status_code=503,
                detail="DEMO_AGENT_UNAVAILABLE"
            )
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{key}/logs")
def get_logs(key: str):
    if not registry or not runner:
        raise HTTPException(status_code=500, detail="Services not initialized")
    
    anomaly = registry.get_anomaly(key)
    if not anomaly:
        raise HTTPException(status_code=404, detail=f"Anomaly '{key}' not found")
        
    try:
        logs_list = runner.logs(key)
        return logs_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# ENDPOINTS CHO STATUSLOCK PLAYWRIGHT DEMO
# ==========================================

from dependencies import require_role
from fastapi import Depends
from database import get_conn

class StatusLockTransferForm(BaseModel):
    is_fix: bool

@router.post("/statuslock_transfer")
def statuslock_transfer(form: StatusLockTransferForm, user=Depends(require_role("Customer"))):
    """Endpoint cho Playwright T1 (Customer) gọi để chạy Transfer có delay"""
    conn = get_conn()
    conn.autocommit = True
    cur = conn.cursor()
    try:
        proc = "sp_Demo_StatusLock_Fix" if form.is_fix else "sp_Demo_StatusLock_Bad"
        cur.execute(f"EXEC {proc} @Delay = '00:00:05', @Role = 'TRANSFER'")
        return {"message": "Transfer completed (demo)"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

class StatusLockLockForm(BaseModel):
    is_fix: bool

@router.patch("/statuslock_lock/{account_id}")
def statuslock_lock(account_id: str, form: StatusLockLockForm, user=Depends(require_role("Banker"))):
    """Endpoint cho Playwright T2 (Banker) gọi để chạy Lock có delay"""
    conn = get_conn()
    conn.autocommit = True
    cur = conn.cursor()
    try:
        proc = "sp_Demo_StatusLock_Fix" if form.is_fix else "sp_Demo_StatusLock_Bad"
        cur.execute(f"EXEC {proc} @Delay = '00:00:02', @Role = 'LOCK'")
        return {"message": "Lock completed (demo)"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()
