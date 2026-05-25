# SafariMap — Development Plan v2.5 (Multi-Tenant SaaS Edition)

> Last updated: May 2026
> Architecture: Multi-Tenant B2B SaaS Ecosystem (Supports KWS, International Agencies, & Private Parks)
> Two apps: **SafariMap Visitor** (public global marketplace) · **SafariMap Ranger** (unlisted, tenant-isolated)
> Legend: 👤 Visitor app · 🛡️ Ranger app · 🤝 Both apps

---

## App Architecture Overview

SafariMap is engineered as a global multi-tenant platform sharing a sandboxed cloud infrastructure powered by Supabase:

- **SafariMap Visitor** — Public universal app; dynamically configures its UI, maps, currencies, and pricing based on the specific park or country boundaries the visitor enters.
- **SafariMap Ranger** — Unlisted, high-security app template. Requires organization-specific secure OAuth2 login; isolates all field telemetry by tenant ID.
- **Backend & Compute Gateway** — Supabase PostgreSQL/PostGIS database leveraging rigid Row-Level Security (RLS) policies. Mobile apps communicate natively with database tables for public reading, but route all heavy operational logic through **Supabase Edge Functions** (TypeScript/Deno) to enforce absolute data isolation across global tenants.
- **Hybrid offline-first** — All mobile data caches locally first via thread-safe schemas, syncing asynchronously when network permits.
- **Embedded map** — Mapbox SDK driving vector layers, topography meshes, and localized heatmaps.

---

## 🖥️ Central Admin Web Dashboard (Tenant Portal)

Every onboarded wildlife agency or private park owner receives access to an isolated desktop operations console featuring five core management modules:

### 1. 🗺️ Live Operations Command Center (The Map Room)
- **Real-Time Fleet Sync:** Renders live, thread-safe GPS coordinate vectors of active field rangers currently operating within the tenant's boundaries.
- **Anonymized Crowd Tracking:** Displays a toggleable real-time visitor density heatmap to identify pedestrian bottlenecks or vehicular speeding trends.
- **Active Incident Dispatch:** Fullscreen alert canvas showing incoming SOS triggers, vehicle breakdowns, or medical emergencies, allowing operators to drag-and-drop response missions to the nearest field ranger unit.

### 2. 📍 Infrastructure & Spatial Trail Editor
- **Mapbox Draw Toolkit:** Visual browser interface enabling wardens to trace new vehicle circuits, walking trails, or buffer zones directly onto satellite base maps.
- **Survey File Intake:** Native ingestion engine supporting drag-and-drop parsing of `.gpx`, `.kml`, and `.geojson` data layers sourced from field surveys.
- **Global Status Toggles:** Universal switches to instantly modify route access constraints (Open / Closed / Flooded) across the tenant's system network, automatically pushing vector recalibration data to mobile clients.

### 3. 🐾 Wildlife Telemetry & Sighting Controls
- **Dynamic Sighting Delay Console:** Control matrix allowing administrators to set rule-based time-delay buffers (e.g., hide completely, or delay by 30 mins) on high-risk endangered species to shield wildlife and stop vehicle swarming.
- **Vetting & Moderation Queue:** Interface to review, approve, edit, or purge visitor-submitted sighting pins before records write to the permanent analytical ledger.
- **Secure Collar API Ingestion:** Encrypted gateway interfaces to map external hardware tracking APIs (Movebank, AfriGIS) exclusively onto the high-security Ranger map layers.

### 4. 🚨 Incident Lifecycle & Disaster Management
- **Structured Resource Dispatch:** Digital ledger to log, track, and close active field incidents (Poaching alerts, medical crises, road blockages) with an immutable timestamp history.
- **Human-Wildlife Conflict Registry:** Spatial registry mapping localized border incidents (fence breaches, agricultural raids, predator interaction) to identify trends for long-term mitigation.

### 5. 📈 Revenue, Content, & System Audits
- **Pass Sales Revenue Analytics:** Financial tracking breakdown illuminating sales volume across localized payment processors (Pesapal M-Pesa hooks, Stripe card arrays, PayFast integrations).
- **Public CMS Bulletin:** Content management workflow to broadcast park guidelines, weather notices, alerts, and calendar logs straight into the Visitor App interface.
- **System Audit Trails:** Encrypted changelog logging every instance of manual route toggling, account provisioning, or sighting moderation to satisfy regulatory security compliance.

---

## Phase 1: Core Functionality (MVP)

