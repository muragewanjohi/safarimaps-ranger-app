# SafariMap — Development Plan v2

> Last updated: May 2026
> Two apps: **SafariMap Visitor** (public) · **SafariMap Ranger** (verified KWS / park staff only)
> Legend: 👤 Visitor app · 🛡️ Ranger app · 🤝 Both apps

---

## App Architecture Overview

SafariMap is built as **two separate apps** sharing one backend:

- **SafariMap Visitor** — downloadable by the public; free tier + paid subscription
- **SafariMap Ranger** — restricted to verified rangers, wardens, and KWS-credentialed guides; no public registration
- **Shared backend** — single API, shared route/sighting database, real-time sync via WebSockets
- **Hybrid offline-first** — all data saved locally first, pushed to cloud when connectivity is available
- **Embedded map** — Mapbox SDK powering both apps; custom route layers, heatmap, offline tile packs

---

## Phase 1: Core Functionality (MVP)

### 🗺️ Maps & Navigation

- 👤 **Embedded park map** — Mapbox SDK rendered inside the app (no redirect to Google Maps); shows terrain, water bodies, and route network
- 👤 **Start trip** — visitor selects park; app prompts to download offline tile pack for that park; GPS path recording begins automatically
- 👤 **Stop trip** — visitor can retrace their recorded path back to start, or navigate to the nearest park exit
- 👤 **Exit park** — dedicated option showing all park exits with estimated drive time per route type
- 👤 **Route filter** — toggle between small car routes, 4×4-only routes, and closed/decommissioned roads; colour-coded (green = all vehicles, amber = 4×4 only, grey = closed)
- 👤 **Park opening & closing times** — displayed on map header; push notification sent when less than 1 hour remains before closing
- 👤 **Park rules** — shown at trip start and accessible from the menu
- 🤝 **Offline maps** — Mapbox tile packs downloaded per park at trip start; all cached route data and sighting pins accessible without connectivity

### 📍 Route Management

- 🛡️ **Record new route** — ranger drives or walks a track; app records a GPS breadcrumb trail (same as Strava); ranger names the route and tags vehicle type on completion
- 🛡️ **Draw route on admin portal** — warden traces tracks on satellite imagery using Mapbox Draw in the web admin portal; supports import of .gpx, .kml, and .geojson files from existing KWS surveys
- 🛡️ **Route approval workflow** — newly recorded or drawn routes are reviewed and approved by a senior warden before going live on the map
- 🛡️ **Dual route naming** — every route has an internal ranger name (e.g. "Hippo Circuit") and an optional visitor-facing name (e.g. "Southern Loop"); ranger names are hidden from visitors
- 🛡️ **Route status update** — ranger taps any route on the map and updates its status: Open / Closed / Flooded / Damaged / Seasonal; change is broadcast to all active visitor sessions within minutes
- 🛡️ **Ranger-only routes** — routes flagged as ranger-only are hidden from the visitor map entirely (patrol routes, anti-poaching corridors)
- 🛡️ **Vehicle type tagging** — routes tagged as: All vehicles / 4×4 only / Ranger only / Decommissioned
- 🛡️ **Route audit trail** — every route change logs who made it and when; visible to wardens in the admin portal

### 🐾 Animal Sightings & Tagging

- 👤 **Tag a sighting** — visitor pins a sighting on the map with species, event description (e.g. "lions hunting a buffalo"), 3–5 photos, and number of animals spotted; timestamp and GPS location captured automatically
- 👤 **Auto-timestamp on photo** — GPS coordinates and time embedded at capture; no manual entry required
- 👤 **Link photos to a safari** — photos and sightings attached to the active trip; trip can be renamed (e.g. "Amboseli June 2026")
- 👤 **Sighting pin colours** — pins colour-coded by recency: last 15 min (bright), last 1 hour (medium), older (faded)
- 👤 **Wishlist / Big Five tracker** — visitor tracks target animals and marks each as seen
- 🛡️ **Verified ranger sighting tag** — ranger-tagged sightings carry a verified badge and are displayed prominently; ranger can tag species, count, behaviour, and attach photos
- 🛡️ **Sighting moderation** — ranger or warden can remove inaccurate visitor-submitted sightings

