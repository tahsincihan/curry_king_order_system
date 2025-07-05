import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/order_model.dart';
import '../model/sales_model.dart';
import '../services/sales_provider.dart';
import '../services/unified_printer_service.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  // Helper function to reconstruct an Order object for printing
  Order _reconstructOrderFromTransaction(SaleTransaction transaction) {
    final items = transaction.items.map((itemMap) {
      // Recreate the MenuItem and OrderItem from the stored map
      final menuItem = MenuItem(
        name: itemMap['name'],
        price: itemMap['price'],
        category: '', // Category is not essential for re-printing
      );
      return OrderItem(
        menuItem: menuItem,
        quantity: itemMap['quantity'],
        specialInstructions: itemMap['specialInstructions'],
      );
    }).toList();

    final customerInfo = CustomerInfo(
      name: transaction.customerName,
      // Address, etc., are not stored, so they won't be on the reprint
    );

    return Order(
      id: transaction.orderId,
      items: items,
      customerInfo: customerInfo,
      orderType: transaction.orderType,
      paymentMethod: transaction.paymentMethod,
      orderTime: transaction.timestamp,
      tableNumber: transaction.tableNumber,
      deliveryCharge: transaction.deliveryCharge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final allSalesDays = salesProvider.getAllSales();
    final allTransactions = allSalesDays
        .expand((dailySales) => dailySales.transactions)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: allTransactions.isEmpty
          ? const Center(
              child: Text(
                'No completed orders found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: allTransactions.length,
              itemBuilder: (context, index) {
                final transaction = allTransactions[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      'Order #${transaction.orderId.substring(transaction.orderId.length - 5)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer: ${transaction.customerName ?? 'N/A'} • Table: ${transaction.tableNumber ?? 'N/A'}',
                        ),
                        Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp)} • ${transaction.paymentMethod.toUpperCase()}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '£${transaction.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () async {
                            try {
                              final orderToPrint =
                                  _reconstructOrderFromTransaction(transaction);
                              await UnifiedPrinterService.printOrder(
                                  orderToPrint);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reprinting order...'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Reprint failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Reprint Order',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
