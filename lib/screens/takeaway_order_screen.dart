import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/menu_data.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import '../screens/order_summary.dart';

class TakeawayOrderScreen extends StatefulWidget {
  @override
  _TakeawayOrderScreenState createState() => _TakeawayOrderScreenState();
}

class _TakeawayOrderScreenState extends State<TakeawayOrderScreen> {
  String selectedCategory = 'Starters';
  bool showCustomerForm = false;
  
  @override
  void initState() {
    super.initState();
    Provider.of<OrderProvider>(context, listen: false).setOrderType('takeaway');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Takeaway Order'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () {
                      if (orderProvider.orderItems.isNotEmpty) {
                        setState(() {
                          showCustomerForm = true;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Add items to cart first')),
                        );
                      }
                    },
                  ),
                  if (orderProvider.totalItems > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${orderProvider.totalItems}',
                          style: TextStyle(
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
      body: Row(
        children: [
          // Categories Sidebar
          Container(
            width: 200,
            color: Colors.grey[100],
            child: ListView.builder(
              itemCount: MenuData.getCategories().length,
              itemBuilder: (context, index) {
                String category = MenuData.getCategories()[index];
                bool isSelected = category == selectedCategory;
                
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: isSelected ? Colors.orange[600] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  ),
                );
              },
            ),
          ),
          
          // Menu Items
          Expanded(
            child: showCustomerForm ? _buildCustomerForm() : _buildMenuItems(),
          ),
          
          // Order Summary Sidebar
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    List<MenuItem> items = MenuData.getItemsByCategory(selectedCategory);
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategory,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} added to order'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description != null) ...[
                SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '£${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  Icon(
                    Icons.add_circle,
                    color: Colors.orange[600],
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: 300,
      color: Colors.grey[50],
      child: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.orange[600],
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: orderProvider.orderItems.length,
                        itemBuilder: (context, index) {
                          OrderItem orderItem = orderProvider.orderItems[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          orderItem.menuItem.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20),
                                        onPressed: () {
                                          orderProvider.removeItem(index);
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove_circle_outline),
                                            onPressed: orderItem.quantity > 1
                                                ? () => orderProvider.updateItemQuantity(
                                                    index, orderItem.quantity - 1)
                                                : null,
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                          Text('${orderItem.quantity}'),
                                          IconButton(
                                            icon: Icon(Icons.add_circle_outline),
                                            onPressed: () => orderProvider.updateItemQuantity(
                                                index, orderItem.quantity + 1),
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '£${orderItem.totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
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
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text(
                            '£${orderProvider.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (orderProvider.deliveryCharge > 0) ...[
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Delivery:', style: TextStyle(fontSize: 16)),
                            Text(
                              '£${orderProvider.deliveryCharge.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        showCustomerForm = false;
                      });
                    },
                  ),
                  Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Collection/Delivery Toggle
              Row(
                children: [
                  Text('Order Type: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ChoiceChip(
                    label: Text('Collection'),
                    selected: !orderProvider.customerInfo.isDelivery,
                    onSelected: (selected) {
                      if (selected) {
                        orderProvider.updateCustomerInfo(isDelivery: false);
                        orderProvider.setDeliveryCharge(0.0);
                      }
                    },
                  ),
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Delivery'),
                    selected: orderProvider.customerInfo.isDelivery,
                    onSelected: (selected) {
                      if (selected) {
                        orderProvider.updateCustomerInfo(isDelivery: true);
                        orderProvider.setDeliveryCharge(2.50); // You can adjust delivery charge
                      }
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Customer Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  orderProvider.updateCustomerInfo(name: value);
                },
              ),
              
              if (orderProvider.customerInfo.isDelivery) ...[
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    orderProvider.updateCustomerInfo(address: value);
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Postcode *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          orderProvider.updateCustomerInfo(postcode: value);
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    orderProvider.updateCustomerInfo(phoneNumber: value);
                  },
                ),
              ],
              
              SizedBox(height: 24),
              
              // Payment Method
              Text('Payment Method:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Cash'),
                    selected: orderProvider.paymentMethod == 'cash',
                    onSelected: (selected) {
                      if (selected) orderProvider.setPaymentMethod('cash');
                    },
                  ),
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Card'),
                    selected: orderProvider.paymentMethod == 'card',
                    onSelected: (selected) {
                      if (selected) orderProvider.setPaymentMethod('card');
                    },
                  ),
                ],
              ),
              
              Spacer(),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canProceed(orderProvider) ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSummaryScreen(),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Review Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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