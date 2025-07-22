import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../model/customer_model.dart';
import '../services/customer_provider.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({Key? key}) : super(key: key);

  @override
  _CustomerManagementScreenState createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load all customers initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerProvider =
          Provider.of<CustomerProvider>(context, listen: false);
      setState(() {
        _filteredCustomers = customerProvider.getAllCustomers();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchCustomers(String query) {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredCustomers = customerProvider.getAllCustomers();
      } else {
        final allCustomers = customerProvider.getAllCustomers();
        _filteredCustomers = allCustomers
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                customer.phoneNumber.contains(query) ||
                customer.addresses.any((addr) =>
                    addr.address.toLowerCase().contains(query.toLowerCase()) ||
                    addr.postcode.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchCustomers('');
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
            'Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final customerProvider =
            Provider.of<CustomerProvider>(context, listen: false);
        await customerProvider.deleteCustomer(customer.id);

        // Refresh the list
        setState(() {
          _filteredCustomers = customerProvider.getAllCustomers();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${customer.name} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting customer: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Phone', customer.phoneNumber),
              _buildDetailRow('Total Orders', '${customer.totalOrders}'),
              _buildDetailRow(
                  'Total Spent', '£${customer.totalSpent.toStringAsFixed(2)}'),
              _buildDetailRow('Average Order',
                  '£${(customer.totalOrders > 0 ? customer.totalSpent / customer.totalOrders : 0).toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Last Order', _formatDate(customer.lastOrderDate)),
              const SizedBox(height: 16),
              const Text(
                'Addresses:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (customer.addresses.isEmpty)
                const Text('No addresses stored',
                    style: TextStyle(color: Colors.grey))
              else
                ...customer.addresses.map((address) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(address.address),
                        subtitle: Text(
                            '${address.postcode} • Used ${address.useCount} times'),
                        trailing: Text(
                          'Last: ${_formatDate(address.lastUsed)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final customerProvider =
                  Provider.of<CustomerProvider>(context, listen: false);
              setState(() {
                _filteredCustomers = customerProvider.getAllCustomers();
              });
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_all') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Customers'),
                    content: const Text(
                        'Are you sure you want to delete all customer data? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    final customerProvider =
                        Provider.of<CustomerProvider>(context, listen: false);
                    await customerProvider
                        .deleteCustomer(''); // This will clear all
                    setState(() {
                      _filteredCustomers = [];
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All customers cleared')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error clearing customers: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All Customers',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Customers', icon: Icon(Icons.people)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomersTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers by name, phone, or address...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: _searchCustomers,
          ),
        ),

        // Customer Count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredCustomers.length} customers${_isSearching ? ' found' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearSearch,
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),

        // Customer List
        Expanded(
          child: _filteredCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSearching ? Icons.search_off : Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching
                            ? 'No customers match your search'
                            : 'No customers stored yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (!_isSearching) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Customers will appear here when delivery orders are placed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone: ${customer.phoneNumber}'),
                            Text(
                                '${customer.totalOrders} orders • £${customer.totalSpent.toStringAsFixed(2)} total'),
                            if (customer.mostRecentAddress != null)
                              Text(
                                customer.mostRecentAddress!.displayAddress,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'view') {
                              _showCustomerDetails(customer);
                            } else if (value == 'delete') {
                              _deleteCustomer(customer);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () => _showCustomerDetails(customer),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        final stats = customerProvider.getCustomerStats();
        final allCustomers = customerProvider.getAllCustomers();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Customers',
                      '${stats['totalCustomers']}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      '${stats['totalOrders']}',
                      Icons.receipt,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Revenue',
                      '£${stats['totalSpent'].toStringAsFixed(2)}',
                      Icons.monetization_on,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Avg Order Value',
                      '£${stats['averageOrderValue'].toStringAsFixed(2)}',
                      Icons.analytics,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Top Customers
              if (allCustomers.isNotEmpty) ...[
                const Text(
                  'Top Customers by Spending',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: (allCustomers
                            .where((c) => c.totalSpent > 0)
                            .toList()
                          ..sort(
                              (a, b) => b.totalSpent.compareTo(a.totalSpent)))
                        .take(10)
                        .map((customer) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: Text('${customer.totalOrders} orders'),
                              trailing: Text(
                                '£${customer.totalSpent.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
