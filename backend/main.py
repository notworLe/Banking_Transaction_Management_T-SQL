from fastapi import FastAPI
from auth.router import router as auth_router
app = FastAPI(title="Banking API")
app.include_router(auth_router)

@app.get("/")
async def greet() -> str:
    return "Hello world"
