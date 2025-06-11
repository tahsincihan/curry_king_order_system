import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/menu_data.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import '../Screens/order_summary.dart';
import '../Screens/menu_item_screen.dart';

class DineInOrderScreen extends StatefulWidget {
  const DineInOrderScreen({Key? key}) : super(key: key);

  @override
  _DineInOrderScreenState createState() => _DineInOrderScreenState();
}

class _DineInOrderScreenState extends State<DineInOrderScreen> {
  String selectedCategory = 'Starters';
  bool showTableForm = false;
  bool showSearch = false;
  final TextEditingController tableController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<MenuItem> searchResults = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).setOrderType('dine-in');
    });
  }

  @override
  void dispose() {
    tableController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        showSearch = false;
      });
      return;
    }

    setState(() {
      showSearch = true;
      searchResults = MenuData.getAllMenuItems()
          .where((item) => 
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              (item.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    // Check if there are items in the cart
    if (orderProvider.orderItems.isNotEmpty) {
      // Show confirmation dialog
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Discard Order?'),
            content: const Text('Are you sure you want to dismiss this order? All items will be lost.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Don't discard (cancel)
                },
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Clear the cart and return to home
                  orderProvider.clearOrder();
                  Navigator.of(context).pop(true); // Discard order
                },
                child: const Text('DISCARD', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
      return shouldPop ?? false;
    }
    
    return true; // If no items in cart, allow back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dine In Order'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  showSearch = !showSearch;
                  if (!showSearch) {
                    searchController.clear();
                    searchResults.clear();
                  }
                });
              },
            ),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restaurant_menu),
                      onPressed: () {
                        if (orderProvider.orderItems.isNotEmpty) {
                          setState(() {
                            showTableForm = true;
                          });
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add items to order first')),
                            );
                          }
                        }
                      },
                    ),
                    if (orderProvider.totalItems > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${orderProvider.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: showTableForm 
            ? _buildTableForm() 
            : _buildCategoryAndMenuScreen(),
      ),
    );
  }

  Widget _buildCategoryAndMenuScreen() {
    return Column(
      children: [
        // Search bar
        if (showSearch) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search dishes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _performSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: _performSearch,
            ),
          ),
        ],
        
        // Horizontal category list (hidden when searching)
        if (!showSearch) ...[
          Container(
            height: 48,
            color: Colors.orange[50],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MenuData.getCategories().length,
              itemBuilder: (context, index) {
                String category = MenuData.getCategories()[index];
                bool isSelected = category == selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange[700] : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.orange[700]! : Colors.grey[400]!,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        
        // Category title and items
        Expanded(
          child: showSearch ? _buildSearchResults() : _buildMenuItems(),
        ),
        
        // Order summary footer
        _buildOrderSummaryFooter(),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              searchResults.isEmpty 
                  ? searchController.text.isEmpty 
                      ? 'Enter a search term'
                      : 'No dishes found'
                  : '${searchResults.length} dishes found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: searchResults.isEmpty 
                ? Center(
                    child: Text(
                      searchController.text.isEmpty 
                          ? 'Start typing to search for dishes'
                          : 'No dishes match your search',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      MenuItem item = searchResults[index];
                      return _buildMenuItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    List<MenuItem> items = MenuData.getItemsByCategory(selectedCategory);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              selectedCategory,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty 
            ? Center(child: Text('No items in this category', 
                style: TextStyle(color: Colors.grey[600], fontSize: 16)))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  MenuItem item = items[index];
                  return _buildMenuItem(item);
                },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: InkWell(
        onTap: () {
          // Navigate to detail screen instead of directly adding
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuItemDetailScreen(menuItem: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Category (shown in search results)
                    if (showSearch) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    // Description if available
                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 4),
                    
                    // Price - Show dine-in price (which is the main price)
                    Text(
                      '£${item.getDineInPrice().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Add button
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryFooter() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.orderItems.isEmpty) {
          return const SizedBox.shrink(); // No footer if cart is empty
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Order summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${orderProvider.totalItems} ${orderProvider.totalItems == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '£${orderProvider.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // View order button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showTableForm = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'View Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          showTableForm = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Table Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Order summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...orderProvider.orderItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.menuItem.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      if (item.specialInstructions != null)
                                        Text(
                                          'Note: ${item.specialInstructions}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '£${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    orderProvider.removeItem(
                                      orderProvider.orderItems.indexOf(item)
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '£${orderProvider.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Table Number Input
                const Text(
                  'Table Number:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: tableController,
                  decoration: InputDecoration(
                    labelText: 'Enter Table Number *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.table_restaurant),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    orderProvider.setTableNumber(value);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Payment Method
                const Text(
                  'Payment Method:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Cash'),
                        selected: orderProvider.paymentMethod == 'cash',
                        onSelected: (selected) {
                          if (selected) orderProvider.setPaymentMethod('cash');
                        },
                        labelStyle: TextStyle(
                          color: orderProvider.paymentMethod == 'cash'
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Card'),
                        selected: orderProvider.paymentMethod == 'card',
                        onSelected: (selected) {
                          if (selected) orderProvider.setPaymentMethod('card');
                        },
                        labelStyle: TextStyle(
                          color: orderProvider.paymentMethod == 'card'
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: tableController.text.isNotEmpty ? () async {
                      if (mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderSummaryScreen(),
                          ),
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Review Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}