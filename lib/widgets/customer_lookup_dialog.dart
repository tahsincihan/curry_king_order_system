import 'package:flutter/material.dart';
import '../model/customer_model.dart';
import '../services/customer_service.dart';

class CustomerLookupDialog extends StatefulWidget {
  final Function(Customer customer, String selectedAddress) onCustomerSelected;

  const CustomerLookupDialog({
    Key? key,
    required this.onCustomerSelected,
  }) : super(key: key);

  @override
  _CustomerLookupDialogState createState() => _CustomerLookupDialogState();
}

class _CustomerLookupDialogState extends State<CustomerLookupDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _searchResults = [];
  List<Customer> _recentCustomers = [];
  bool _isSearching = false;
  bool _showingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentCustomers() {
    setState(() {
      _recentCustomers = CustomerService.getRecentCustomers(limit: 10);
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showingRecent = true;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showingRecent = false;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text.trim() == query) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    final results = CustomerService.searchCustomers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.people_outline, size: 28, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Customer Lookup',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or last 4 digits of phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 16),

            // Results header
            Row(
              children: [
                Text(
                  _showingRecent 
                      ? 'Recent Customers (${_recentCustomers.length})'
                      : _isSearching
                          ? 'Searching...'
                          : 'Search Results (${_searchResults.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                if (_showingRecent && _recentCustomers.isNotEmpty) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _showFrequentCustomers();
                    },
                    child: const Text('Show Frequent'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Results list
            Expanded(
              child: _buildResultsList(),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search by customer name or last 4 digits of phone number to find saved addresses.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
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

  Widget _buildResultsList() {
    final customers = _showingRecent ? _recentCustomers : _searchResults;

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showingRecent ? Icons.history : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showingRecent 
                  ? 'No recent customers found.\nCustomers will appear here after their first order.'
                  : 'No customers found.\nTry a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Phone: ${customer.phoneNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${customer.orderCount} ${customer.orderCount == 1 ? 'order' : 'orders'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(customer.lastUsed),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (customer.addresses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Saved Addresses:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              ...customer.addresses.map((address) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () {
                    widget.onCustomerSelected(customer, address);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, 
                               color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, 
                               color: Colors.green, size: 16),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No saved addresses for this customer',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFrequentCustomers() {
    setState(() {
      _recentCustomers = CustomerService.getFrequentCustomers(limit: 10);
      _showingRecent = true;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}

// Helper function to show the dialog
Future<void> showCustomerLookupDialog({
  required BuildContext context,
  required Function(Customer customer, String selectedAddress) onCustomerSelected,
}) {
  return showDialog(
    context: context,
    builder: (context) => CustomerLookupDialog(
      onCustomerSelected: onCustomerSelected,
    ),
  );
}