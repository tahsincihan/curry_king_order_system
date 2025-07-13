import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/customer_model.dart';
import '../services/customer_service.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({Key? key}) : super(key: key);

  @override
  _CustomerManagementScreenState createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _sortBy = 'recent'; // 'recent', 'frequent', 'name'

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = CustomerService.getAllCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
      _sortCustomers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_customers);
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
                 customer.phoneNumber.contains(query) ||
                 customer.addresses.any((addr) => addr.toLowerCase().contains(query));
        }).toList();
      }
    });
    _sortCustomers();
  }

  void _sortCustomers() {
    setState(() {
      switch (_sortBy) {
        case 'recent':
          _filteredCustomers.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
          break;
        case 'frequent':
          _filteredCustomers.sort((a, b) => b.orderCount.compareTo(a.orderCount));
          break;
        case 'name':
          _filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
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
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'stats':
                  _showCustomerStats();
                  break;
                case 'export':
                  _exportCustomerData();
                  break;
                case 'cleanup':
                  _showCleanupDialog();
                  break;
                case 'clear':
                  _showClearAllDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: Text('Customer Statistics'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Data'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'cleanup',
                child: Text('Cleanup Old Customers'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All Data', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers by name, phone, or address...',
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
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Sort options
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Recent'),
                      selected: _sortBy == 'recent',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortBy = 'recent';
                          });
                          _sortCustomers();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Frequent'),
                      selected: _sortBy == 'frequent',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortBy = 'frequent';
                          });
                          _sortCustomers();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Name'),
                      selected: _sortBy == 'name',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortBy = 'name';
                          });
                          _sortCustomers();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customer count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Text(
              '${_filteredCustomers.length} of ${_customers.length} customers',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No customers found matching your search'
                : 'No customers saved yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Customers will appear here after their first order',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${customer.phoneNumber}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: customer.orderCount > 1 ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${customer.orderCount} ${customer.orderCount == 1 ? 'order' : 'orders'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: customer.orderCount > 1 ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Last order: ${_formatDate(customer.lastUsed)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Since: ${DateFormat('dd/MM/yyyy').format(customer.createdAt)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (customer.postcode?.isNotEmpty == true)
                            Text(
                              'Postcode: ${customer.postcode}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editCustomer(customer),
                          tooltip: 'Edit Customer',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteCustomer(customer),
                          tooltip: 'Delete Customer',
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Addresses
                if (customer.addresses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Saved Addresses:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...customer.addresses.map((address) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(address, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editCustomer(Customer customer) {
    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => _CustomerEditDialog(
        customer: customer,
        onSaved: () {
          _loadCustomers();
        },
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await CustomerService.deleteCustomer(customer.id);
                Navigator.pop(context);
                _loadCustomers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${customer.name} deleted')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting customer: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCustomerStats() {
    final stats = CustomerService.getCustomerStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Customers: ${stats['totalCustomers'] ?? 0}'),
            Text('Repeat Customers: ${stats['repeatCustomers'] ?? 0}'),
            Text('Total Orders: ${stats['totalOrders'] ?? 0}'),
            Text('Average Orders per Customer: ${(stats['averageOrdersPerCustomer'] ?? 0.0).toStringAsFixed(1)}'),
            Text('Repeat Customer Rate: ${(stats['repeatCustomerRate'] ?? 0.0).toStringAsFixed(1)}%'),
          ],
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

  void _exportCustomerData() {
    final data = CustomerService.exportCustomerData();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Customer Data'),
        content: Text('Customer data exported successfully.\n\nTotal customers: ${data['totalCustomers']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Old Customers'),
        content: const Text('This will remove customers who have only ordered once and haven\'t ordered in the last 6 months.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await CustomerService.cleanupOldCustomers();
                Navigator.pop(context);
                _loadCustomers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Old customers cleaned up')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error during cleanup: $e')),
                  );
                }
              }
            },
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Customer Data'),
        content: const Text('Are you sure you want to delete ALL customer data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await CustomerService.clearAllCustomers();
                Navigator.pop(context);
                _loadCustomers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All customer data cleared')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing data: $e')),
                  );
                }
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

// Simple edit dialog for customer details
class _CustomerEditDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback onSaved;

  const _CustomerEditDialog({
    required this.customer,
    required this.onSaved,
  });

  @override
  _CustomerEditDialogState createState() => _CustomerEditDialogState();
}

class _CustomerEditDialogState extends State<_CustomerEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _postcodeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _postcodeController = TextEditingController(text: widget.customer.postcode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Customer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _postcodeController,
            decoration: const InputDecoration(labelText: 'Postcode'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            try {
              widget.customer.name = _nameController.text;
              widget.customer.phoneNumber = _phoneController.text;
              widget.customer.postcode = _postcodeController.text.isEmpty ? null : _postcodeController.text;
              
              await CustomerService.updateCustomer(widget.customer);
              Navigator.pop(context);
              widget.onSaved();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer updated')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating customer: $e')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}