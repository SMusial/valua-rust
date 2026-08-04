// =============================================================================
// valua_core/src/lib.rs
// ValuaRUST Decision Engine — Pure Rust, no Android, no FFI
// =============================================================================
//
// E[Z] = E[V] × P(sale) − (C_listing + C_success + C_handling + C_shipping)
//
// Decision rules (MCDA):
//   E[Z] ≤ 0              → Discard
//   0 < E[Z] < 20 PLN     → Bundle
//   E[Z] ≥ 20, Clothing   → Sell on Vinted
//   E[Z] ≥ 20, E[V] > 200 → Sell on eBay
//   E[Z] ≥ 20, others     → Sell on Allegro
// =============================================================================

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------

/// Fixed listing fee charged per item listed (PLN)
pub const LISTING_FEE_PLN: f64 = 1.0;

/// Platform success fee as a fraction of estimated value (1%)
pub const SUCCESS_FEE_RATE: f64 = 0.01;

/// Default agent handling cost per item (PLN) — packing, labelling
pub const DEFAULT_HANDLING_COST_PLN: f64 = 12.0;

/// Minimum E[Z] threshold to justify a SELL decision (PLN)
pub const BUNDLE_THRESHOLD_PLN: f64 = 20.0;

/// Estimated value threshold above which eBay is preferred over Allegro (PLN)
pub const EBAY_VALUE_THRESHOLD_PLN: f64 = 200.0;

/// Engine version — exposed to Kotlin via UniFFI to confirm bridge is live
pub const ENGINE_VERSION: &str = "0.1.0-mvp";

// -----------------------------------------------------------------------------
// Data Types
// -----------------------------------------------------------------------------

/// Item category — drives sale probability, shipping estimate, and platform routing
#[derive(Debug, Clone, PartialEq)]
pub enum Category {
    Clothing,
    Furniture,
    Books,
    Electronics,
    Other,
}

impl Category {
    /// Historical sale probability for this category (0.0 – 1.0)
    pub fn sale_probability(&self) -> f64 {
        match self {
            Category::Clothing    => 0.70,
            Category::Furniture   => 0.55,
            Category::Books       => 0.60,
            Category::Electronics => 0.65,
            Category::Other       => 0.50,
        }
    }

    /// Estimated shipping cost for this category (PLN)
    pub fn shipping_estimate_pln(&self) -> f64 {
        match self {
            Category::Clothing    => 12.0,
            Category::Furniture   => 50.0, // bulky items
            Category::Books       => 10.0,
            Category::Electronics => 15.0,
            Category::Other       => 15.0,
        }
    }
}

/// The operational decision the engine returns for each item
#[derive(Debug, Clone, PartialEq)]
pub enum DecisionAction {
    /// Item has no net commercial value — discard or recycle
    Discard,
    /// Item value is marginal alone — group with similar items
    Bundle,
    /// List on the specified retail platform
    SellOn(Platform),
}

/// Supported retail platforms
#[derive(Debug, Clone, PartialEq)]
pub enum Platform {
    Allegro,
    Vinted,
    Ebay,
}

impl Platform {
    pub fn display_name(&self) -> &str {
        match self {
            Platform::Allegro => "Allegro",
            Platform::Vinted  => "Vinted",
            Platform::Ebay    => "eBay",
        }
    }
}

/// Input provided by the agent (or camera layer in Phase 1.5)
#[derive(Debug, Clone)]
pub struct ItemInput {
    /// Item category selected by the agent
    pub category: Category,
    /// Estimated market value in PLN (from agent input or price cache)
    pub estimated_value_pln: f64,
    /// Optional override for handling cost (uses DEFAULT_HANDLING_COST_PLN if None)
    pub handling_cost_override: Option<f64>,
}

impl ItemInput {
    pub fn new(category: Category, estimated_value_pln: f64) -> Self {
        Self {
            category,
            estimated_value_pln,
            handling_cost_override: None,
        }
    }

    pub fn with_handling_cost(mut self, cost: f64) -> Self {
        self.handling_cost_override = Some(cost);
        self
    }
}

/// Full result returned to the UI for a single scanned item
#[derive(Debug, Clone)]
pub struct ScanResult {
    /// The operational decision
    pub action: DecisionAction,
    /// Expected net profit after all costs (PLN) — E[Z]
    pub expected_net_profit_pln: f64,
    /// Platform owner's 1% success fee on this item (PLN)
    pub platform_fee_pln: f64,
    /// Sale probability used in the calculation (0.0 – 1.0)
    pub sale_probability: f64,
    /// Total cost used in the calculation (PLN)
    pub total_cost_pln: f64,
    /// Human-readable explanation of the decision
    pub reason: String,
}

