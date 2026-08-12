# SIH 2026 - AI-Based Farmer Query Support and Advisory System

## Architecture Overview
- **Mobile Client (`/mobile`):** Flutter Mobile App (Voice & Image Queries).
- **AI Microservice (`/ai_service`):** Python FastAPI (Sarvam Translation, Gemini / RAG Advisory, Disease Detection).
- **Database & Auth:** Supabase (PostgreSQL).

## Local Development Setup

### 1.AI Microservice Setup
Open your terminal and navigate to the `ai_service` directory:
```bash
cd ai_service
```

Create a Python virtual environment:
```bash
python -m venv venv
```

Activate the virtual environment:
- **Linux/Mac:** `source venv/bin/activate`
- **Windows (Command Prompt):** `venv\Scripts\activate.bat`
- **Windows (PowerShell):** `venv\Scripts\Activate.ps1`

Install dependencies:
```bash
pip install -r requirements.txt
```

Set up your secret keys:
1. Create a `.env` file inside `ai_service/`.
2. Copy contents from `.env.example` into `.env`.
3. Paste the real `GEMINI_API_KEY` and `SARVAM_API_KEY`

Run the FastAPI server:
```bash
uvicorn main:app --reload --port 8000
```
Your server will be running live at `http://localhost:8000` (interactive API docs at `http://localhost:8000/docs`).

### 2. Flutter Mobile Setup
Open your terminal and navigate to the `mobile` directory:
```bash
cd mobile
```

Fetch Flutter packages:
```bash
flutter pub get
```

Run the app on your emulator or physical device:
```bash
flutter run
```
*Note: To connect Flutter to the local AI server on an Android Emulator, use `http://10.0.2.2:8000` as the base API URL instead of `localhost`.*