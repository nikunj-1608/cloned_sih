from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.config import settings
from app.database import get_db

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

@app.get("/api/v1/health/db", tags=["Health Check"])
def db_health_check(db: Session = Depends(get_db)):
    try:
        result = db.execute(text("SELECT 1")).scalar()
        return {"status": "healthy", "database": "connected", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")