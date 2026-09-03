from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(
    title=settings.APP_NAME,
    description="Backend API for Smart India Hackathon 2026 Project",
    version="1.0.0"
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Health Check"])
async def root():
    return {
        "status": "online",
        "message": f"Welcome to {settings.APP_NAME}",
        "version": "1.0.0"
    }

@app.get("/api/v1/health", tags=["Health Check"])
async def health_check():
    return {
        "status": "healthy",
        "database": "disconnected"
    }