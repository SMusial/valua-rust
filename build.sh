#!/bin/bash
set -e

echo "🔨 Testowanie valua_core..."
cargo test -p valua_core
echo "✅ Testy przeszły"

echo "🔨 Budowanie biblioteki Rust dla Android (ARM64)..."
cargo ndk -t arm64-v8a -o ./flutter/android/app/src/main/jniLibs \
  build -p valua_edge --release
echo "✅ libvalua_edge.so → flutter/android/app/src/main/jniLibs/arm64-v8a/"

echo "🔨 Generowanie bindingów Dart..."
cd flutter
flutter_rust_bridge_codegen generate \
  --rust-root ../crates/valua_edge \
  --rust-input crate::lib \
  --dart-output flutter/lib/src/rust/
echo "✅ Bindingi Dart wygenerowane"

echo "🎉 Build zakończony — uruchom: cd flutter && flutter run"