### 🚨 Safety & Distress

- 👤 **Visitor SOS** — one-tap distress alert; broadcasts visitor GPS location to all rangers in that park and KWS command; SMS fallback triggered automatically when no data connection available
- 👤 **Mechanical breakdown report** — visitor reports car breakdown or vehicle stuck in mud; includes photo, GPS location, and incident type (breakdown / mud / flat tyre); routed to nearest available ranger
- 👤 **Report types** — SOS / Breakdown / Stuck in mud / Wildlife conflict / Other
- 🛡️ **Incident visible to all rangers** — any incident reported by a ranger (or escalated from a visitor) is immediately broadcast to all active rangers in that park with a map pin and push notification
- 🛡️ **Incident types (ranger-initiated)** — SOS response / Poaching / Road damage / Animal conflict / Fire / Visitor welfare
- 🛡️ **Incident lifecycle** — Open → Assigned → Resolved; status visible to all rangers in the park
- 🛡️ **Respond action** — ranger taps an incident and hits Respond; app navigates ranger to the incident location

### 💳 Payments & Subscriptions (Visitor)

- 👤 **Free tier** — 1-hour full access; after expiry, restricted to nearby sightings and public photos only
- 👤 **Paid tier** — KES 500 via M-Pesa (Pesapal) or $5 via card (Pesapal / Stripe); daily and monthly plans
- 👤 **Premium features** (paid only) — ranger-verified sighting pins, crowd heatmap, AI animal identification, wishlist proximity notifications, historical sighting data
- 👤 **Payment methods** — Pesapal as primary gateway (M-Pesa + Visa/Mastercard, KRA-compliant); Stripe as fallback for international visitors

### 📋 Park Information

- 👤 **News board / events page** — park announcements, upcoming activities (e.g. tree planting), KWS news
- 👤 **Calendar** — scheduled park events and activities
- 🛡️ **KWS advertising portal** — admin interface for KWS to publish promotions and announcements visible in the visitor app

---

## Phase 2: Tracking Enhancements & Engagement

### 🗺️ Crowd & Heatmap Intelligence

- 👤 **Points of interest** — locations where many visitors are gathered auto-surface as points of interest on the visitor map; colour-coded by density (blue sparse → amber medium → red high); clears automatically when visitors disperse
- 👤 **Navigate to point of interest** — visitor taps a POI and gets turn-by-turn navigation along safe park routes to reach it
- 🛡️ **Ranger crowd density view** — ranger map shows visitor density heatmap (Uber-style); helps wardens deploy rangers proactively to high-traffic areas
- 🛡️ **Visitor path analytics** — aggregate (anonymised) visitor paths visible to rangers; helps identify congestion points and off-road driving patterns

### 🤖 AI Features

- 👤 **AI animal identification** — visitor photographs an animal; AI identifies species and returns facts, behaviour notes, and conservation status
- 👤 **AI animal sound recognition** — visitor records a sound; AI identifies the animal species from audio
- 🛡️ **AI-assisted ranger tagging** — AI pre-fills species suggestion when ranger photographs a sighting; ranger confirms or overrides

### 🔔 Notifications

- 👤 **Wishlist proximity alert** — push notification when a ranger-tagged sighting of a wishlist animal is within 10–20 minutes of the visitor's current location; includes navigation option
- 👤 **Park closing countdown** — notification sent 60 min and 30 min before closing time
- 🛡️ **Ranger-to-ranger alert** — all incidents and route status changes broadcast instantly to rangers in the same park

### 📊 Analytics & Feedback