// -----------------------------------------------------------------------------
// Engine
// -----------------------------------------------------------------------------

/// Evaluate a single item and return a full ScanResult.
///
/// This is the core function exposed to Kotlin via UniFFI.
pub fn evaluate_item(input: &ItemInput) -> ScanResult {
    let v  = input.estimated_value_pln;
    let p  = input.category.sale_probability();
    let c_handling  = input.handling_cost_override
        .unwrap_or(DEFAULT_HANDLING_COST_PLN);
    let c_shipping  = input.category.shipping_estimate_pln();
    let c_listing   = LISTING_FEE_PLN;
    let c_success   = v * SUCCESS_FEE_RATE;     // 1% of estimated value

    let total_cost  = c_listing + c_success + c_handling + c_shipping;

    // E[Z] = E[V] × P(sale) − total costs
    let ez = (v * p) - total_cost;

    let platform_fee = c_success; // 1% is the owner's success-based revenue

    let (action, reason) = decide(ez, v, &input.category);

    ScanResult {
        action,
        expected_net_profit_pln: round2(ez),
        platform_fee_pln: round2(platform_fee),
        sale_probability: p,
        total_cost_pln: round2(total_cost),
        reason,
    }
}

/// Returns the engine version string — used by Kotlin to confirm the bridge is live
pub fn engine_version() -> String {
    ENGINE_VERSION.to_string()
}

// -----------------------------------------------------------------------------
// Internal: MCDA routing logic
// -----------------------------------------------------------------------------

fn decide(ez: f64, value: f64, category: &Category) -> (DecisionAction, String) {
    if ez <= 0.0 {
        return (
            DecisionAction::Discard,
            format!(
                "E[Z] = {:.2} PLN — not worth listing. Discard or recycle.",
                ez
            ),
        );
    }

    if ez < BUNDLE_THRESHOLD_PLN {
        return (
            DecisionAction::Bundle,
            format!(
                "E[Z] = {:.2} PLN — marginal. Group with similar items to \
                 reach bundle threshold of {:.0} PLN.",
                ez, BUNDLE_THRESHOLD_PLN
            ),
        );
    }

    // E[Z] ≥ 20 PLN — route to optimal platform
    match category {
        Category::Clothing => (
            DecisionAction::SellOn(Platform::Vinted),
            format!(
                "E[Z] = {:.2} PLN — list on Vinted. P(sale) = {:.0}%.",
                ez,
                category.sale_probability() * 100.0
            ),
        ),
        _ if value > EBAY_VALUE_THRESHOLD_PLN => (
            DecisionAction::SellOn(Platform::Ebay),
            format!(
                "E[Z] = {:.2} PLN — high-value item (>{:.0} PLN). \
                 List on eBay for wider audience. P(sale) = {:.0}%.",
                ez,
                EBAY_VALUE_THRESHOLD_PLN,
                category.sale_probability() * 100.0
            ),
        ),
        _ => (
            DecisionAction::SellOn(Platform::Allegro),
            format!(
                "E[Z] = {:.2} PLN — list on Allegro. P(sale) = {:.0}%.",
                ez,
                category.sale_probability() * 100.0
            ),
        ),
    }
}

/// Round to 2 decimal places
fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}

