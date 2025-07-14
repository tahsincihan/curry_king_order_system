import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/customer_model.dart';
import '../services/customer_provider.dart';

class CustomerLookupWidget extends StatefulWidget {
  final Function(Customer customer, CustomerAddress address)? onCustomerSelected;
  final bool showRecentCustomers;
  final String? hintText;

  const CustomerLookupWidget({
    Key? key,
    this.onCustomerSelected,
    this.showRecentCustomers = true,
    this.hintText,
  }) : super(key: key);

  @override
  _CustomerLookupWidgetState createState() => _CustomerLookupWidgetState();
}

class _CustomerLookupWidgetState extends State<CustomerLookupWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    customerProvider.searchCustomers(query);
    
    setState(() {
      _showSearchResults = query.isNotEmpty;
    });
  }

  void _selectCustomer(Customer customer) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    
    if (customer.addresses.length == 1) {
      // Single address - auto select
      final address = customer.addresses.first;
      customerProvider.selectCustomer(customer);
      customerProvider.selectAddress(address);
      
      _searchController.text = customer.displayName;
      setState(() {
        _showSearchResults = false;
      });
      
      widget.onCustomerSelected?.call(customer, address);
      
    } else if (customer.addresses.length > 1) {
      // Multiple addresses - show selection dialog
      _showAddressSelectionDialog(customer);
    } else {
      // No addresses - just select customer for name/phone
      customerProvider.selectCustomer(customer);
      _searchController.text = customer.displayName;
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  void _showAddressSelectionDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Address for ${customer.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: customer.addresses.length * 80.0,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: customer.addresses.length,
            itemBuilder: (context, index) {
              final address = customer.addresses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(address.address),
                  subtitle: Text('${address.postcode} • Used ${address.useCount} times'),
                  trailing: address == customer.mostRecentAddress
                      ? const Chip(
                          label: Text('Recent', style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    
                    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                    customerProvider.selectCustomer(customer);
                    customerProvider.selectAddress(address);
                    
                    _searchController.text = customer.displayName;
                    setState(() {
                      _showSearchResults = false;
                    });
                    
                    widget.onCustomerSelected?.call(customer, address);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
    });
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    customerProvider.clearSearchOnly();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            TextFormField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Search Customer',
                hintText: widget.hintText ?? 'Enter name or last 4 digits of phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),

            // Search Results or Recent Customers
            if (_showSearchResults) ...[
              const SizedBox(height: 8),
              _buildSearchResults(customerProvider),
            ] else if (widget.showRecentCustomers) ...[
              const SizedBox(height: 16),
              _buildRecentCustomers(customerProvider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(CustomerProvider customerProvider) {
    if (customerProvider.isSearching) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Searching customers...'),
            ],
          ),
        ),
      );
    }

    if (customerProvider.searchResults.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.search_off, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No customers found for "${customerProvider.searchQuery}"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Found ${customerProvider.searchResults.length} customers:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...customerProvider.searchResults.map((customer) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(customer.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone: ${customer.phoneNumber}'),
                  if (customer.mostRecentAddress != null)
                    Text(
                      customer.mostRecentAddress!.displayAddress,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  Text(
                    '${customer.totalOrders} orders • Last: ${_formatDate(customer.lastOrderDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: customer.addresses.length > 1
                  ? Chip(
                      label: Text('${customer.addresses.length} addresses'),
                      backgroundColor: Colors.blue[100],
                    )
                  : null,
              onTap: () => _selectCustomer(customer),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentCustomers(CustomerProvider customerProvider) {
    final recentCustomers = customerProvider.getRecentCustomers(limit: 3);
    
    if (recentCustomers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Customers:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recentCustomers.map((customer) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(customer.displayName),
              subtitle: customer.mostRecentAddress != null
                  ? Text(customer.mostRecentAddress!.displayAddress)
                  : Text('${customer.totalOrders} orders'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectCustomer(customer),
            ),
          );
        }).toList(),
      ],
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}