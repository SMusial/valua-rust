# ValuaRUST

Real-time item valuation and triage system for residential property clearance.

## Phase 1 Scope
- `valua_core` — pure Rust decision engine (E[Z] formula + MCDA routing)
- `valua_edge` — UniFFI bridge (Rust → Kotlin)
- Android UI — Jetpack Compose (manual input, Redmi Note 11S)

## Quick Start

### 1. Verify the workspace compiles
```bash
cargo build
```

### 2. Run the unit test (Step 1 stub — just confirms project layout)
```bash
cargo test -p valua_core
```

Expected:
```
running 1 test
test tests::version_is_set ... ok
test result: ok. 1 passed
```

### 3. Build for Android ARM64
```bash
cargo ndk -t arm64-v8a -o android/app/src/main/jniLibs build -p valua_edge
```

Full implementation guide: see `docs/phase1_steps.md`
