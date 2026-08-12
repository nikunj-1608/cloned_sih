from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="SIH")

#this allows llutter local emulator to communicate with this api basically. it's a dummy request
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DummyRequest(BaseModel):
    message: str

@app.get("/")
def health_check():
    return {"status": "realpratz Test 1"}

@app.post("/test-connection")
def test_connection(req: DummyRequest):
    return {"reply": f"Backend received your message: {req.message}"}