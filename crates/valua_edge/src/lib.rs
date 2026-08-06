mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge */

pub mod api {
    use valua_core::engine_version;
    pub use valua_core::{Category, DecisionAction, ItemInput, ScanResult};

    /// Wersja silnika — potwierdza że most Rust↔Flutter działa
    pub fn get_engine_version() -> String {
        valua_core::engine_version()
    }

    /// Główna funkcja decyzyjna — wywołana z Dart przez most
    pub fn evaluate_item(category: Category, estimated_value_pln: f64) -> ScanResult {
        let input = ItemInput {
            category,
            estimated_value_pln,
            handling_cost_override: None,
        };
        valua_core::evaluate_item(&input)
    }
}
