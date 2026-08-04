//! build.rs for valua_edge
//!
//! UniFFI needs to run at build time to generate the C scaffolding that
//! Kotlin will call.  This single line is all that is required.
fn main() {
    uniffi::uniffi_bindgen_main()
}
