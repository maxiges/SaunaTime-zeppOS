# Sauna Time — Local HTTP API for Smartwatch Synchronization

This document is the **authoritative API specification** for sending sauna session
data from a smartwatch (Zepp OS, Garmin, Apple Watch, etc.) to the **Sauna Time**
app running on an Android/iOS phone.

It is written so that it can be handed to an AI/developer as the single source of
truth for implementing the watch-side **send & synchronize** feature.

---

## 1. Overview

Sauna Time runs a small **local HTTP server inside the phone app**. The watch
pushes JSON payloads describing a completed sauna session; the app parses,
validates, **deduplicates**, and stores them in its local database.

- **Transport:** plain HTTP (no TLS — local network only).
- **Content-Type:** `application/json` (UTF-8).
- **Base URL:** `http://<phone-ip-address>:<port>`
- **Default port:** `8080` (configurable in the app's HTTP console).
- **Server binds to:** all network interfaces (`0.0.0.0`) — reachable from any
  device on the same network.
- **CORS:** enabled (`Access-Control-Allow-Origin: *`, methods `GET, POST, OPTIONS`)
  so it also works from a desktop browser / web test tool.

### Endpoints at a glance

| Method    | Path            | Purpose                                      |
| --------- | --------------- | -------------------------------------------- |
| `GET`     | `/api/status`   | Server health + session count (also `GET /`) |
| `POST`    | `/api/sessions` | **Send / add one sauna session** (primary)   |
| `POST`    | `/session`      | Alias for `/api/sessions`                    |
| `OPTIONS` | any path        | CORS preflight (returns `200 OK`)            |

---

## 2. Connection & Base URL

The phone app starts the server automatically when the app is launched
(`main.dart` calls `startServer(port: 8080)`).

To discover the phone's address:

- The app shows the server address in the **HTTP & Watch** console
  (e.g., `http://192.168.1.23:8080`).
- The watch must be on the **same Wi-Fi network** as the phone, or connected to
  the **phone's hotspot**.

> **Emulator note:** on the Android emulator the host loopback is `10.0.2.2`,
> not `127.0.0.1`. On a physical device, use the phone's LAN IP.

---

## 3. Server status — `GET /api/status`

Useful as a lightweight "is the app reachable?" check before sending data.

**Request:**

```
GET http://<phone-ip>:8080/api/status
```

**Response — `200 OK`:**

```json
{
  "status": "ok",
  "app": "sauna_time",
  "version": "1.0.0",
  "sessionsCount": 42
}
```

---

## 4. Adding a session — `POST /api/sessions`

This is **the** endpoint the watch uses to upload one sauna session.

```
POST http://<phone-ip>:8080/api/sessions
Content-Type: application/json

{ ...session payload... }
```

### 4.1 Minimal payload (valid)

```json
{
  "startTime": 1785081600,
  "durationMinutes": 15,
  "temperature": 86.5,
  "averageHeartRate": 114,
  "maxHeartRate": 142
}
```

### 4.2 Full payload (recommended — everything the app can display)

```json
{
  "id": "zepp-2026-08-24-1800-7f3a",
  "startTime": 1785081600,
  "endTime": 1785082680,
  "durationMinutes": 18,
  "temperature": 88.0,
  "averageHeartRate": 121,
  "maxHeartRate": 142,
  "notes": "Evening sauna",
  "phases": [1, 2, 3],
  "heartRateSamples": [
    { "timestamp": 1785081660, "value": 85.0, "phase": 1 },
    { "timestamp": 1785082200, "value": 120.0, "phase": 2 },
    { "timestamp": 1785082560, "value": 95.0, "phase": 3 }
  ],
  "temperatureSamples": [
    { "timestamp": 1785081660, "value": 84.0 },
    { "timestamp": 1785082200, "value": 87.0 }
  ]
}
```

### 4.3 Field reference

| Field                | Type            | Required | Default / Notes                                                                |
| -------------------- | --------------- | -------- | ------------------------------------------------------------------------------ |
| `id`                 | string          | no       | Auto-generated UUID if omitted. **Send a stable id to make sync idempotent.**  |
| `startTime`          | number (Unix s) | no       | Unix timestamp in **seconds** (or ISO-8601). Defaults to now. Alias: `date`.   |
| `endTime`            | number (Unix s) | no       | Unix timestamp in **seconds** (or ISO-8601). Used to derive `durationMinutes`. |
| `durationMinutes`    | number          | no       | Duration in minutes — can be fractional (e.g. `12.5`). Default `15`.           |
| `durationSeconds`    | int             | no       | Duration in **seconds** — highest precision. Overrides `durationMinutes`.      |
| `temperature`        | number          | no       | Air/session temperature in °C. Alias: `temp`.                                  |
| `averageHeartRate`   | int             | no       | Alias: `avgHr`, `avg_heart_rate`.                                              |
| `maxHeartRate`       | int             | no       | Alias: `maxHr`, `max_heart_rate`.                                              |
| `notes`              | string          | no       | Free text. Alias: `comment`.                                                   |
| `phases`             | array           | no       | 1–3 sauna phases. Alias: `stages`, `etapy`. See §4.4.                          |
| `heartRateSamples`   | array           | no       | HR telemetry points. Alias: `heart_rate_samples`. See §4.5.                    |
| `temperatureSamples` | array           | no       | Temperature telemetry points. See §4.5.                                        |

> Every session posted through this API is stored with `source = "watchHttp"` by
> the server (this is used for filtering in the app and for duplicate detection).

> **Duration precision:** send `durationSeconds` (or a fractional `durationMinutes`,
> e.g. `12.5`) to record the exact length to the **second**. When `endTime` is
> provided it always wins (`endTime − startTime`, second precision).
> Priority: `endTime` → `durationSeconds` → `durationMinutes` → `15` min.

### 4.4 Phases (`phases`) — optional, 1 to 3 stages

Each sauna session can be split into up to 3 phases. In the optimized API a phase
is sent as a **number**:

| Code | Phase     | Meaning                              |
| ---- | --------- | ------------------------------------ |
| `1`  | `heating` | the actual sauna phase — **default** |
| `2`  | `cooling` | cooling down                         |
| `3`  | `resting` | resting between rounds               |

```json
"phases": [1, 2, 3]
```

If `phases` (or a sample's `phase`) is omitted, it **defaults to `1` (heating)**.

For backward compatibility the server still accepts the **string names** and the
**object form with an optional duration** (used to split samples by time):

```json
"phases": [
  { "type": 1, "durationMinutes": 9 },
  { "type": 2, "durationMinutes": 5 },
  { "type": 3, "durationMinutes": 4 }
]
```

The type key inside an object can be `type`, `phase`, `name`, or `etap` (number or
name); the duration key can be `durationMinutes`, `duration`, or `minutes`.

**Accepted string names** (case-insensitive, for compatibility):

| Code | Phase     | Accepted names                                                               |
| ---- | --------- | ---------------------------------------------------------------------------- |
| `1`  | `heating` | `heating`, `warmup`, `warm-up`, `heat`, `sauna`, `nagrzewanie`, `saunowanie` |
| `2`  | `cooling` | `cooling`, `cool`, `cold`, `chłodzenie`, `chlodzenie`, `schladzanie`         |
| `3`  | `resting` | `resting`, `rest`, `relax`, `odpoczywanie`, `odpoczynek`                     |

**Behavior:**

- If samples do **not** carry a `phase` field but `phases` is declared, the server
  tags each sample with a phase automatically based on time (equal split, or
  according to the `durationMinutes` you provide).
- A sample without any `phase` at all is treated as `1` (heating).
- Unknown phase codes/names are ignored.

### 4.5 Measurement samples (`heartRateSamples` / `temperatureSamples`)

Each sample is an object:

```json
{
  "timestamp": 1785081660,
  "value": 85.0,
  "phase": 1
}
```

| Field       | Type            | Notes                                                            |
| ----------- | --------------- | ---------------------------------------------------------------- |
| `timestamp` | number (Unix s) | Required. Unix timestamp in **seconds** (or ISO-8601 string).    |
| `value`     | number          | Required. HR in bpm, or temperature in °C.                       |
| `phase`     | number          | Optional. `1` = heating (default), `2` = cooling, `3` = resting. |

The samples are used by the app to draw heart-rate / temperature charts colored
by phase.

---

## 5. Responses & status codes

| Status code                 | Meaning                                                          | Example body                                                          |
| --------------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------- |
| `201 Created`               | Session was **stored** successfully (new entry).                 | `{"success":true,"sessionId":"...","message":"..."}`                  |
| `200 OK`                    | **Duplicate detected** — session already exists, nothing stored. | `{"success":true,"duplicate":true,"sessionId":"...","message":"..."}` |
| `400 Bad Request`           | Empty request body.                                              | `{"error":"Puste ciało żądania"}`                                     |
| `404 Not Found`             | Unknown endpoint.                                                | `{"error":"Endpoint nie istnieje"}`                                   |
| `500 Internal Server Error` | Malformed JSON or unexpected server error.                       | `{"error":"Błąd wewnętrzny: ..."}`                                    |

**Success (`201`) body example:**

```json
{
  "success": true,
  "sessionId": "watch-100",
  "message": "Sesja została odebrana i zapisana w Sauna Time"
}
```

**Duplicate (`200`) body example:**

```json
{
  "success": true,
  "duplicate": true,
  "sessionId": "watch-100",
  "message": "Sesja już istnieje — pominięto, aby uniknąć duplikatu"
}
```

> Treat **both** `201` and `200` (with `duplicate: true`) as a successful sync.

---

## 6. Duplicate detection & idempotency (IMPORTANT)

The server is designed to **never store the same session twice**, even if the
watch re-sends it. Duplicate protection works on two levels:

### 6.1 By explicit `id` (recommended)

If the payload contains an `id` that already exists in the database, the server
returns `200 OK` with `duplicate: true` and **does not** overwrite or re-add the
existing entry.

**→ For reliable sync, the watch MUST generate a stable `id` once per sauna
session and reuse the exact same `id` on every retry / re-sync.**

Good id candidates:

- Watch's own session start timestamp + device serial, e.g. `zepp-<deviceId>-<epochSeconds>`.
- Any string the watch can reliably reproduce for the same physical session.

### 6.2 By content fingerprint (safety net)

If the watch does **not** send an `id` (or sends a new one each time), the server
falls back to a **content fingerprint**:

```
fingerprint = source + "|" + startTime (UTC, minute precision) + "|" + durationMinutes
```

If a stored session matches this fingerprint, the incoming one is treated as a
duplicate and **skipped** (`200 OK`, `duplicate: true`). This guarantees that a
watch which generates a fresh UUID on every attempt still cannot flood the app
with duplicate entries.

### 6.3 What the watch should do

- **Always send the same stable `id` for the same session.** This makes sync
  fully idempotent regardless of fingerprint edge cases.
- After receiving `201` **or** `200/duplicate`, mark the session as _synced_ in
  the watch's local storage so it is not re-queued.
- Only delete the watch-side record after a confirmed `201`/`200`.

---

## 7. Recommended Zepp OS sync flow (implementation guide)

1. **Record** the session locally on the watch (phases, HR/temp samples, times).
2. **Generate a stable `id`** once when the session ends:
   ```
   id = "zepp-" + deviceId + "-" + startEpochSeconds
   ```
   Persist it with the session record.
3. **Build the payload** exactly as in §4.2.
4. **POST** it to `http://<phone-ip>:8080/api/sessions`.
   - Content-Type: `application/json`.
   - Set a reasonable timeout (e.g., 5–10 s).
5. **Interpret the response:**
   - `201` → stored. Mark synced. ✅
   - `200` + `duplicate: true` → already present. Mark synced. ✅
   - `400` → malformed payload. Fix and retry (do not loop forever).
   - `500` → server error (e.g., invalid JSON). Check payload formatting.
   - Network error / timeout → the phone app may be closed or out of range.
     **Retry with backoff:** 1 s, 2 s, 4 s, 8 s… up to N attempts, then keep the
     session in a "pending sync" queue on the watch.
6. **When to send:** send immediately when the session ends, and/or at the start
   of the next app connection (e.g., when the watch finds the phone again).

### Sync checklist for the watch

- [ ] Same Wi-Fi / hotspot as the phone.
- [ ] Stable `id` reused across retries.
- [ ] `startTime`/`endTime` as Unix timestamps (seconds).
- [ ] `durationMinutes` > 0.
- [ ] Accept `201` and `200 duplicate` as success.
- [ ] Retry with backoff on network errors only.

---

## 8. cURL examples (for testing from a desktop)

**Check status:**

```bash
curl http://localhost:8080/api/status
```

**Send a minimal session:**

```bash
curl -X POST http://localhost:8080/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"startTime": 1785081600, "durationSeconds": 930, "temperature": 85.0, "averageHeartRate": 110, "notes": "Test"}'
```

**Send a full session with phases and samples:**

```bash
curl -X POST http://localhost:8080/api/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "id": "zepp-test-1",
    "startTime": 1785081600,
    "endTime": 1785082680,
    "durationMinutes": 18,
    "phases": [1, 2, 3],
    "heartRateSamples": [
      {"timestamp": 1785081660, "value": 85.0, "phase": 1},
      {"timestamp": 1785082200, "value": 120.0, "phase": 2}
    ]
  }'
```

---

## 9. Field aliases (parser is tolerant)

For backward compatibility the server also accepts these alternative names:

| Canonical field    | Accepted aliases          |
| ------------------ | ------------------------- |
| `startTime`        | `date`                    |
| `durationMinutes`  | `duration`                |
| `temperature`      | `temp`                    |
| `averageHeartRate` | `avgHr`, `avg_heart_rate` |
| `maxHeartRate`     | `maxHr`, `max_heart_rate` |
| `notes`            | `comment`                 |
| `phases`           | `stages`, `etapy`         |
| `heartRateSamples` | `heart_rate_samples`      |

Use the **canonical** names for new integrations.

---

## 10. Networking notes & troubleshooting

- **Same network required.** The watch and phone must be on the same LAN (or the
  watch must join the phone's hotspot).
- **Port conflicts.** The default port is `8080`. It can be changed from the app
  (**HTTP & Watch** screen → port icon). The watch must then use the new port.
- **Android emulator:** use `http://10.0.2.2:8080` to reach the host.
- **iOS simulator / local testing:** `http://127.0.0.1:8080` or
  `http://localhost:8080`.
- **Firewall:** on a desktop testing scenario, allow inbound TCP on the chosen port.
- **Server not running:** if the app was killed, the server stops too. The watch
  should retry later (see §7 backoff strategy).
- **CORS:** enabled, so browser-based tests (fetch/XHR from a web page) work.

---

## 11. Implementation reference (server-side)

- Parser: `lib/features/http_server/services/http_server_service.dart`
  (`parseWatchPayload`, `isDuplicate`, `hasDuplicate`).
- Storage: `lib/features/sessions/data/session_storage.dart`.
- Session model: `lib/features/sessions/domain/models/sauna_session.dart`.
- Phases: `lib/features/sessions/domain/models/sauna_phase.dart`.
