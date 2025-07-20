import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/order_provider.dart';
import '../services/unified_printer_service.dart'; // ADD THIS IMPORT
import '../model/order_model.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    // Use the buildCurrentOrder method to get a preview of the order being built
    final Order order = orderProvider.buildCurrentOrder();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Order'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Type Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                order.orderType == 'takeaway'
                                    ? Icons.takeout_dining
                                    : Icons.restaurant_menu,
                                color: Colors.orange[600],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.orderType == 'takeaway'
                                    ? 'TAKEAWAY ORDER'
                                    : 'DINE IN ORDER',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Order Time: ${_formatDateTime(order.orderTime)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Customer Information
                  if (order.orderType == 'takeaway') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                'Name', order.customerInfo.name ?? 'N/A'),
                            if (order.customerInfo.isDelivery) ...[
                              _buildInfoRow('Type', 'Delivery'),
                              _buildInfoRow('Address',
                                  order.customerInfo.address ?? 'N/A'),
                              _buildInfoRow('Postcode',
                                  order.customerInfo.postcode ?? 'N/A'),
                              _buildInfoRow('Phone',
                                  order.customerInfo.phoneNumber ?? 'N/A'),
                            ] else ...[
                              _buildInfoRow('Type', 'Collection'),
                              if (order.customerInfo.phoneNumber?.isNotEmpty ==
                                  true)
                                _buildInfoRow(
                                    'Phone', order.customerInfo.phoneNumber!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Dine In Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Table Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                'Table Number', order.tableNumber ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Order Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...order.items.map((item) => _buildOrderItem(item)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text('£${order.subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (order.deliveryCharge > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Delivery Charge:'),
                                Text(
                                    '£${order.deliveryCharge.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
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
                                '£${order.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Method:'),
                              Text(
                                order.paymentMethod.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[600],
                      side: BorderSide(color: Colors.orange[600]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Back to Edit',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Show loading indicator while processing
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Placing order and printing...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );

                      try {
                        // Place the order into the live list in the provider
                        orderProvider.placeOrder();

                        // Try to print the order automatically
                        try {
                          await UnifiedPrinterService.printOrder(order);
                          print('Order printed successfully');
                        } catch (printError) {
                          print('Print error: $printError');
                          // Don't fail the order placement if printing fails
                          // Just show a warning to the user
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading dialog

                            // Show print error dialog but allow order to continue
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Order Placed'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('✅ Order placed successfully!'),
                                    const SizedBox(height: 8),
                                    Text(
                                        '⚠️ Printing failed: ${printError.toString()}'),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'You can reprint from the live orders screen.'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }

                        // Navigate back to the home screen to see the live order dashboard
                        if (context.mounted) {
                          Navigator.pop(
                              context); // Close loading dialog if still open
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Order placed and printed successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        // Handle order placement errors
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error placing order: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text(
                      'Place & Print Order',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                if (item.specialInstructions?.isNotEmpty == true)
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
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
