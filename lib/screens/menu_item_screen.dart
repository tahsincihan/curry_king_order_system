import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import 'package:provider/provider.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final MenuItem menuItem;

  const MenuItemDetailScreen({Key? key, required this.menuItem}) : super(key: key);

  @override
  _MenuItemDetailScreenState createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  int quantity = 1;
  String? selectedRice = 'Pilau Rice';
  final TextEditingController noteController = TextEditingController();
  double additionalCost = 0.0;
  
  final List<String> riceOptions = [
    'Pilau Rice',
    'Plain Rice',
    'Special Fried Rice',
    'Mushroom Fried Rice',
    'Egg Fried Rice',
    'Garlic Fried Rice',
    'Onion Fried Rice',
    'Coconut Fried Rice',
    'Keema Rice',
  ];

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _updateRice(String? rice) {
    if (rice == null) return;
    
    setState(() {
      // Reset additional cost
      additionalCost = 0.0;
      
      // If not default rice (Pilau Rice), add £1
      if (rice != 'Pilau Rice' && rice != 'Plain Rice') {
        additionalCost = 1.0;
      }
      
      selectedRice = rice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize Order'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item name and price
              Text(
                widget.menuItem.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '£${widget.menuItem.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              
              // Description if available
              if (widget.menuItem.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.menuItem.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Quantity selector
              Row(
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => quantity++),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Rice selection for curry dishes
              if (widget.menuItem.category.contains('Dishes') && 
                  !widget.menuItem.category.contains('Starters') &&
                  !widget.menuItem.category.contains('Tandoori')) ...[
                const Text(
                  'Select Rice:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRice,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: riceOptions.map((String rice) {
                        return DropdownMenuItem<String>(
                          value: rice,
                          child: Text(
                            rice == 'Pilau Rice' || rice == 'Plain Rice'
                                ? rice
                                : '$rice (+£1.00)',
                          ),
                        );
                      }).toList(),
                      onChanged: _updateRice,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilau Rice or Plain Rice included with no extra charge.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Special instructions
              const Text(
                'Special Instructions:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'e.g. Spicy, No onions, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Total price
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
                    '£${((widget.menuItem.price + additionalCost) * quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Add to cart button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Create a modified menu item with adjusted price if needed
                    MenuItem adjustedItem = MenuItem(
                      name: selectedRice != null && selectedRice != 'Pilau Rice'
                          ? "${widget.menuItem.name} with $selectedRice"
                          : widget.menuItem.name,
                      price: widget.menuItem.price + additionalCost,
                      category: widget.menuItem.category,
                      description: widget.menuItem.description,
                    );
                    
                    // Add to cart
                    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                    
                    // Create new order item with selected options
                    OrderItem orderItem = OrderItem(
                      menuItem: adjustedItem,
                      quantity: quantity,
                      specialInstructions: noteController.text.isNotEmpty ? noteController.text : null,
                    );
                    
                    // Add custom method to add complete order item
                    orderProvider.addCompleteOrderItem(orderItem);
                    
                    // Show confirmation and go back
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.menuItem.name} added to order'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Add to Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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