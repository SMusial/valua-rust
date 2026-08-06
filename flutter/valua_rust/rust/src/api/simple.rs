use flutter_rust_bridge::frb;

#[derive(Debug, Clone)]
pub enum Category {
    Clothing,
    Furniture,
    Books,
    Electronics,
    Other,
}

#[derive(Debug, Clone)]
pub enum DecisionAction {
    Discard,
    Bundle,
    SellOn(String),
}

#[derive(Debug, Clone)]
pub struct ScanResult {
    pub action: DecisionAction,
    pub estimated_value_pln: f64,
    pub expected_net_profit_pln: f64,
    pub sale_probability: f64,
    pub reason: String,
}

#[frb(sync)] // Makes it synchronous, remove #[frb(sync)] if you want an async Future in Dart
pub fn evaluate_item(title: String, category: Category) -> ScanResult {
    let title_lower = title.to_lowercase();

    // Basic heuristic evaluation logic
    let (est_value, prob) = match category {
        Category::Electronics => (150.0, 0.70),
        Category::Furniture => (80.0, 0.50),
        Category::Clothing => (30.0, 0.40),
        Category::Books => (15.0, 0.60),
        Category::Other => (25.0, 0.35),
    };

    let net_profit = est_value * prob - 5.0; // Subtract estimated overhead

    let (action, reason) = if net_profit <= 0.0 {
        (
            DecisionAction::Discard,
            "Niska szacowana wartość i prawdopodobieństwo sprzedaży. Zalecana utylizacja."
                .to_string(),
        )
    } else if net_profit < 20.0 {
        (
            DecisionAction::Bundle,
            "Pojedynczo mało opłacalne. Dołącz do pakietu zbiorczego.".to_string(),
        )
    } else {
        (
            DecisionAction::SellOn("Allegro / OLX".to_string()),
            format!(
                "Wysoki oczekiwany zysk (~{:.2} PLN). Zalecane wystawienie.",
                net_profit
            ),
        )
    };

    ScanResult {
        action,
        estimated_value_pln: est_value,
        expected_net_profit_pln: net_profit,
        sale_probability: prob,
        reason,
    }
}