- 👤 **Feedback form** — visitor submits feedback; stored in database and visible to park management
- 👤 **Animal analytics (visitor)** — visitor's personal stats: animals spotted, species breakdown, parks visited
- 🛡️ **Animal analytics (park-wide)** — ranger dashboard showing species frequency by location and time; helps wildlife management decisions
- 🛡️ **Points & rewards for rangers/guides** — rangers earn points for verified sightings, incident responses, and route updates; redeemable via partner rewards

### 👥 Social Layer

- 👤 **Follow other visitors** — follow other users and see their public safari photos (Instagram-style feed for wildlife and travel)
- 👤 **Premium version** — enhanced social features, unlimited photo uploads, priority AI processing

---

## Phase 3: Community & Historical Data

### 🌍 Wildlife Tracking

- 🛡️ **Live animal tracking** — connect to real-time GPS collar APIs (e.g. AfriGIS, Movebank) for live animal location overlays; ranger-only layer by default
- 👤 **Migratory pattern display** — static and animated visualisation of known animal migration routes based on wildlife database data and historical sightings
- 🛡️ **History of migratory patterns and Big Five sightings** — store and display historical sighting data and last-known locations per species per park

### 🌿 Community & Conflict

- 👤 **Report human-wildlife conflict** — geo-tagged conflict report with photo upload; routed to KWS
- 🛡️ **Human-wildlife conflict dashboard** — ranger view of all active and historical conflict reports with map overlay
- 👤 **Live feed** — real-time stream of public sightings and events across all parks

### 🏆 Gamification

- 👤 **Points for using the app** — visitors earn points for sightings, feedback, and community contributions; redeemable via partner rewards (hotels, tour operators)
- 🛡️ **Ranger leaderboard** — top contributors by verified sightings and incident responses

---

## Phase 4: Advanced Features, Partnerships & Niche Offerings

### 📸 Marketplace

- 👤 **Photo marketplace** — visitors can list and sell high-quality wildlife photos through the app; built on Cloudinary (storage) and Stripe (payouts)

### 🧭 Planning & Premium Tours

- 👤 **Safari planner** — calendar-based trip planner; suggests parks and routes based on seasonal migration data, historical sightings, and current animal activity
- 👤 **Premium private tours** — curated tour packages bookable through the app (gorilla tours, bird watching, night safaris); integrated with tour operator APIs

### 🌡️ Environment & Integrations

- 🛡️ **Climate change tracking** — rangers log environmental data (water levels, vegetation, weather events); visualised as trend charts for conservation reporting
- 🛡️ **Integration with external tagging systems** — deeper integration with KWS collar tracking, AfriGIS, and other wildlife monitoring systems

### 🤝 Partnerships

- 🛡️ **Partner admin panel** — hospitality and tourism partners manage their rewards, promotions, and listings through a dedicated portal
- 🛡️ **Tourism & hospitality association integration** — connect with booking APIs for hotels, lodges, and tour operators near each park

---

## Technical Notes

| Concern | Decision |
|---|---|
| Map engine | Mapbox SDK (React Native / Flutter); offline tile packs per park |
| Route data format | GeoJSON LineString stored in PostGIS; served as vector tiles |
| Real-time sync | WebSockets (Supabase Realtime or Socket.io) for incidents, route status, heatmap |
| Offline sync | SQLite local store + background sync queue; conflict resolution: last-write-wins for status, merge for collections |
| Photo storage | Cloudinary (upload on connectivity restore) |
| Payments | Pesapal primary (M-Pesa + card, KRA-compliant); Stripe fallback for international |
| AI identification | On-device TFLite model + cloud fallback (lower accuracy offline) |
| SOS offline fallback | Pre-composed SMS to KWS gateway number with GPS coordinates; triggers on no-data SOS |
| Ranger authentication | KWS-issued credentials only; no self-registration on ranger app |
| Privacy | Visitor paths aggregated anonymously server-side; individual coordinates never exposed to rangers |
| Route changes → offline maps | Route status changes invalidate cached tile segments; lightweight manifest sync at trip start |

