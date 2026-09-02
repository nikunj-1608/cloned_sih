# Project State

> [!IMPORTANT]
> This is a living document. Update your respective task statuses here before closing any pull request to the `staging` branch.

## Current Status Overview
**Active Phase:** Phase 1 (Foundation & Project Setup)
**Overall Health:** On Track

---

## Milestone Tracking

### Phase 1: Foundation & Project Setup (Active)
- [x] Repository initialization and branch protection (`staging` and `main` locked).
- [x] Initial documentation (`README.md`, `Tasks.md`, `PS.md` created).
- [ ] Backend: Initialize FastAPI server and Supabase instance.
- [ ] Backend: Enable PostGIS extension and create basic schemas.
- [ ] Frontend: Initialize Flutter project with Riverpod.
- [ ] Frontend: Render basic `flutter_map` interface.

### Phase 2: Offline Engine & Geospatial Core (Pending)
- [ ] Backend: Endpoints for IMBL, MPA, and PFZ GeoJSON data.
- [ ] Frontend: Implement `sqflite` caching for offline boundaries.
- [ ] Frontend: Integrate `turf_dart` for Point-in-Polygon (PiP) distance calculations.
- [ ] Frontend: Connect hardware GPS listener for geofencing alarms.

### Phase 3: External API & UI Integration (Pending)
- [ ] Backend: Data pipelines for Open-Meteo and INCOIS.
- [ ] Frontend: Build conversational chat interface.
- [ ] Frontend: Integrate AI4Bharat Bhashini (STT/TTS).

### Phase 4: Multi-Agent ML Orchestration (Pending)
- [ ] ML: Build LangGraph Supervisor and specialist sub-agents.
- [ ] ML: Implement Gemini 1.5 Flash structured outputs.
- [ ] Backend: Expose LangGraph swarm via FastAPI.
- [ ] Frontend: Parse JSON responses and render dynamic routes.

### Phase 5: Testing, Edge Cases & Final Polish (Pending)
- [ ] ML: Refine prompts for auditable execution traces.
- [ ] Backend: Implement telemetry flush for trip closures.
- [ ] Frontend: Polish offline alarm escalation and handle API timeouts.

---

## 4. Blockers & Risks

You can insert issues you're facing here.