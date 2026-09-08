# Project State

> [!IMPORTANT]
> This is a living document. Update your respective task statuses here before closing any pull request to the `staging` branch.

## Current Status Overview
**Active Phase:** Phase 4 (Conversational Layer) — Part I, pre-prototype
**Overall Health:** On Track
**Last Updated:** 2026-09-08

---

## Milestone Tracking

> Phases are split around the prototype video. See `Tasks.md`.

### Part I — Before the Prototype

**Phase 0: Repository Scaffold — Complete**
- [x] Monorepo layout (`mobile/`, `backend/`, `ai_service/`, `data/seed/`).
- [x] `.gitignore` corrected; `.env.example` templates added.

**Phase 1: Mobile Foundation — Complete**
- [x] Flutter project with Riverpod, Android + iOS.
- [x] Design system for low-literacy, high-glare marine use.
- [x] `flutter_map` with IMBL / MPA / PFZ layers and a legend.
- [x] Dependency-free geodesy kernel with 12 unit tests.
- [x] Verified: `flutter analyze` clean, 13/13 tests pass, debug APK builds.

**Phase 2: Backend Core API — Complete**
- [x] FastAPI in `backend/` (uv, Python 3.13) with strict Pydantic schemas.
- [x] `/health` — reports seed-data counts, not just liveness.
- [x] `/v1/boundaries` and `/v1/pfz` — GeoJSON from `data/seed/`, radius filtering.
- [x] `/v1/marine/conditions` — live Open-Meteo, degrades instead of failing.
- [x] `/v1/advisory-pack` — bundled offline response with `valid_until`.
- [x] `POST /v1/chat` — schema locked; deterministic router reports `engine="rules"`.
- [x] Verified: 19/19 tests pass, ruff clean, live data confirmed end to end.
- [ ] Local PostGIS container — **deferred to Phase 6**, not needed for the video.

**Phase 3: Offline Safety Kernel & The Alarm — Complete**
- [x] `sqflite` advisory-pack cache with graceful degradation.
- [x] `LocationService` seam: real `geolocator` stream, or a scripted demo track.
- [x] Full-screen boundary alarm — bundled siren, haptics, one-way escalation.
- [x] Crossing detection by side-of-line (see Architecture Decisions).
- [x] Staleness meter that drains over the pack's validity window.
- [x] Verified: 42/42 tests pass, analyzer clean, debug APK builds.
- [ ] Airplane-mode rehearsal on a physical handset — needs a device.

**Phase 4: Conversational Layer — Pending**
- [ ] LangGraph supervisor + specialists on Gemini 2.5 Flash.
- [ ] `agent_trace[]` emission and the trace panel in-app.
- [ ] On-device STT/TTS behind a swappable interface.

**Phase 5: Demo Assembly & Shoot — Pending**
- [ ] Run of show scripted; demo dataset seeded; two full rehearsals; record.

### Part II — After the Prototype
- [ ] Phase 6: Authoritative IMBL/MPA data, INCOIS ingestion, PostGIS as source of truth.
- [ ] Phase 7: Risk / route / reporting agents, multi-turn context, eval harness.
- [ ] Phase 8: Bhashini, language detection, five regional languages.
- [ ] Phase 9: Telemetry flush, background alarms, battery profiling, auth.
- [ ] Phase 10: Licensed tile source, field testing, Play Store release.

---

## Architecture Decisions

### The "Two-Brain" split
The problem statement demands a conversational AI platform, but the app must work at sea with zero connectivity. These are resolved by splitting the system explicitly:

*   **Offline Safety Kernel** — geofencing, distance, time-to-breach, and alarms. Runs entirely on-device against cached data. No network, no LLM. It cannot hallucinate.
*   **Online Reasoning Brain** — the LangGraph agent swarm. Runs at port or within cell range.

A language model never decides whether the vessel is about to cross a maritime boundary.

### Crossing detection is side-of-line, not distance

A boundary alarm driven purely by distance falls silent at the worst possible
moment: once the vessel is past the line the distance starts growing again, so
"am I getting closer?" answers no. The kernel therefore compares which *side* of
the boundary the vessel is on against its home port, and treats a side change as
a breach regardless of distance. Found by the escalation test in
`mobile/test/alarm_escalation_test.dart`, which is the regression guard.

### Demo region
Palk Strait / Rameswaram. The IMBL sits close to shore there and boundary crossings are a well-documented real-world problem, which makes the geofencing demo urgent rather than academic.

---

## Blockers & Risks

| # | Issue | Impact | Mitigation |
|---|---|---|---|
| 1 | **INCOIS has no consumable public API.** Probed 2026-09-08: `portal/osf` → 404, `geoserver` → 403, `las` and `sarat` → timeout. PFZ advisories are published as per-district PDF/text bulletins, not GeoJSON. | High — Phase 2 and 3 both assumed an API that does not exist. | Seed PFZ/SST/chlorophyll into PostGIS from published bulletins. Treat a live parser as a stretch goal. |
| 2 | **Bhashini onboarding latency.** ULCA/UDYAT key issuance takes days; pipeline endpoints are unreliable. | Medium — could block the voice demo. | STT/TTS behind a Dart interface; on-device `speech_to_text` + `flutter_tts` is the default implementation. |
| 3 | **`turf_dart` does not exist** on pub.dev. The package is `turf`, at `0.0.12`. | Medium — would have failed at `pub add`, and is unfit for the safety path. | Dependency-free ray-casting PiP + haversine in Dart. |
| 4 | **Gemini 1.5 Flash is retired** for new projects; `google-generativeai` is the deprecated SDK. | Medium — would produce dead code. | Gemini 2.5 Flash via `google-genai`. |
| 5 | **First backend PR was reverted** (`5657bbf`) — code landed at repo root with committed `__pycache__/` blobs. | Resolved | Monorepo layout enforced in Phase 0; `.gitignore` corrected. |
| 6 | **Cannot film the geofence alarm at sea.** Live GPS will not fire on cue during a take. | Medium — risks the prototype video. | Demo Mode replays a canned GPS track toward the IMBL. |

---

## Verified External Dependencies

| Source | Status | Notes |
|---|---|---|
| Open-Meteo Marine API | Working, keyless | Verified 2026-09-08 against 13.04N / 80.45E |
| INCOIS | Not consumable | See blocker #1 |
| OSM raster tiles | Working | Used for the base map |
