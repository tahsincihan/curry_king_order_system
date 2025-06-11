import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/menu_data.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import '../Screens/order_summary.dart';

class TakeawayOrderScreen extends StatefulWidget {
  const TakeawayOrderScreen({Key? key}) : super(key: key);

  @override
  _TakeawayOrderScreenState createState() => _TakeawayOrderScreenState();
}

class _TakeawayOrderScreenState extends State<TakeawayOrderScreen> {
  String selectedCategory = 'Starters';
  bool showCustomerForm = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).setOrderType('takeaway');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takeaway Order'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      if (orderProvider.orderItems.isNotEmpty) {
                        setState(() {
                          showCustomerForm = true;
                        });
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add items to cart first')),
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
              width: isSmallScreen ? screenWidth * 0.30 : 140, // Reduced width
              color: Colors.grey[100],
              child: ListView.builder(
                itemCount: MenuData.getCategories().length,
                itemBuilder: (context, index) {
                  String category = MenuData.getCategories()[index];
                  bool isSelected = category == selectedCategory;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), // Minimal margin
                    child: Material(
                      color: isSelected ? Colors.orange[600] : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Minimal padding
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12, // Smaller font
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Menu Items
            Expanded(
              child: showCustomerForm ? _buildCustomerForm() : _buildMenuItems(),
            ),
            
            // Order Summary Sidebar - RESPONSIVE WIDTH
            Container(
              width: isSmallScreen ? screenWidth * 0.30 : 180, // Reduced width
              color: Colors.grey[50],
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4), // Minimal padding
                        color: Colors.orange[600],
                        child: const Row(
                          children: [
                            Icon(Icons.receipt, color: Colors.white, size: 14), // Smaller icon
                            SizedBox(width: 2), // Minimal spacing
                            Expanded(
                              child: Text(
                                'Order Summary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12, // Smaller font
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
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: orderProvider.orderItems.length,
                                itemBuilder: (context, index) {
                                  OrderItem orderItem = orderProvider.orderItems[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2), // Minimal margin
                                    child: Padding(
                                      padding: const EdgeInsets.all(4), // Minimal padding
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
                                                    fontSize: 11, // Smaller font
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  orderProvider.removeItem(index);
                                                },
                                                child: const Icon(Icons.close, size: 14),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  InkWell(
                                                    onTap: orderItem.quantity > 1
                                                        ? () => orderProvider.updateItemQuantity(
                                                            index, orderItem.quantity - 1)
                                                        : null,
                                                    child: const Icon(Icons.remove_circle_outline, size: 14),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                                    child: Text('${orderItem.quantity}', style: const TextStyle(fontSize: 11)),
                                                  ),
                                                  InkWell(
                                                    onTap: () => orderProvider.updateItemQuantity(
                                                        index, orderItem.quantity + 1),
                                                    child: const Icon(Icons.add_circle_outline, size: 14),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '£${orderItem.totalPrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                  fontSize: 11, // Smaller font
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
                          padding: const EdgeInsets.all(4), // Minimal padding
                          color: Colors.white,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:', style: TextStyle(fontSize: 11)), // Smaller font
                                  Text(
                                    '£${orderProvider.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), // Smaller font
                                  ),
                                ],
                              ),
                              if (orderProvider.deliveryCharge > 0) ...[
                                const SizedBox(height: 2), // Minimal spacing
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Delivery:', style: TextStyle(fontSize: 11)), // Smaller font
                                    Text(
                                      '£${orderProvider.deliveryCharge.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11), // Smaller font
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Smaller font
                                  ),
                                  Text(
                                    '£${orderProvider.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12, // Smaller font
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    print('Building menu items for category: $selectedCategory');
    
    List<MenuItem> items = MenuData.getItemsByCategory(selectedCategory);
    print('Found ${items.length} items for $selectedCategory');
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategory,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item name with constraints
              SizedBox(
                width: double.infinity,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              
              // Price and add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '£${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  Icon(
                    Icons.add_circle,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerForm() {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        showCustomerForm = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Collection/Delivery Toggle
              Wrap(
                spacing: 8,
                children: [
                  const Text('Order Type:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ChoiceChip(
                    label: const Text('Collection'),
                    selected: !orderProvider.customerInfo.isDelivery,
                    onSelected: (selected) {
                      if (selected) {
                        orderProvider.updateCustomerInfo(isDelivery: false);
                        orderProvider.setDeliveryCharge(0.0);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Delivery'),
                    selected: orderProvider.customerInfo.isDelivery,
                    onSelected: (selected) {
                      if (selected) {
                        orderProvider.updateCustomerInfo(isDelivery: true);
                        orderProvider.setDeliveryCharge(2.50);
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Customer Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  orderProvider.updateCustomerInfo(name: value);
                },
              ),
              
              if (orderProvider.customerInfo.isDelivery) ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    orderProvider.updateCustomerInfo(address: value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Postcode *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          orderProvider.updateCustomerInfo(postcode: value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Phone *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          orderProvider.updateCustomerInfo(phoneNumber: value);
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    orderProvider.updateCustomerInfo(phoneNumber: value);
                  },
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Payment Method
              const Text('Payment Method:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Cash'),
                    selected: orderProvider.paymentMethod == 'cash',
                    onSelected: (selected) {
                      if (selected) orderProvider.setPaymentMethod('cash');
                    },
                  ),
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
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canProceed(orderProvider) ? () async {
                    if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderSummaryScreen(),
                        ),
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
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

  bool _canProceed(OrderProvider orderProvider) {
    bool hasName = orderProvider.customerInfo.name?.isNotEmpty == true;
    
    if (orderProvider.customerInfo.isDelivery) {
      bool hasAddress = orderProvider.customerInfo.address?.isNotEmpty == true;
      bool hasPostcode = orderProvider.customerInfo.postcode?.isNotEmpty == true;
      bool hasPhone = orderProvider.customerInfo.phoneNumber?.isNotEmpty == true;
      return hasName && hasAddress && hasPostcode && hasPhone;
    }
    
    return hasName;
  }
}
