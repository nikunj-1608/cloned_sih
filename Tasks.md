# Task List

Work is split into two parts. **Part I** is everything the prototype video needs
and nothing more. **Part II** is what turns the prototype into a system that
could actually go to sea.

> [!IMPORTANT]
> Anything not required to film a convincing demo belongs in Part II. If a task
> in Part I grows past what the camera will see, cut it back.

---
---

# Part I — Before the Prototype

**Goal:** a five-minute video showing a fisherman asking a question in Tamil,
getting an evidence-backed answer on a map, sailing out, and being alarmed
before crossing the maritime boundary — with the network switched off.

## Phase 0: Repository Scaffold — DONE
> **Goal:** Monorepo layout so all three tracks work in parallel.

### Pratz (Lead)
- [x] Create `mobile/`, `backend/`, `ai_service/`, `data/seed/`.
- [x] Fix `.gitignore` (the first backend PR was reverted because `app/` and
      `alembic/` landed at the repo root with committed `__pycache__/` blobs).
- [x] Add `.env.example` templates.

---

## Phase 1: Mobile Foundation — DONE
> **Goal:** A running app with the design system and the map in place.

### Yashika (Frontend)
- [x] Initialize the Flutter project in `mobile/` (Android + iOS).
- [x] Set up `Riverpod` (`NotifierProvider` and derived providers, no legacy APIs).
- [x] Build the design system: 64dp touch targets, sunlight-readable palette,
      bilingual labels, clamped text scaling.
- [x] Integrate `flutter_map` — IMBL, MPA and PFZ layers with a permanent legend.
- [x] Write the dependency-free geodesy kernel (`geo_math.dart`) with unit tests.
- [x] Home / Map / Ask shell with three always-visible destinations.

---

## Phase 2: Backend Core API — DONE
> **Goal:** Real HTTP the app can call. Data may be seeded; the contract is real.

### Nikunj (Backend)
- [x] Initialize `FastAPI` in `backend/` with `uv` and strict Pydantic schemas.
- [x] `GET /health` — liveness.
- [x] `GET /v1/boundaries` — IMBL and MPA as GeoJSON from `data/seed/`.
- [x] `GET /v1/pfz` — Potential Fishing Zones with a `valid_until` stamp.
- [x] `GET /v1/marine/conditions` — **live** Open-Meteo Marine proxy, normalized,
      with timeouts and graceful degradation to a cached last-known value.
- [x] `GET /v1/advisory-pack` — everything above in one response, for offline caching.
- [x] `POST /v1/chat` — **the contract that unblocks everyone.**

> [!IMPORTANT]
> `POST /v1/chat` returns `answer`, `evidence[]`, `map_layers[]` and
> `agent_trace[]`. Phase 2 backs it with a deterministic intent router. Phase 4
> swaps in LangGraph behind the identical schema, so the frontend never changes.

- [ ] ~~Local PostGIS in Docker~~ — **moved to Phase 6.** Shapely over seeded
      GeoJSON covers every demo query; a database buys nothing before the video.

## Phase 3: Offline Safety Kernel & The Alarm (ACTIVE)
> **Goal:** The money shot. The alarm must fire on camera, with the radio off.

### Yashika (Frontend)
- [ ] `sqflite` cache: download the advisory pack at port, read it at sea.
- [ ] Wire `geolocator` to the real position stream, with `DEMO_MODE` replaying a
      scripted track so the alarm can be filmed on land.
- [ ] **Boundary alarm UI** — full-screen takeover, siren, haptic, and a single
      large dismiss. Escalates by time-to-breach: 45 min, 15 min, crossing.
- [ ] Staleness meter: visibly degrade confidence as cached data ages.
- [ ] Airplane-mode test: every safety feature must work with the radio off.

## Phase 4: Conversational Layer
> **Goal:** Ask a question out loud, get an answer with a map and its evidence.

### Anushka (ML)
- [ ] `LangGraph` supervisor with Weather, Ocean and Geospatial specialists.
- [ ] **Gemini 2.5 Flash** via the **`google-genai`** SDK, strict function calling.
- [ ] Emit `agent_trace[]` — which agent ran, which tool it called, what came back.

