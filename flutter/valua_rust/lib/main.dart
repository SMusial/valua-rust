import 'package:flutter/material.dart';
import 'package:valua_rust/src/rust/api/simple.dart';
import 'package:valua_rust/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValuaRUST',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScanResult? _result;
  String _status = 'Ready to evaluate item';

  Future<void> _runEvaluation() async {
    try {
      final res = evaluateItem(
        title: 'Vintage Wooden Chair',
        category: Category.furniture,
      );
      setState(() {
        _result = res;
        _status = 'Evaluation completed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error calling Rust: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ValuaRUST Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 72,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_result != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Value: ${_result!.estimatedValuePln} PLN',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Expected Net Profit: ${_result!.expectedNetProfitPln} PLN'),
                        Text('Sale Probability: ${(_result!.saleProbability * 100).toStringAsFixed(1)}%'),
                        Text('Reason: ${_result!.reason}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _runEvaluation,
                icon: const Icon(Icons.flash_on),
                label: const Text('Run Item Evaluation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