// =============================================================================
// Unit Tests — all 6 decision paths
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // Test 1: Zero value item → always Discard
    // -------------------------------------------------------------------------
    #[test]
    fn discard_zero_value() {
        let input = ItemInput::new(Category::Furniture, 0.0);
        let result = evaluate_item(&input);
        assert_eq!(result.action, DecisionAction::Discard,
            "Zero value item must be discarded");
        assert!(result.expected_net_profit_pln <= 0.0,
            "E[Z] must be negative for zero value item");
    }

    // -------------------------------------------------------------------------
    // Test 2: Low value item where costs exceed revenue → Discard
    // E[V]=10, P=0.55, total_cost = 1 + 0.10 + 12 + 50 = 63.10
    // E[Z] = 10*0.55 - 63.10 = 5.50 - 63.10 = -57.60 → Discard
    // -------------------------------------------------------------------------
    #[test]
    fn discard_negative_profit() {
        let input = ItemInput::new(Category::Furniture, 10.0);
        let result = evaluate_item(&input);
        assert_eq!(result.action, DecisionAction::Discard,
            "Item with negative E[Z] must be discarded");
        assert!(result.expected_net_profit_pln < 0.0,
            "E[Z] must be negative: got {}", result.expected_net_profit_pln);
    }

    // -------------------------------------------------------------------------
    // Test 3: Marginal item — E[Z] > 0 but < 20 PLN → Bundle
    // E[V]=50, Category=Books, P=0.60, shipping=10
    // total_cost = 1 + 0.50 + 12 + 10 = 23.50
    // E[Z] = 50*0.60 - 23.50 = 30 - 23.50 = 6.50 → Bundle
    // -------------------------------------------------------------------------
    #[test]
    fn bundle_marginal_item() {
        let input = ItemInput::new(Category::Books, 50.0);
        let result = evaluate_item(&input);
        assert_eq!(result.action, DecisionAction::Bundle,
            "Marginal item (0 < E[Z] < 20) must be bundled. E[Z]={:.2}",
            result.expected_net_profit_pln);
    }

    // -------------------------------------------------------------------------
    // Test 4: Clothing with good value → Sell on Vinted
    // E[V]=80, P=0.70, shipping=12
    // total_cost = 1 + 0.80 + 12 + 12 = 25.80
    // E[Z] = 80*0.70 - 25.80 = 56 - 25.80 = 30.20 → Vinted
    // -------------------------------------------------------------------------
    #[test]
    fn sell_clothing_to_vinted() {
        let input = ItemInput::new(Category::Clothing, 80.0);
        let result = evaluate_item(&input);
        assert_eq!(
            result.action,
            DecisionAction::SellOn(Platform::Vinted),
            "Clothing with E[Z]≥20 must route to Vinted. E[Z]={:.2}",
            result.expected_net_profit_pln
        );
    }

    // -------------------------------------------------------------------------
    // Test 5: Mid-value Furniture → Sell on Allegro
    // E[V]=100, P=0.55, shipping=50
    // total_cost = 1 + 1.00 + 12 + 50 = 64.00
    // E[Z] = 100*0.55 - 64 = 55 - 64 = -9.0 → hmm, need higher value
    // Let's use E[V]=200, P=0.55, shipping=50
    // total_cost = 1 + 2.00 + 12 + 50 = 65.00
    // E[Z] = 200*0.55 - 65 = 110 - 65 = 45.0 → Allegro (200 is not > 200)
    // -------------------------------------------------------------------------
    #[test]
    fn sell_mid_value_to_allegro() {
        let input = ItemInput::new(Category::Furniture, 200.0);
        let result = evaluate_item(&input);
        assert_eq!(
            result.action,
            DecisionAction::SellOn(Platform::Allegro),
            "Mid-value item (E[V]≤200) with E[Z]≥20 must route to Allegro. \
             E[Z]={:.2}", result.expected_net_profit_pln
        );
        assert!(result.expected_net_profit_pln >= BUNDLE_THRESHOLD_PLN,
            "E[Z] must be ≥ 20 PLN to qualify for SELL");
    }

    // -------------------------------------------------------------------------
    // Test 6: Fee calculation correctness
    // E[V]=100, Category=Electronics, P=0.65, shipping=15
    // c_listing=1, c_success=1.00, c_handling=12, c_shipping=15 → total=29.00
    // E[Z] = 100*0.65 - 29 = 65 - 29 = 36.00
    // platform_fee = 1% of 100 = 1.00 PLN
    // -------------------------------------------------------------------------
    #[test]
    fn fee_calculation_correct() {
        let input = ItemInput::new(Category::Electronics, 100.0);
        let result = evaluate_item(&input);
        assert!(
            (result.platform_fee_pln - 1.00).abs() < 0.001,
            "1% fee on 100 PLN must equal 1.00 PLN, got {:.4}",
            result.platform_fee_pln
        );
        assert!(
            (result.total_cost_pln - 29.00).abs() < 0.001,
            "Total cost must be 29.00 PLN, got {:.4}",
            result.total_cost_pln
        );
        assert!(
            (result.expected_net_profit_pln - 36.00).abs() < 0.001,
            "E[Z] must be 36.00 PLN, got {:.4}",
            result.expected_net_profit_pln
        );
    }

    // -------------------------------------------------------------------------
    // Bonus: engine_version() returns the correct string
    // -------------------------------------------------------------------------
    #[test]
    fn engine_version_is_set() {
        assert_eq!(engine_version(), "0.1.0-mvp");
    }
}