### 🗺️ Maps & Navigation
- 👤 **Embedded park map** — Mapbox SDK rendered inside the app; shows terrain, water bodies, road grids, and foot trail networks.
- 👤 **Start trip & Intelligent GPS Tracking** — Background execution layers use adaptive distance-based GPS filtering to prevent **battery drain**. Polling patterns scale automatically depending on motion velocity (50m driving increments vs 15m pedestrian pacing, pausing completely when stationary).
- 👤 **Stop trip** — Visitor can retrace their recorded path back to start or navigate to the nearest trailhead/park exit.
- 👤 **Route & Trail filter** — Interactive map switches separating driving loops from designated pedestrian walking/hiking tracks.
- 👤 **Adaptive Vector Routing Engine** — Local map vector routing engines dynamically force client navigation to recalculate itineraries if a path status changes to closed or dangerous.
- 👤 **Park rules & Trekking Permissions** — Explicitly surfaces localized rule modules and safety levels: Self-Guided Walking Allowed, Ranger Escort Required, or Vehicles Only.
- 🤝 **Offline maps** — Automated localized packet downloads containing vector routing models and elevation grids readable without active data connection.

### 📍 Route & Trail Management
- 🛡️ **Record new route or trail** — Ranger application maps a track in real time; tags routing type, difficulty grading, and security escorts on submission.
- 🛡️ **Dual trail naming** — Separates confidential field ranger naming schemes from clean public-facing visitor labels.
- 🛡️ **Asset classification** — Structural map properties tagged by tenant preferences: All Vehicles / 4×4 Only / Hiking Path / Ranger Patrol Only.

### 🐾 Animal Sightings & Tagging
- 👤 **Tag a sighting** — Visitor logs animal details, count coordinates, and photos. Geolocation data and capture times are extracted via embedded image metadata.
- 👤 **Wishlist / Target trackers** — Allows users to mark off localized species targets as they navigate.
- 🛡️ **Incognito & Delayed Broadcast Logging** — Guides and rangers submit sightings directly to a `/submit-sighting` Edge Function. The backend securely checks the tenant's delay profile, reserving sensitive data in the research vault while hiding it from public maps until safe time limits expire.

### 🚨 Safety & Distress
- 👤 **Visitor SOS Framework** — One-tap emergency broadcast transmitting GPS coordinate vectors directly to adjacent rangers and tenant dispatch arrays.
- 🤝 **Cross-Platform SMS Fallback** — Critical offline backup loop:
    - **Android:** Background dispatch of raw structured coordinate string directly to the destination agency gateway.
    - **iOS:** Autocompiles structured coordinate syntax and brings up the native text messenger, requiring a quick confirmation tap from the user to broadcast.
- 👤 **Incident Logging** — Structured reporting templates for mechanical asset issues, road blockages, injuries, or hazardous animal behavior.

### 💳 Payments & Subscriptions (Visitor)
- 👤 **Flexible Safari & Trekking Passes** — Tailored access windows (e.g., 3-day, 7-day passes) formatted to scale naturally within holiday travel timelines instead of recurring monthly subscription models.
- 👤 **Tenant-Isolated Payment Processing** — Native webhooks securely run inside server-side Edge Functions (`/pesapal-webhook` or `/stripe-webhook`). This prevents client-side transaction spoofing, checks Instant Payment Notifications (IPN) asynchronously, and triggers automated Lipa na M-Pesa STK push windows on user devices safely.

---

## Technical Notes

| Concern | Decision & Architecture Strategy |
|:---|:---|
| **Multi-Tenant Isolation** | Database tables use PostgreSQL **Row-Level Security (RLS)** keyed to a tenant `organization_id`. Account identities use Supabase Auth Custom Claims, meaning tenant boundaries are parsed natively by the core DB engine. |
| **Backend API Layer** | **Supabase Edge Functions** (TypeScript on Deno) act as the secure gateway. They remove direct client insert privileges for operational actions, reducing database round-trip times and keeping payment secrets hidden from the client mobile binaries. |
| **Map Engine & Vectors** | Mapbox SDK via Flutter. Vector assets, topo maps, and static terrain shapes are packaged into compact, high-performance offline `.mbtiles` SQLite files. |
| **Offline Sync Mesh** | Handled via Flutter `sqflite` running multi-isolate thread-safe controller classes. Conflicts are processed via true event timestamp sequencing parsed against rigid organizational hierarchy privileges. |
| **Battery Conservation** | Position processing runs optimized motion wrappers (such as `flutter_background_geolocation`), toggling hardware sensors via accelerometer feedback to sleep GPS modules when users halt. |
| **AI Model Inference** | Hybrid configuration. Local device categorization runs embedded, quantized **TensorFlow Lite (TFLite)** modules for offline field indexing, seamlessly defaulting to full cloud lookups when cell connectivity is available. |
| **Ranger Deployment** | Privately provisioned binary distribution structures (Google Play Private Channel / Apple Custom App Distribution). Self-registration flows are omitted; access requires secure pre-assigned tenant admin credentials. |