> [!IMPORTANT]
> Gemini 1.5 Flash is retired for new projects and `google-generativeai` is the
> deprecated SDK. Target Gemini 2.5 Flash on `google-genai`.

### Yashika (Frontend)
- [ ] Live chat against `POST /v1/chat` with answer, map-layer and evidence cards.
- [ ] Expandable agent-trace panel — the explainability USP needs a surface.
- [ ] On-device `speech_to_text` + `flutter_tts`. **Not Bhashini yet.**

> [!WARNING]
> Bhashini onboarding takes days and its endpoints are unreliable. The voice demo
> must not depend on it. Regional STT/TTS goes behind a Dart interface now and
> Bhashini swaps in during Phase 8.

## Phase 5: Demo Assembly & Shoot
> **Goal:** Turn working software into five minutes of convincing footage.

### Everyone
- [ ] Script the run of show, beat by beat, before recording anything.
- [ ] Seed a demo dataset that makes every beat land (a PFZ worth sailing to, a
      boundary worth alarming about).
- [ ] Rehearse end-to-end on a physical handset, in airplane mode, twice.
- [ ] Record. Keep the raw footage.

---
---

# Part II — After the Prototype

**Goal:** replace every seeded value, mock and shortcut with the real thing.

## Phase 6: Real Data
### Nikunj (Backend)
- [ ] Replace hand-drawn geometry with the **authoritative** IMBL and MPA datasets.
- [ ] Ingest INCOIS PFZ advisory bulletins (see blocker #1 — they are per-district
      PDF/text, not an API). Parse to GeoJSON on a schedule.
- [ ] SST and chlorophyll into PostGIS with proper spatial-temporal indexing.
- [ ] Migrate from seeded files to PostGIS as the single source of truth.

> [!CAUTION]
> The Phase 1 demo geometry in `mobile/lib/features/map/demo_geo.dart` is
> hand-drawn and explicitly not survey-accurate. It must not survive Part II.

## Phase 7: Agent Depth
### Anushka (ML)
- [ ] Add Risk Assessment, Route Optimization and Reporting agents.
- [ ] Multi-turn context so users can refine a query across several turns.
- [ ] Auditable execution trace on every answer, not just the happy path.
- [ ] Stress-test with complex regional-language queries.
- [ ] Evaluation harness: a fixed question set, scored on every prompt change.

## Phase 8: Regional Language
### Yashika (Frontend) + Anushka (ML)
- [ ] Swap `AI4Bharat Bhashini` in behind the Phase 4 STT/TTS interface.
- [ ] Automatic language detection — reply in whatever language was asked.
- [ ] Extend beyond Tamil: Telugu, Malayalam, Odia, Bengali.
- [ ] Localize the whole UI, not only the assistant.

## Phase 9: Reliability
### Nikunj (Backend)
- [ ] Trip-closure telemetry flush — sync offline alert logs and spatial history
      back to Supabase once 4G returns at port.
- [ ] Auth, rate limiting, and structured request logging.

### Yashika (Frontend)
- [ ] Background execution so alarms fire with the screen off and the app closed.
- [ ] Battery profiling — a trip is measured in days, not hours.
- [ ] Handle API timeouts, async audio and state transitions without crashing.
- [ ] Crash reporting and an offline alert audit log.

## Phase 10: Scale
- [ ] Replace public OSM tiles with a licensed or self-hosted source.
      *(flutter_map warns about this: the public servers are not free to use.)*
- [ ] Field-test with actual fishermen and act on what they say.
- [ ] Play Store release track and update strategy for low-end devices.

---

## New USPs Adopted

| USP | Where it lands |
|---|---|
| **Two-Brain architecture** — deterministic offline kernel, online agentic brain | Phase 3 + 4 |
| **Time-to-breach** alerting instead of raw distance | Phase 3 |
| **Evidence ledger** with a freshness meter | Phase 2 + 4 |
| **Pre-departure advisory pack** | Phase 3 |
| **Demo Mode** scripted GPS track | Phase 3 |
| **Catch-log feedback loop** | Phase 7 |
