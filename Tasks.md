# Task List

---

## Phase 1: Foundation & Project Setup
> **Goal:** Establish the core structural components of the application.

### Nikunj (Backend)
- [ ] Initialize the `FastAPI` server environment.
- [ ] Set up the `Supabase` instance and enable the `PostGIS` extension.
- [ ] Create basic database schemas (e.g., user profiles, spatial tables for boundaries).

### Yashika (Frontend)
- [ ] Initialize the Flutter project.
- [ ] Set up `Riverpod` for state management.
- [ ] Integrate `flutter_map` and render a basic map interface.

### Anushka (ML)
- [ ] *(On standby: reviewing documentation for LangGraph, AI4Bharat Bhashini, and Gemini 1.5 Flash structured outputs).*

---

## Phase 2: Offline Engine & Geospatial Core
> **Goal:** Ensure the application can function without the internet at sea.

### Nikunj (Backend)
- [ ] Create API endpoints to serve International Maritime Boundary Line (IMBL) and Marine Protected Area (MPA) boundaries as GeoJSON.
- [ ] Create endpoints to serve 24-hour Potential Fishing Zone (PFZ) coordinate data.

### Yashika (Frontend)
- [ ] Implement `sqflite` for pre-departure downloading and caching of the GeoJSON boundaries.
- [ ] Integrate `turf_dart` and write the Point-in-Polygon (PiP) background distance calculator.
- [ ] Connect the hardware GPS listener to trigger visual and auditory alarms when the vessel approaches geofenced boundaries.

---

## Phase 3: External API & UI Integration
> **Goal:** Connect weather data pipelines and the voice interface.

### Nikunj (Backend)
- [ ] Write connector scripts to fetch and format marine weather data from the `Open-Meteo` API (wave height, wind speed, swell period).
- [ ] Ensure `INCOIS` data pipelines (SST, Chlorophyll) are properly structured for database insertion.

### Yashika (Frontend)
- [ ] Build the main conversational chat interface (UI).
- [ ] Integrate the `AI4Bharat Bhashini` API for regional Speech-to-Text (STT) and Text-to-Speech (TTS).

---

## Phase 4: Multi-Agent ML Orchestration
> **Goal:** Build the brain of the platform now that the backend endpoints and frontend UI are ready.

### Anushka (ML)
- [ ] Build the `LangGraph` Supervisor Agent to parse natural language queries.
- [ ] Develop the specialist sub-agents (Ocean Analytics Agent, Weather Intelligence Agent).
- [ ] Implement Google Gemini 1.5 Flash using strict Function Calling/Structured Outputs to force deterministic data retrieval and eliminate hallucinations.

### Nikunj (Backend)
- [ ] Expose the LangGraph swarm via `FastAPI` endpoints so the frontend can send transcribed user queries to it.
- [ ] Ensure the Python functions (tool calling) correctly query the `PostGIS` database based on the AI's requests.

### Yashika (Frontend)
- [ ] Connect the Bhashini-transcribed text to the new FastAPI agent endpoints.
- [ ] Parse the structured JSON response from the agents to render dynamic routes and GeoJSON overlays on `flutter_map`.

---

## Phase 5: Testing, Edge Cases & Final Polish
> **Goal:** Ensure mission-critical reliability and system optimization.

### Anushka (ML)
- [ ] Refine agent prompts to ensure the Synthesis Agent always provides an auditable execution trace (explaining exactly why a route is safe based on the data).
- [ ] Stress-test the model with complex, multi-turn regional language queries.

### Nikunj (Backend)
- [ ] Implement the "trip closure" telemetry flush (syncing offline alert logs and spatial history back to Supabase once 4G is restored at port).

### Yashika (Frontend)
- [ ] Polish the UI/UX, especially the offline alarm escalation module.
- [ ] Handle API timeouts, asynchronous audio loading, and state management gracefully to prevent app crashes.