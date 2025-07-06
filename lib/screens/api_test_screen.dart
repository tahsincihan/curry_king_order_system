import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/postcode_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final TextEditingController _postcodeController = TextEditingController();
  late final PostcodeService postcodeService;
  
  bool _isLoading = false;
  bool _hasApiKey = false;
  String _apiKeyStatus = '';
  List<String> _testResults = [];
  List<String> _foundAddresses = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    final apiKey = dotenv.env['GETADDRESS_API_KEY'];
    postcodeService = PostcodeService(apiKey);
    
    setState(() {
      _hasApiKey = apiKey != null && apiKey.isNotEmpty;
      _apiKeyStatus = _hasApiKey 
          ? 'API Key: ${apiKey!.substring(0, 8)}...' 
          : 'No API Key Found';
    });
    
    _addTestResult('Service initialized');
    _addTestResult(_hasApiKey ? '✓ API Key loaded' : '✗ No API key in .env file');
    
    if (_hasApiKey) {
      _addTestResult('Ready to test GetAddress.io endpoints');
    } else {
      _addTestResult('⚠ Create .env file with GETADDRESS_API_KEY=your_key');
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
    });

    _addTestResult('=== TESTING ALL ENDPOINTS ===');

    try {
      final results = await postcodeService.testAllEndpoints();
      
      _addTestResult('Endpoint test completed');
      
      // Test autocomplete endpoint
      if (results['endpoints']['autocomplete'] != null) {
        final autocompleteResult = results['endpoints']['autocomplete'];
        final status = autocompleteResult['status'];
        final success = autocompleteResult['success'] ?? false;
        
        _addTestResult('--- AUTOCOMPLETE ENDPOINT ---');
        _addTestResult('Status: $status');
        _addTestResult('Result: ${success ? '✓ SUCCESS' : '✗ FAILED'}');
        
        if (autocompleteResult['url'] != null) {
          _addTestResult('URL: ${autocompleteResult['url']}');
        }
        
        if (autocompleteResult['error'] != null) {
          _addTestResult('Error: ${autocompleteResult['error']}');
        } else if (autocompleteResult['response'] != null) {
          _addTestResult('Response preview: ${autocompleteResult['response']}');
        }
      }
      
      // Test find endpoint
      if (results['endpoints']['find'] != null) {
        final findResult = results['endpoints']['find'];
        final status = findResult['status'];
        final success = findResult['success'] ?? false;
        
        _addTestResult('--- FIND ENDPOINT ---');
        _addTestResult('Status: $status');
        _addTestResult('Result: ${success ? '✓ SUCCESS' : '✗ FAILED'}');
        
        if (findResult['url'] != null) {
          _addTestResult('URL: ${findResult['url']}');
        }
        
        if (findResult['error'] != null) {
          _addTestResult('Error: ${findResult['error']}');
        } else if (findResult['response'] != null) {
          _addTestResult('Response preview: ${findResult['response']}');
        }
      }
      
      _addTestResult('=== RECOMMENDATION ===');
      bool findWorks = results['endpoints']['find']?['success'] ?? false;
      bool autocompleteWorks = results['endpoints']['autocomplete']?['success'] ?? false;
      
      if (autocompleteWorks && findWorks) {
        _addTestResult('✓ Both endpoints work - using /autocomplete as primary');
      } else if (autocompleteWorks) {
        _addTestResult('✓ Use /autocomplete endpoint (user suggested)');
      } else if (findWorks) {
        _addTestResult('✓ Use /find endpoint');
      } else {
        _addTestResult('✗ No endpoints working - check API key or account');
        _addTestResult('Visit: https://getaddress.io/admin');
      }
      
    } catch (e) {
      _addTestResult('✗ Connection test error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testPostcodeLookup() async {
    final postcode = _postcodeController.text.trim();
    
    if (postcode.isEmpty) {
      _addTestResult('✗ Please enter a postcode');
      return;
    }

    setState(() {
      _isLoading = true;
      _foundAddresses.clear();
    });

    _addTestResult('=== POSTCODE LOOKUP TEST ===');
    _addTestResult('Looking up postcode: $postcode');

    try {
      final addresses = await postcodeService.getAddresses(postcode);
      
      setState(() {
        _foundAddresses = addresses;
      });

      if (addresses.isNotEmpty) {
        _addTestResult('✓ Found ${addresses.length} addresses');
        if (addresses.first.contains('Sample Town')) {
          _addTestResult('⚠ Using mock data (API unavailable)');
        } else {
          _addTestResult('✓ Real API data returned');
        }
        
        // Show first few addresses in log
        for (int i = 0; i < addresses.length && i < 3; i++) {
          _addTestResult('  ${i + 1}. ${addresses[i]}');
        }
        if (addresses.length > 3) {
          _addTestResult('  ... and ${addresses.length - 3} more');
        }
      } else {
        _addTestResult('✗ No addresses found');
      }
    } catch (e) {
      _addTestResult('✗ Lookup error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _testPostcodeValidation() {
    final testCases = [
      'SW1A 1AA',  // Valid - Buckingham Palace
      'M1 1AA',    // Valid - Manchester
      'B33 8TH',   // Valid - Birmingham
      'W1A 0AX',   // Valid - BBC Broadcasting House
      'EC4M 7RF',  // Valid - Bank, London
      'INVALID',   // Invalid
      '12345',     // Invalid
      '',          // Invalid
      'SW1A1AA',   // Valid but no space
      'sw1a 1aa',  // Valid but lowercase
    ];

    _addTestResult('=== POSTCODE VALIDATION TEST ===');
    
    for (final testCase in testCases) {
      final isValid = postcodeService.isValidUKPostcode(testCase);
      final formatted = postcodeService.formatPostcode(testCase);
      _addTestResult('$testCase -> ${isValid ? "✓" : "✗"} (formatted: "$formatted")');
    }
  }

  Future<void> _testSpecificEndpoints() async {
    setState(() {
      _isLoading = true;
    });

    final testPostcode = 'SW1A1AA';
    _addTestResult('=== INDIVIDUAL ENDPOINT TESTS ===');
    _addTestResult('Testing with postcode: $testPostcode (Buckingham Palace)');

    // Test Autocomplete endpoint directly
    _addTestResult('--- Testing /autocomplete endpoint ---');
    try {
      final autocompleteAddresses = await postcodeService.tryAutocompleteEndpoint(testPostcode);
      if (autocompleteAddresses.isNotEmpty) {
        _addTestResult('✓ /autocomplete works! Found ${autocompleteAddresses.length} addresses');
        _addTestResult('  Sample: ${autocompleteAddresses.first}');
        if (autocompleteAddresses.first.contains('Sample Town')) {
          _addTestResult('  ⚠ Mock data returned - API may be unavailable');
        } else {
          _addTestResult('  ✓ Real data returned');
        }
      } else {
        _addTestResult('✗ /autocomplete returned no addresses');
      }
    } catch (e) {
      _addTestResult('✗ /autocomplete error: $e');
    }

    // Test Find endpoint directly
    _addTestResult('--- Testing /find endpoint ---');
    try {
      final findAddresses = await postcodeService.tryFindEndpoint(testPostcode);
      if (findAddresses.isNotEmpty) {
        _addTestResult('✓ /find works! Found ${findAddresses.length} addresses');
        _addTestResult('  Sample: ${findAddresses.first}');
        if (findAddresses.first.contains('Sample Town')) {
          _addTestResult('  ⚠ Mock data returned - API may be unavailable');
        } else {
          _addTestResult('  ✓ Real data returned');
        }
      } else {
        _addTestResult('✗ /find returned no addresses');
      }
    } catch (e) {
      _addTestResult('✗ /find error: $e');
    }

    _addTestResult('=== TEST COMPLETE ===');

    setState(() {
      _isLoading = false;
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
      _foundAddresses.clear();
    });
    _addTestResult('Results cleared');
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Setup Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Get API Key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Go to https://getaddress.io'),
              Text('• Sign up for free account'),
              Text('• Get your API key from admin panel'),
              SizedBox(height: 12),
              
              Text(
                '2. Create .env file:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Create .env file in project root'),
              Text('• Add: GETADDRESS_API_KEY=your_key_here'),
              Text('• Restart the app'),
              SizedBox(height: 12),
              
              Text(
                '3. Security:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Never commit .env to version control'),
              Text('• Add .env to .gitignore'),
              Text('• Regenerate key if exposed'),
              SizedBox(height: 12),
              
              Text(
                '4. Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Check account at getaddress.io/admin'),
              Text('• Verify remaining credits'),
              Text('• Ensure no extra spaces in .env'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GetAddress.io API Testing'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showApiKeyHelp,
            tooltip: 'API Key Help',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearResults,
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status Card
            Card(
              color: _hasApiKey ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasApiKey ? Icons.check_circle : Icons.error,
                          color: _hasApiKey ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GetAddress.io API Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_apiKeyStatus),
                    Text('Status: ${_hasApiKey ? "Ready" : "Not Configured"}'),
                    if (!_hasApiKey) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Create .env file with GETADDRESS_API_KEY=your_key',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testApiConnection,
                          child: const Text('Test Both Endpoints'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testPostcodeValidation,
                          child: const Text('Test Validation'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testSpecificEndpoints,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Test Individual Endpoints'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Postcode Lookup Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Postcode Lookup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _postcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Enter UK Postcode',
                              hintText: 'e.g., SW1A 1AA',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _testPostcodeLookup(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testPostcodeLookup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Lookup'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try test postcodes: SW1A 1AA (Buckingham Palace), M1 1AA (Manchester), B33 8TH (Birmingham)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Section
            Expanded(
              child: Row(
                children: [
                  // Test Log
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Log',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _testResults.isEmpty
                                    ? const Text('No test results yet')
                                    : ListView.builder(
                                        itemCount: _testResults.length,
                                        itemBuilder: (context, index) {
                                          final result = _testResults[index];
                                          Color textColor = Colors.black87;
                                          if (result.contains('✓')) {
                                            textColor = Colors.green[700]!;
                                          } else if (result.contains('✗')) {
                                            textColor = Colors.red[700]!;
                                          } else if (result.contains('⚠')) {
                                            textColor = Colors.orange[700]!;
                                          }
                                          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 1),
                                            child: Text(
                                              result,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                color: textColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Found Addresses
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Found Addresses',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _foundAddresses.isEmpty
                                    ? const Text('No addresses found')
                                    : ListView.builder(
                                        itemCount: _foundAddresses.length,
                                        itemBuilder: (context, index) {
                                          final address = _foundAddresses[index];
                                          final isMock = address.contains('Sample Town');
                                          
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 2),
                                            color: isMock ? Colors.orange[50] : Colors.green[50],
                                            child: ListTile(
                                              dense: true,
                                              title: Text(
                                                address,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              leading: CircleAvatar(
                                                backgroundColor: isMock ? Colors.orange : Colors.green,
                                                radius: 12,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              subtitle: isMock 
                                                  ? const Text(
                                                      'Mock Data',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.orange,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Real Data',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postcodeController.dispose();
    super.dispose();
  }
}