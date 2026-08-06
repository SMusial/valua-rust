# ValuaRUST

> **Real-time item valuation and triage system for residential property clearance.**
> Built with Rust + Flutter. Designed for field agents clearing estates, apartments, and houses.

[![Phase](https://img.shields.io/badge/Phase-1%20MVP-orange)](https://github.com/SMusial/valua-rust/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-1.79+-orange)](https://rustup.rs)
[![Android](https://img.shields.io/badge/Android-13%20API%2034-green)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

---

## What is ValuaRUST?

ValuaRUST enables a field agent to walk through a residential property and triage **1,000+ items per hour**, instantly receiving one of three operational decisions per item:

| Decision | Meaning |
|---|---|
| 🔴 **DISCARD** | Net profit E[Z] ≤ 0 — not worth the handling cost |
| 🟡 **BUNDLE** | Low individual value — group with similar items |
| 🟢 **SELL** | Route automatically to Allegro / Vinted / eBay |

---

## The Decision Formula

```
E[Z] = E[V] × P(sale) − (C_listing + C_success + C_handling + C_shipping)

Where:
  E[V]        = estimated market value (PLN)
  P(sale)     = historical sale probability per category
  C_listing   = 1.00 PLN  (fixed per item)
  C_success   = 1% of E[V]
  C_handling  = 12.00 PLN (default)
  C_shipping  = per category (12–50 PLN)
```

---

## Monetisation Model

| Fee | Amount | When |
|---|---|---|
| Listing fee | **1.00 PLN** | Per item listed |
| Success fee | **1% of sale price** | Per item sold |

---

## Tech Stack

```
┌─────────────────────────────────────────┐
│         FLUTTER UI (Dart)               │
│   Android + iOS (cross-platform)        │
└─────────────────┬───────────────────────┘
                  │ flutter_rust_bridge
                  ▼
┌─────────────────────────────────────────┐
│         RUST CORE ENGINE                │
│   valua_core — E[Z] + MCDA routing      │
│   valua_edge — Flutter bridge           │
└─────────────────────────────────────────┘
```

| Layer | Technology | Purpose |
|---|---|---|
| UI | Flutter + Dart | Cross-platform mobile UI |
| Bridge | flutter_rust_bridge v2 | Rust ↔ Dart bindings |
| Decision Engine | Rust (valua_core) | E[Z] formula + MCDA rules |
| Android Build | Gradle 8.9 + AGP 8.5.2 | Android packaging |
| Target Device | Android 13, API 34, ARM64 | Redmi Note 11S tested |

---

## Project Structure

```
valua-rust/
├── crates/
│   ├── valua_core/          ← Pure Rust decision engine
│   │   └── src/lib.rs       ← E[Z] formula, MCDA rules, 7 unit tests
│   └── valua_edge/          ← Flutter bridge
│       └── src/lib.rs       ← flutter_rust_bridge exports
├── flutter/
│   └── valua_rust/          ← Flutter app (Android + iOS)
│       └── lib/main.dart    ← Full UI: categories, triage, session
├── Cargo.toml               ← Workspace root
└── build.sh                 ← One-command build script
```

---

## Quick Start

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Rust | 1.79+ | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Flutter | 3.x | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Android NDK | 26+ | Android Studio → SDK Manager → SDK Tools → NDK |
| cargo-ndk | latest | `cargo install cargo-ndk` |

### 1. Clone the repository

```bash
git clone https://github.com/SMusial/valua-rust.git
cd valua-rust
```

### 2. Run Rust unit tests

```bash
cargo test -p valua_core
```

Expected:
```
running 7 tests
test tests::discard_zero_value ... ok
test tests::discard_negative_profit ... ok
test tests::bundle_marginal_item ... ok
test tests::sell_clothing_to_vinted ... ok
test tests::sell_mid_value_to_allegro ... ok
test tests::fee_calculation_correct ... ok
test tests::engine_version_is_set ... ok

test result: ok. 7 passed; 0 failed
```

### 3. Run the Flutter app

```bash
cd flutter/valua_rust
flutter pub get
flutter run
```

---

## What You See on the Device

```
╔════════════════════════════════╗
║    ValuaRUST MVP  v0.1.0-mvp  ║
╠════════════════════════════════╣
║  Select Category:              ║
║  [👕 Clothing] [🪑 Furniture]  ║
║  [📚 Books] [📱 Electronics]   ║
║                                ║
║  Estimated value (PLN): [___]  ║
║                                ║
║       ⚡ Evaluate Item         ║
╠════════════════════════════════╣
║  🟢 SELL on Allegro            ║
║  Net profit E[Z]:   33 PLN     ║
║  Your 1% fee:        1 PLN     ║
╠════════════════════════════════╣
║  Session: 1 / 10 items         ║
╚════════════════════════════════╝
```

---

## Release History

| Tag | Description | Status |
|---|---|---|
| [`v0.2.0-flutter`](https://github.com/SMusial/valua-rust/releases/tag/v0.2.0-flutter) | Flutter MVP — Android 13, cross-platform ready | ✅ Current |
| [`v0.1.0-kotlin`](https://github.com/SMusial/valua-rust/releases/tag/v0.1.0-kotlin) | Kotlin/UniFFI MVP — Android native | ✅ Stable |
| [`v0.1.0-mvp`](https://github.com/SMusial/valua-rust/releases/tag/v0.1.0-mvp) | Initial Rust engine — all tests passing | ✅ Stable |

---

## Roadmap

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | Manual triage — Flutter UI + Rust engine | ✅ Done |
| **Phase 1.5** | Camera scanning — CameraX + ONNX YOLOv8 | 🔜 Next |
| **Phase 2** | Cloud backend — Rust/Axum + Gemini VLM | 📋 Planned |
| **Phase 3** | Retail integrations — Allegro + Vinted + OLX | 📋 Planned |
| **Phase 4** | Billing — Stripe + 1 PLN/item + 1% success fee | 📋 Planned |

---

## IP Notice

This project and all associated ideas, architecture, and code were conceived and
documented on **2026-07-22** by Sylwester Musial. All rights reserved.
This repository is private and shared for development purposes only.
