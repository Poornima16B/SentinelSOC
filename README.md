<div align="center">

# SentinelSOC — Open-Source Autonomous Ransomware Defense and EDR Platform

### Self-hosted. Deterministic-first. Offline-capable.

*Detect, block, and recover from ransomware and intrusions in milliseconds — 163 enabled Sigma rules + 4 chain detections covering 82 CVEs, <1 ms in-memory evaluation, no LLM in the hot path.*

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.12-blue)]()
[![Docker](https://img.shields.io/badge/docker-compose-blue)]()
[![Version](https://img.shields.io/badge/version-1.7.33-cyan)]()

[What is SentinelSOC?](#what-is-sentinelsoc) · [Install](#5-minute-install) · [Ransomware Defense](#ransomware-defense-v16) · [Detection](#detection-1111-verified) · [vs Wazuh / OSSEC / Elastic](#sentinelsoc-vs-wazuh--ossec--elastic-security) · [Architecture](#architecture) · [Docs](docs/)

</div>

---

## What is SentinelSOC?

**SentinelSOC is an open-source, self-hosted autonomous defense platform that detects ransomware, lateral movement, and intrusions in real time — without depending on a cloud AI service.**

It owns your firewall, watches your logs, runs deception honeypots, and evaluates 163 enabled Sigma rules + 4 chain detections in **<1 ms per event**. When it sees an attack — brute-force, shadow-copy delete, mass file encryption, ransom note drop, SMB lateral movement — it auto-blocks the attacker IP and writes a structured incident postmortem. Process termination and snapshot recovery are built into the platform.

The enabled count is the number of `enabled: true` files under `backend/app/rules/sigma/`. Of the 163, 42 are endpoint rules (process command lines, file, registry, DLL-load, service-install, RDP-logon and canary detections) and 8 more match outbound connections (2 port heuristics and 6 C2 indicator lists). These see events only when an **endpoint agent** (node-tauri or the Python agent) reports for the host, or, for process/file events and IOC peers, on the SentinelSOC host itself through its built-in host monitor. With no agent enrolled they evaluate nothing on your endpoints. Several sensors are opt-in builds (node-tauri's ETW/eBPF feature supplies file, registry, DLL-load and connection events; release builds send process start/stop only). Each disabled rule says in its description what agent change or external log source would revive it.

Set `AEGIS_AI_MODE=disabled` and the entire stack runs on deterministic rules and Jinja2 templates. AI enrichment is available but never required.

**Three modules:**
- **Surface** — attack-surface management (nmap + nuclei, scheduled scans, CVSS history)
- **Response** — fully autonomous incident response: confirmed threats block permanently, unconfirmed ones block *provisionally* and expire themselves (see [Autonomous Response](#autonomous-response))
- **Phantom** — deception layer (SSH honeypot on :2222, HTTP decoy on :8888, breadcrumb credential traps)

```bash
git clone https://github.com/Poornima16B/SentinelSOC.git && cd SentinelSOC
docker compose up -d
# Dashboard: http://localhost:3000 · API: http://localhost:8000
```

---

## Frequently Asked Questions

### How does SentinelSOC detect ransomware?

SentinelSOC ships **12 ransomware-specific Sigma rules + 1 kill-chain** mapped to MITRE ATT&CK techniques T1490, T1486, T1105, T1218, and T1021. The correlation engine evaluates each event in **<1 ms** using an O(1) type-indexed rule lookup.

Specific behaviors detected:
- **Shadow-copy deletion** — `vssadmin delete shadows`, `wbadmin delete catalog`, `bcdedit /set {default} recoveryenabled No`, tmutil, btrfs snapshot delete
- **Mass file encryption** — ≥50 write events/second via the Rust endpoint agent; entropy analysis (≥7.5 bits/byte)
- **Canary file trips** — 10 hidden sentinel files in Documents/Desktop/Downloads; any modification triggers an immediate critical incident
- **Ransom note drop** — filename pattern detection for `README.txt`, `HOW_TO_DECRYPT`, `RECOVER_FILES`, and 40+ known ransom note variants
- **LOLBin staging** — `certutil -urlcache`, `rundll32` abuse for payload delivery (MITRE T1105/T1218)
- **RDP-then-encrypt lateral movement** — T1021.001 RDP session followed by encryption events on the same host
- **SMB lateral movement** — T1021.002 file-share writes to remote hosts
- **WinRM remote execution** — T1021.006 `wsmprovhost.exe` spawning suspicious child processes

The **RaaS threat intel feed** (refreshed every 6 hours from RansomLook + CISA) supplies current C2 IP ranges, onion addresses, file extensions, and ransom note artifacts for known groups: LockBit, Akira, REvil, BlackCat/ALPHV, Babuk, Conti, WannaCry, and others.

### Is SentinelSOC really offline-capable?

Yes. Set `AEGIS_AI_MODE=disabled` and every AI call site falls back to a deterministic path:

| AI operation | Offline fallback |
|---|---|
| Honeypot decoy content | Jinja2 templates in `app/templates/honeypot/` |
| Incident triage and classification | MITRE rule mapper + chain heuristics |
| Counter-attack selection | Static `THREAT_TO_PLAYBOOK` lookup table |
| IP enrichment | RBL + MaxMind GeoIP-Lite (no model call) |
| Report generation | Per-type Jinja2 templates |
| Playbook selection | 6 in-code playbooks; AI selector replaced by dict |

The RaaS intel feed, Sigma rules, chain detections, and all firewall blocking continue to operate with no external API calls.

### How does SentinelSOC compare to a traditional SIEM or EDR?

See the [comparison table](#sentinelsoc-vs-wazuh--ossec--elastic-security) below. The short answer: SentinelSOC trades unlimited enterprise scale for deterministic-first detection at machine speed and zero licensing cost.

### Can I run SentinelSOC on a homelab or laptop?

Yes. SentinelSOC is tested and runs seamlessly via Docker Compose (or natively with FastAPI + Next.js). A standard laptop, Mac mini, Raspberry Pi 5, or any Linux VPS with Docker is sufficient. The Rust endpoint agent builds for macOS arm64, Linux x64, and Windows x64.

### What are the system requirements?

- Docker + Docker Compose (for the full stack)
- 2 GB RAM minimum; 4 GB recommended
- `AEGIS_REAL_FW=1` + root/sudo for real pfctl/iptables enforcement (optional — defaults to in-memory NoopFirewall)
- No external services required in offline mode

---

## Ransomware Defense — v1.6

Full ransomware defense end-to-end. Everything below ships in the open-source free tier.

### Detection (server-side, <1 ms)

12 Sigma rules cover the complete ransomware kill-chain:

| Rule | MITRE Technique | Trigger |
|---|---|---|
| `ransomware_shadow_delete` | T1490 | vssadmin / wbadmin / bcdedit / tmutil shadow-delete commands |
| `ransomware_lolbin_certutil` | T1105 | certutil -urlcache -f payload staging |
| `ransomware_lolbin_rundll32` | T1218 | rundll32 loading from temp or user-writable paths |
| `ransomware_smb_lateral` | T1021.002 | SMB writes to ≥3 remote hosts in 60 s |
| `ransomware_winrm_exec` | T1021.006 | wsmprovhost spawning cmd/powershell/wscript |
| `ransomware_rdp_then_encrypt` | T1021.001 + T1486 | RDP session → encryption events same host, 5 min window |
| `ransomware_mass_extension_change` | T1486 | ≥20 extension-change events in 5 s |
| `ransomware_canary_tripped` | T1486 | Sentinel file modified |
| `ransomware_ransom_note` | T1486 | Known ransom note filename patterns |
| `ransomware_entropy_spike` | T1486 | ≥7.5 bits/byte mean entropy on ≥50 writes/s |
| `ransomware_vss_inhibit` | T1490 | Registry: DisableAutomaticSystemRestorePoint |
| `ransomware_backup_delete` | T1490 | wbadmin delete backup / bcdedit recoveryenabled No |

**Chain rule `ransomware_chain`**: fires a CRITICAL incident when ≥3 of the above rules trigger for the same host within a 10-minute window.

### Threat Intel (RaaS feed)

- Source: RansomLook API + CISA Known Ransomware Advisories
- Refresh interval: every 6 hours (with offline cache)
- Per-group data: aliases, C2 IPs, onion addresses, known file extensions, ransom note artifacts
- Groups tracked: LockBit, Akira, REvil, BlackCat/ALPHV, Babuk, Conti, WannaCry, Locky, and 20+ others
- Cached to `backend/app/data/raas/*.json` — survives restarts

### Recovery Orchestration

```python
# Query recovery options for an incident
GET /api/v1/ransomware/recovery-options/{event_id}

# Trigger restore from snapshot
POST /api/v1/ransomware/restore

# Look up decryptors (NoMoreRansom seed)
GET /api/v1/ransomware/decryptors
```

`SnapshotManager` wraps: tmutil (macOS), btrfs/zfs (Linux), VSS via Rust agent (Windows), Noop (default).

`DecryptorLibrary` ships a NoMoreRansom seed list for: Akira, Babuk, REvil, LockBit, WannaCry, Conti, Locky, and others.

### Endpoint Agent (Rust)

The hardened Rust agent in `agent-rust/` provides:
- **Canary watcher** — filesystem notify on 10 hidden sentinel files
- **Entropy classifier** — sliding-window entropy analysis (mean ≥7.5 bits/byte at ≥50 writes/s)
- **Process killer** — forensic snapshot captured before `SIGKILL` (Linux) / `TerminateProcess` (Windows)
- **Self-protection** — `prctl(PR_SET_DUMPABLE, 0)` on Linux; `SetProcessMitigationPolicy` on Windows
- **Rollback** — calls SnapshotManager via API

#### Running the node agent without a window

The node agent (`node-tauri/`) is one binary with an optional GUI console. An endpoint sensor has to run with the screen locked, before login and on servers, so the window is not required:

```bash
sentinelsoc_node --headless          # or AEGIS_NODE_HEADLESS=1; no window, no tray. Ctrl-C to stop
sentinelsoc_node --install-service   # Windows, elevated prompt: registers service (LocalSystem, auto-start)
sentinelsoc_node --uninstall-service # Windows, elevated prompt
sc start SentinelSOCNode
```

- Headless logs to `<data dir>/logs/sentinelsoc-node.log` (rotated at 10 MB).
- Data directory: Windows GUI `%APPDATA%\sentinelsoc-node`; Windows headless/service `%ProgramData%\sentinelsoc-node` (restricted to SYSTEM and Administrators, since it holds the node token); macOS/Linux `~/.config/sentinelsoc-node` in every mode.
- As a service, ransomware canaries are seeded and watched in every real user profile under `C:\Users` (Documents, Desktop, Downloads), not in the SYSTEM profile.

### Dashboard

`/dashboard/ransomware` provides:
- RaaS group activity timeline (recharts)
- Recent ransomware events table with MITRE technique links
- Decryptor lookup widget (NoMoreRansom)
- Recovery options panel per incident

### Test Harness

```bash
AEGIS_LIVEFIRE=1 python -m pytest backend/tests/integration/test_ransomware_e2e.py -v
```

Generates 100 entropy-padded dummy files in a tempdir, drops a ransom note, races the agent. Asserts: kill within 500 ms, incident reaches API, chain rule fires, recovery snapshot available, synthetic C2 IP blocked.

---

## SentinelSOC vs Wazuh / OSSEC / Elastic Security

| Capability | SentinelSOC | Wazuh 4.x | OSSEC 3.x | Elastic Security 8.x |
|---|---|---|---|---|
| **Detection latency** | <1 ms (in-memory Sigma eval) | 5–60 s pipeline | 5–30 s | 10–60 s |
| **Action latency** | <50 ms (local pfctl/iptables) | Active response ~5 s | Active response ~5 s | Manual SOAR / hours |
| **Ransomware Sigma rules** | 12 rules + 1 kill-chain | Community rules, no kill-chain | None built-in | SIEM rules, no offline kill-chain |
| **MITRE ATT&CK mapping** | T1490/T1486/T1105/T1218/T1021 | Yes (agent) | Partial | Yes (SIEM) |
| **Offline / air-gapped** | Full (`AEGIS_AI_MODE=disabled`) | Partial | Yes | No (requires cloud) |
| **Honeypot deception** | SSH :2222 + HTTP :8888 + breadcrumbs | No | No | No |
| **Recovery orchestration** | tmutil / btrfs / zfs / VSS | No | No | No |
| **RaaS threat intel** | RansomLook + CISA, every 6 h | No | No | Threat intel subscriptions (paid) |
| **Self-hosted** | Yes, Docker Compose | Yes, complex stack | Yes, C agent | Self-managed or Elastic Cloud |
| **Deployment complexity** | `docker compose up -d` (~3 min) | Multi-node agent rollout | Manual C agent install | Weeks, requires Elasticsearch |
| **AI / LLM dependency** | Optional (`AEGIS_AI_MODE=disabled`) | None | None | Hard requirement for ML features |
| **Cost** | Free, AGPL-3.0 | Free, GPL-2.0 | Free, GPL-2.0 | Free tier limited; Elastic Cloud $$$$ |
| **Rust endpoint agent** | Yes (EDR + entropy + canary) | C agent | C agent | Elastic agent (Go) |
| **Deception / breadcrumb traps** | Yes | No | No | No |

**Where SentinelSOC wins**: solo operators, indie SaaS teams, and homelabs that need deterministic ransomware kill-chain detection with sub-50 ms automated blocking and zero per-seat licensing. `docker compose up -d` and you have rules + honeypots + firewall enforcement in 3 minutes.

**Where to choose Wazuh/Elastic instead**: large multi-site enterprise deployments, regulated environments requiring Magic-Quadrant vendor relationships, or teams with dedicated SOC staff.

---

## Detection: 11/11 Verified

Every detection capability tested against real attack patterns:

| # | Attack Vector | Detection Layer | Response | Result |
|---|--------------|----------------|----------|--------|
| 1 | SQL Injection (UNION, blind, error-based) | L1: Middleware regex + double URL-decode | Auto-block IP | PASS |
| 2 | XSS (reflected, stored, DOM) | L1: Middleware + L2: Log watcher | Auto-block IP | PASS |
| 3 | Path Traversal (`../`, `%2e%2e`) | L1: Middleware | Auto-block IP | PASS |
| 4 | Command Injection (`;cat`, `$(...)`) | L1: Middleware | Auto-block IP | PASS |
| 5 | SSH Brute Force (5+ failures/5 min) | L3: Sigma rule + honeypot capture | Auto-block + attacker profile | PASS |
| 6 | Port Scan (10+ ports/60 s) | L2: Log watcher + L3: Correlation | Auto-block IP | PASS |
| 7 | Scanner Detection (nmap, sqlmap, nikto) | L1: User-Agent + probe paths | Auto-block IP | PASS |
| 8 | Breadcrumb Trap (stolen honeypot creds) | Phantom → L1: Middleware chain | Critical incident + block | PASS |
| 9 | Lateral Movement (10+ internal hops) | L3: Sigma chain rule + campaign tracker | Isolate host (autonomous) | PASS |
| 10 | C2 Beacon (periodic callbacks) | Entropy analysis (Renyi) | Auto-respond | PASS |
| 11 | Credential Stuffing (distributed) | L3: Correlation sliding window | Auto-block + feed report | PASS |

---

## 5-Minute Install

**Prerequisites:** Docker and Docker Compose.

```bash
git clone https://github.com/Poornima16B/SentinelSOC.git
cd SentinelSOC

# Configure
cp .env.example .env
# Edit .env — set AEGIS_SECRET_KEY, AEGIS_ADMIN_PASSWORD and POSTGRES_PASSWORD at minimum
# OPENROUTER_API_KEY is optional; omit it and SentinelSOC runs fully offline

# Launch
docker compose up -d

# Dashboard at http://localhost:3000
# API at http://localhost:8000
```

No default credentials. The setup wizard at `/setup` walks you through creating your admin account.

### What Gets Deployed

| Container | Port | Purpose |
|---|---|---|
| `sentinelsoc-api` | 8000 | FastAPI backend (140+ endpoints, 25 API routers) |
| `sentinelsoc-frontend` | 3000 | Next.js 14 dashboard (21 pages, real-time WebSocket) |
| `sentinelsoc-db` | 5432 | PostgreSQL 16 |
| `sentinelsoc-redis` | 6379 | Redis event bus and cache |

### Manual Installation

```bash
# Backend
cd backend && pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Frontend
cd frontend && npm install && npm run build && npm start
```

### Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `AEGIS_REAL_FW` | unset | Set to `1` to enable real pfctl/iptables enforcement |
| `AEGIS_AI_MODE` | `optional` | `required` / `optional` / `disabled` — gates every AI call site. `optional` tries AI and falls back to deterministic logic on failure; `disabled` never calls out. |
| `AEGIS_REAL_RECOVERY` | unset | Set to `1` to enable real snapshot restore |
| `AEGIS_LIVEFIRE` | unset | Set to `1` to run the ransomware emulation harness |
| `AEGIS_FIREWALL_URL` | unset | Optional remote firewall agent URL |
| `AEGIS_FIREWALL_SECRET` | unset | Shared secret for backend <-> firewall agent channel |
| `AEGIS_SAFE_IPS` | `127.0.0.1,::1,localhost` | IPs/CIDRs never blocked and never turned into an incident |
| `AEGIS_BLOCKS_PERMANENT` | unset | Set to `1` to make every block permanent without provisional expiry |
| `AEGIS_PROVISIONAL_BLOCK_TTL_HOURS` | `6` | Base lifetime of an ambiguous (provisional) auto-block |
| `AEGIS_FULL_SCAN_HOURS` | `8` | Full nmap + nuclei scan interval |
| `AEGIS_DOS_MODE` | `monitor` | `monitor` (detect only) or `active` (enforce) |
| `AEGIS_DOS_PER_IP_RPS` | `10` | Per-source request-rate ceiling |

---

## Autonomous Response

SentinelSOC is built to run unattended, so it does not hold decisions for an operator. An approval queue on an unwatched system is not caution — it is an attacker walking free while rows accumulate in a dashboard nobody is reading.

What replaces human review is **reversibility, not confidence**:

| Verdict | Trigger | Block |
|---|---|---|
| **Confirmed** | known-bad IOC, named exploit class, counted brute force, classified high-severity | permanent |
| **Provisional** | anything triage could not classify | executes immediately, **auto-expires** after `AEGIS_PROVISIONAL_BLOCK_TTL_HOURS` (default 6) |

A confirmed attack is a judgement the system can stand behind indefinitely. An unconfirmed one is a guess, and a guess made with nobody watching has to be able to undo itself. A genuinely hostile source re-offends and is re-blocked — usually with the evidence to confirm it permanently the second time. A false positive clears on its own instead of quietly locking a real user out forever.

The `expire_provisional_blocks` job runs every 10 minutes and is the only thing that undoes an autonomous mistake. **Safe IPs are never blocked at all**, by either path — they short-circuit in the guardrail before any verdict is reached.

---

## Architecture

### Detection Pipeline

```
Incoming Event
     |
[Layer 1] Attack Detector Middleware ──────────── runs on EVERY request
     |     6 regex categories + double URL-decode + breadcrumb detection
     |     Auto-block after 3 attacks/IP (5 min sliding window, <1 ms detection)
     |
[Layer 2] Log Watcher ────────────────────────── PM2/journalctl log tail
     |     7 security patterns, brute-force tracker, rate limiter
     |
[Layer 3] Sigma Correlation Engine ───────────── event correlation
     |     163 enabled Sigma rules + 4 chain rules + campaign tracker
     |     O(1) type-indexed lookup, 10K event sliding window
     |
[Layer 4] Response Engine (dual-mode) ──────────── classification + decision
     |     Fast path: Sigma → IOC cache → Playbook → done (<1 ms)
     |     AI path: triage → classify → incident → actions (2–5 s, optional)
     |     MITRE ATT&CK mapping on every incident
     |
[Layer 5] Auto-Response ──────────────────────── execution
          10 deterministic playbooks (<50 ms each)
          Verdict: confirmed → permanent block | unconfirmed → provisional (self-expiring)
          Guardrails gate each action type; safe IPs short-circuit before any verdict
          Three-layer blocking: external agent → FastAPI 403 → local pfctl/iptables
```

### System Overview

```
+-------------+     +---------------+     +----------------+
|   Desktop   |     |   Dashboard   |     |   Node Agent   |
|   Manager   |     |   (Next.js)   |     |  (Tauri+Rust)  |
|   (Tauri)   |     |   Port 3000   |     |   Per-host     |
+------+------+     +-------+-------+     +-------+--------+
       |                    |                      |
       +---------+----------+----------------------+
                 |
          REST API + WebSocket (real-time push)
                 |
+----------------+------------------+
|    SentinelSOC Backend (FastAPI)  |
|            Port 8000              |
|  +---------+  +----------+       |
|  | Surface |  | Response |       |
|  |  (ASM)  |  |  (SOAR)  |       |
|  +---------+  +----------+       |
|  +---------+  +----------+       |
|  | Phantom |  | Ransomware|      |
|  | (Decoy) |  | Defense  |       |
|  +---------+  +----------+       |
+----------+-----------+-----------+
           |
+----------+--+
| PostgreSQL  |
|   (data)    |
+-------------+
```

### Data Flow

```
PM2/System Logs  → Log Watcher  → Sigma Engine  → Response Actions  → Audit Log
nmap/nuclei      → Scheduler    → Assets DB     → Risk Score
Honeypots        → Interactions → Attacker Profiler → Threat Intel
RaaS Feed        → Intel Cache  → Correlation Engine → Block/Alert
Rust Agent       → Events       → Chain Detection → Kill-chain response
```

---

## Modules

### Surface — Attack Surface Management
Continuous discovery and vulnerability assessment.
- **Asset Discovery** — nmap service detection with OS fingerprinting (`-sV -O`)
- **Vulnerability Scanning** — Nuclei integration with deterministic risk scoring
- **Hardening Checks** — Configuration audits with actionable remediation
- **Scheduled Scans** — Full scan (2 h), quick scan (30 min), discovery (1 h)

### Response — Autonomous Incident Response (SOAR)
Deterministic-first alert triage with automated action execution.
- **<1 ms Fast Path** — Sigma check → IOC cache → playbook → done, no AI round-trip
- **10 Deterministic Playbooks** — `auto_block_brute_force`, `auto_block_sql_injection`, `auto_respond_c2_beacon`, `ransomware_kill_chain_response`, and 6 more
- **Guardrail System** — Per-action-type policy (`auto_approve` / `require_approval` / `never_auto`) plus a safe-IP short-circuit that no verdict can override
- **Full Audit Trail** — Every decision logged: reasoning, confidence, timestamp, action taken

### Phantom — Honeypot Deception
Deploy decoy services that attract, profile, and trap attackers.
- **SSH Honeypot** (port 2222) — Paramiko server with fake banner, captures credentials and commands
- **HTTP Honeypot** (port 8888) — Rotating decoy pages: Jenkins, WordPress, phpMyAdmin
- **Breadcrumb Traps** — Fake `.env` files with tracked credentials; attacker reuses them → CRITICAL incident

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Python 3.12, FastAPI, SQLAlchemy async, APScheduler |
| Frontend | Next.js 14, TypeScript, Tailwind CSS, Recharts |
| Database | PostgreSQL 16 (asyncpg), Redis (cache/pubsub) |
| Threat Intel | RansomLook, CISA, Spamhaus, Tor exit list, MaxMind GeoIP-Lite |
| Desktop | Tauri v2, Rust |
| Endpoint Agent | Rust (tokio, notify, sysinfo) |
| Scanning | nmap, Nuclei |
| Deception | Paramiko (SSH), aiohttp (HTTP), Jinja2 templates |
| Containers | Docker Compose |
| AI (optional) | OpenRouter (claude-opus, sonnet, 5+ free models) |

---

## Project Structure

```
SentinelSOC/
├── backend/                    # FastAPI application
│   ├── app/
│   │   ├── api/                # 25 API routers (140+ endpoints)
│   │   ├── core/               # Auth, events, guardrails, attack detector, firewall engine
│   │   ├── models/             # SQLAlchemy models
│   │   ├── modules/
│   │   │   ├── surface/        # ASM: discovery, nuclei, risk scoring
│   │   │   ├── response/       # SOAR: ingestion, analysis, playbooks, responder
│   │   │   └── phantom/        # Deception: SSH/HTTP honeypots, profiler, rotation
│   │   ├── rules/              # 229 Sigma rule files (163 enabled) + 4 chain rules (YAML)
│   │   │   ├── sigma/          # Categorized by MITRE tactic
│   │   │   └── chains/         # Kill-chain detection rules
│   │   └── services/           # Background services: log_watcher, raas_intel, correlation_engine
│   └── tests/                  # pytest suite (125 Python tests)
├── frontend/                   # Next.js 14 dashboard (21 pages)
│   └── src/app/dashboard/
│       └── ransomware/         # RaaS timeline, events, decryptor lookup
├── agent-rust/                 # Standalone Rust EDR agent
│   └── src/ransomware/         # Canary, entropy, killer, rollback
├── desktop-tauri/              # SentinelSOC Manager desktop app (Tauri v2)
├── docs/                       # Documentation
├── .well-known/
│   └── llms.txt                # LLM-discoverable site structure
├── docker-compose.yml
└── .env.example
```

---

## API Reference

All endpoints under `/api/v1/` require `X-API-Key` header or JWT Bearer token.

| Router | Description |
|---|---|
| `auth` | Register, login, JWT, RBAC (admin/analyst/viewer) |
| `surface` | Scans, assets, vulnerabilities, hardening |
| `response` | Incidents, actions, guardrails, analysis |
| `phantom` | Honeypots, interactions, attacker profiles |
| `correlation` | Sigma rules, chain detection, campaigns |
| `ransomware` | Kill-chain events, recovery options, decryptors |
| `nodes` | Endpoint agent enrollment, heartbeat, events |
| `threats` | IOC search, threat feeds, STIX export |
| `ask` | Natural language queries to the rule engine |

WebSocket at `/ws` for real-time event streaming.

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) for our responsible disclosure policy.

---

## License

SentinelSOC is licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0).

---

<div align="center">

Built with ❤️ · [SentinelSOC](https://github.com/Poornima16B/SentinelSOC) · AGPL-3.0

</div>
