import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/menu_data.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import '../Screens/order_summary.dart';

class DineInOrderScreen extends StatefulWidget {
  const DineInOrderScreen({Key? key}) : super(key: key);

  @override
  _DineInOrderScreenState createState() => _DineInOrderScreenState();
}

class _DineInOrderScreenState extends State<DineInOrderScreen> {
  String selectedCategory = 'Starters';
  bool showTableForm = false;
  final TextEditingController tableController = TextEditingController();
  
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dine In Order'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
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
      // Use SafeArea to avoid overflow at the bottom
      body: SafeArea(
        child: Row(
          children: [
            // Categories Sidebar - RESPONSIVE WIDTH
            Container(
              width: isSmallScreen ? screenWidth * 0.35 : 180, // Responsive width
              color: Colors.grey[100],
              child: ListView.builder(
                itemCount: MenuData.getCategories().length,
                itemBuilder: (context, index) {
                  String category = MenuData.getCategories()[index];
                  bool isSelected = category == selectedCategory;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Reduced margin
                    child: Material(
                      color: isSelected ? Colors.orange[700] : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Reduced padding
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: isSmallScreen ? 13 : 14, // Smaller font on small screens
                            ),
                            maxLines: 2, // Allow wrapping for long category names
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Menu Items or Table Form
            Expanded(
              child: showTableForm ? _buildTableForm() : _buildMenuItems(),
            ),
            
            // Order Summary Sidebar - RESPONSIVE WIDTH
            Container(
              width: isSmallScreen ? screenWidth * 0.35 : 220, // Responsive width
              color: Colors.grey[50],
              child: _buildOrderSummary(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    // Debug print to check the selected category
    print('Building menu items for category: $selectedCategory');
    
    List<MenuItem> items = MenuData.getItemsByCategory(selectedCategory);
    
    // Debug print to check if items are loaded
    print('Found ${items.length} items for $selectedCategory');
    
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategory,
            style: TextStyle(
              fontSize: 20, // Smaller font
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          Expanded(
            child: items.isEmpty 
            ? Center(child: Text('No items in this category', 
                style: TextStyle(color: Colors.grey[600], fontSize: 16)))
            : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 1 : 2, // 1 column on small screens
                childAspectRatio: isSmallScreen ? 2.0 : 1.5, // Wider cards on small screens
                crossAxisSpacing: 8, // Reduced spacing
                mainAxisSpacing: 8, // Reduced spacing
              ),
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
      child: InkWell(
        onTap: () {
          Provider.of<OrderProvider>(context, listen: false).addItem(item);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} added to order'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description != null) ...[
                const SizedBox(height: 4), // Reduced spacing
                Expanded(
                  child: Text(
                    item.description!,
                    style: TextStyle(
                      fontSize: 11, // Smaller font
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '£${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14, // Smaller font
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  Icon(
                    Icons.add_circle,
                    color: Colors.orange[700],
                    size: 20, // Smaller icon
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableForm() {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      child: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        showTableForm = false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Table Information',
                      style: TextStyle(
                        fontSize: 20, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Table Number Input
              SizedBox(
                width: isSmallScreen ? double.infinity : 300,
                child: TextFormField(
                  controller: tableController,
                  decoration: const InputDecoration(
                    labelText: 'Table Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.table_restaurant),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    orderProvider.setTableNumber(value);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment Method
              const Text('Payment Method:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Cash'),
                    selected: orderProvider.paymentMethod == 'cash',
                    onSelected: (selected) {
                      if (selected) orderProvider.setPaymentMethod('cash');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Card'),
                    selected: orderProvider.paymentMethod == 'card',
                    onSelected: (selected) {
                      if (selected) orderProvider.setPaymentMethod('card');
                    },
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Continue Button
              SizedBox(
                width: isSmallScreen ? double.infinity : 300,
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding
              color: Colors.orange[700],
              child: const Row(
                children: [
                  Icon(Icons.receipt, color: Colors.white, size: 18), // Smaller icon
                  SizedBox(width: 4), // Reduced spacing
                  Expanded(
                    child: Text(
                      'Order Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Smaller font
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orderProvider.orderItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items added',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: orderProvider.orderItems.length,
                      itemBuilder: (context, index) {
                        OrderItem orderItem = orderProvider.orderItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Reduced margin
                          child: Padding(
                            padding: const EdgeInsets.all(6), // Reduced padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        orderItem.menuItem.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12, // Smaller font
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16), // Smaller icon
                                      onPressed: () {
                                        orderProvider.removeItem(index);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 16), // Smaller icon
                                          onPressed: orderItem.quantity > 1
                                              ? () => orderProvider.updateItemQuantity(
                                                  index, orderItem.quantity - 1)
                                              : null,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Text('${orderItem.quantity}', style: const TextStyle(fontSize: 12)), // Smaller font
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 16), // Smaller icon
                                          onPressed: () => orderProvider.updateItemQuantity(
                                              index, orderItem.quantity + 1),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '£${orderItem.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                        fontSize: 12, // Smaller font
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (orderProvider.orderItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Smaller font
                    ),
                    Text(
                      '£${orderProvider.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}