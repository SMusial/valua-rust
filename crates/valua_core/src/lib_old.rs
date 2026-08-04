

//! valua_core — Pure decision engine for ValuaRUST.
//!
//! This crate contains zero Android code, zero FFI, and zero external
//! dependencies.  It implements the E[Z] formula and MCDA routing rules
//! that determine whether a scanned item should be discarded, bundled,
//! or listed on a retail platform.
//!
//! Full logic is added in Step 2.  For now this stub lets the workspace
//! compile cleanly so you can verify the project layout before writing
//! any business logic.

/// Engine version — surfaced to the Android UI through valua_edge.
pub const VERSION: &str = "0.1.0-mvp";

/// Placeholder function — confirms the crate links correctly.
/// Replaced by the full decision function in Step 2.
pub fn engine_version() -> &'static str {
    VERSION
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_is_set() {
        assert_eq!(engine_version(), "0.1.0-mvp");
    }
}
