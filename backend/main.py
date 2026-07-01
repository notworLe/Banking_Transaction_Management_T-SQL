from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from auth.router import router as auth_router
from routers.admin import router as admin_router
from routers.banker import router as banker_router
from routers.customer import router as customer_router
from routers.demo import router as demo_router

app = FastAPI(title="Banking Transaction API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(banker_router)
app.include_router(customer_router)
app.include_router(demo_router)


@app.get("/")
async def root():
    return {"message": "Banking Transaction API", "docs": "/docs"}
