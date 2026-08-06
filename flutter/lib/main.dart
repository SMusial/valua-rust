import 'package:flutter/material.dart';

void main() {
  runApp(const ValuaRustApp());
}

const int kSessionLimit = 10;
const double kPlatformFeePercent = 0.01;
const double kListingFeePln = 1.0;

enum ItemCategory { clothing, furniture, books, electronics, other }

extension ItemCategoryExt on ItemCategory {
  String get label => switch (this) {
    ItemCategory.clothing => 'Odzież',
    ItemCategory.furniture => 'Meble',
    ItemCategory.books => 'Książki',
    ItemCategory.electronics => 'Elektronika',
    ItemCategory.other => 'Inne',
  };
  String get emoji => switch (this) {
    ItemCategory.clothing => '👕',
    ItemCategory.furniture => '🪑',
    ItemCategory.books => '📚',
    ItemCategory.electronics => '📱',
    ItemCategory.other => '📦',
  };
}

class ScanResult {
  final String action;
  final String platform;
  final double estimatedValuePln;
  final double expectedNetProfitPln;
  final double saleProbability;
  final String reason;
  ScanResult({
    required this.action,
    required this.platform,
    required this.estimatedValuePln,
    required this.expectedNetProfitPln,
    required this.saleProbability,
    required this.reason,
  });
}

ScanResult evaluateItem(ItemCategory category, double estimatedValue) {
  const double handlingCost = 12.0;
  const double listingFee = 1.0;
  final shippingCost = switch (category) {
    ItemCategory.clothing => 12.0,
    ItemCategory.furniture => 50.0,
    ItemCategory.books => 12.0,
    ItemCategory.electronics => 20.0,
    ItemCategory.other => 15.0,
  };
  final saleProbability = switch (category) {
    ItemCategory.clothing => 0.75,
    ItemCategory.furniture => 0.55,
    ItemCategory.books => 0.45,
    ItemCategory.electronics => 0.70,
    ItemCategory.other => 0.40,
  };
  final successFee = estimatedValue * 0.01;
  final totalCosts = listingFee + successFee + handlingCost + shippingCost;
  final expectedProfit = (estimatedValue * saleProbability) - totalCosts;
  String action;
  String platform;
  String reason;
  if (expectedProfit <= 0) {
    action = 'DISCARD';
    platform = '';
    reason =
        'E[Z] = ${expectedProfit.toStringAsFixed(2)} PLN — koszt obsługi przewyższa wartość.';
  } else if (expectedProfit < 20.0) {
    action = 'BUNDLE';
    platform = '';
    reason =
        'E[Z] = ${expectedProfit.toStringAsFixed(2)} PLN — zbyt niska wartość, spakuj z innymi.';
  } else if (category == ItemCategory.clothing) {
    action = 'SELL';
    platform = 'Vinted';
    reason =
        'E[Z] = ${expectedProfit.toStringAsFixed(2)} PLN — odzież najlepiej na Vinted.';
  } else if (estimatedValue > 200.0) {
    action = 'SELL';
    platform = 'eBay';
    reason =
        'E[Z] = ${expectedProfit.toStringAsFixed(2)} PLN — wysoka wartość, kieruj na eBay.';
  } else {
    action = 'SELL';
    platform = 'Allegro';
    reason =
        'E[Z] = ${expectedProfit.toStringAsFixed(2)} PLN — optymalna platforma: Allegro.';
  }
  return ScanResult(
    action: action,
    platform: platform,
    estimatedValuePln: estimatedValue,
    expectedNetProfitPln: expectedProfit,
    saleProbability: saleProbability,
    reason: reason,
  );
}

class ValuaRustApp extends StatelessWidget {
  const ValuaRustApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValuaRUST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  int _sessionCount = 0;
  bool _sessionComplete = false;
  ItemCategory? _selectedCategory;
  final _valueController = TextEditingController();
  ScanResult? _result;

  void _evaluate() {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (_selectedCategory == null || value == null) return;
    final result = evaluateItem(_selectedCategory!, value);
    setState(() {
      _result = result;
      _sessionCount++;
      if (_sessionCount >= kSessionLimit) _sessionComplete = true;
    });
  }

  void _resetSession() {
    setState(() {
      _sessionCount = 0;
      _sessionComplete = false;
      _result = null;
      _selectedCategory = null;
      _valueController.clear();
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionComplete) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'Sesja zakończona!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Przeskanowano $_sessionCount przedmiotów',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _resetSession,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Nowa sesja',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ValuaRUST',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'v0.1.0-mvp',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_sessionCount / $kSessionLimit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildValueInput(),
            const SizedBox(height: 16),
            _buildEvaluateButton(),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildDecisionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _sessionCount / kSessionLimit;
    final color = progress < 0.5
        ? Colors.green
        : progress < 0.8
        ? Colors.orange
        : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sesja: $_sessionCount / $kSessionLimit',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              '${kSessionLimit - _sessionCount} pozostało',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategoria przedmiotu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemCategory.values.map((cat) {
                return FilterChip(
                  label: Text('${cat.emoji} ${cat.label}'),
                  selected: _selectedCategory == cat,
                  onSelected: (_) => setState(() {
                    _selectedCategory = cat;
                    _result = null;
                  }),
                  selectedColor: const Color(0xFFE65100).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFE65100),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueInput() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Szacowana wartość',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                suffixText: 'PLN',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluateButton() {
    final enabled =
        _selectedCategory != null &&
        _valueController.text.isNotEmpty &&
        _sessionCount < kSessionLimit;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: enabled ? _evaluate : null,
        icon: const Icon(Icons.bolt),
        label: const Text(
          'Oceń przedmiot',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDecisionCard() {
    final r = _result!;
    final isDiscard = r.action == 'DISCARD';
    final isBundle = r.action == 'BUNDLE';
    final cardColor = isDiscard
        ? const Color(0xFFFFEBEE)
        : isBundle
        ? const Color(0xFFFFF8E1)
        : const Color(0xFFE8F5E9);
    final accentColor = isDiscard
        ? Colors.red
        : isBundle
        ? Colors.orange
        : Colors.green;
    final emoji = isDiscard
        ? '🔴'
        : isBundle
        ? '🟡'
        : '🟢';
    final decisionText = isDiscard
        ? 'WYRZUĆ'
        : isBundle
        ? 'PAKIET ZBIORCZY'
        : 'SPRZEDAJ na ${r.platform}';
    final agentPayout = r.expectedNetProfitPln * kPlatformFeePercent;
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    decisionText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _metricRow(
              'Szacowana wartość',
              '${r.estimatedValuePln.toStringAsFixed(2)} PLN',
            ),
            _metricRow(
              'Zysk netto E[Z]',
              '${r.expectedNetProfitPln.toStringAsFixed(2)} PLN',
              bold: true,
              color: accentColor,
            ),
            _metricRow(
              'Opłata platformy',
              '${(r.estimatedValuePln * kPlatformFeePercent + kListingFeePln).toStringAsFixed(2)} PLN',
            ),
            _metricRow(
              'Twój zarobek (1%)',
              '${agentPayout.toStringAsFixed(2)} PLN',
              color: Colors.blue,
            ),
            _metricRow(
              'P(sprzedaży)',
              '${(r.saleProbability * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                r.reason,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
