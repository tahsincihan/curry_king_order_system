import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import '../services/sales_provider.dart';
import '../services/unified_printer_service.dart';
import 'takeaway_order_screen.dart';
import 'dine_in_screen.dart';
import 'printer_settings_screen.dart';
import 'sales_screen.dart';
import 'order_summary.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Curry King POS'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesScreen())),
            tooltip: 'Sales Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PrinterSettingsScreen())),
            tooltip: 'Printer Settings',
          ),
          const SizedBox(width: 16),
        ],
      ),
      // **UPDATED: Flex values adjusted for a 60/40 layout split**
      body: Row(
        children: [
          // Left side - Main actions panel
          Expanded(
            // Takes up 3 parts (60%) of the available space
            flex: 3,
            child: _buildActionPanel(context),
          ),

          // Right side - Live Order Dashboard
          Expanded(
            // Takes up 2 parts (40%) of the available space
            flex: 2,
            child: _buildLiveOrdersPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 60,
            color: Colors.orange[800],
          ),
          const SizedBox(height: 16),
          const Text('New Order',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildOrderButton(
            context: context,
            title: 'TAKEAWAY',
            subtitle: 'Collection & Delivery',
            icon: Icons.takeout_dining,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TakeawayOrderScreen())),
          ),
          const SizedBox(height: 24),
          _buildOrderButton(
            context: context,
            title: 'DINE IN',
            subtitle: 'Table Orders',
            icon: Icons.restaurant_menu,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DineInOrderScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton(
      {required BuildContext context,
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Live Orders Panel
  Widget _buildLiveOrdersPanel(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final liveOrders = orderProvider.liveOrders;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Live Orders (${liveOrders.length})',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: liveOrders.isEmpty
                  ? const Center(
                      child: Text('No active orders',
                          style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: liveOrders.length,
                      itemBuilder: (context, index) {
                        // Display newest orders first
                        return _LiveOrderCard(
                            order: liveOrders[liveOrders.length - 1 - index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// Live Order Card Widget
class _LiveOrderCard extends StatelessWidget {
  final Order order;
  const _LiveOrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    IconData icon;
    String title;
    String subtitle;
    Color cardColor = Colors.white;

    if (order.orderType == 'dine-in') {
      icon = Icons.restaurant_menu;
      title = 'Table ${order.tableNumber ?? 'N/A'}';
      subtitle = 'Dine-In Order';
      cardColor = Colors.blue[50]!;
    } else {
      if (order.customerInfo.isDelivery) {
        icon = Icons.delivery_dining;
        title = order.customerInfo.name ?? 'Delivery';
        subtitle = 'Delivery to ${order.customerInfo.address ?? 'N/A'}';
        cardColor = Colors.green[50]!;
      } else {
        icon = Icons.takeout_dining;
        title = order.customerInfo.name ?? 'Collection';
        subtitle = 'Collection Order';
        cardColor = Colors.orange[50]!;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!, width: 1)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.black54),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${order.totalItems} items • ${DateFormat('HH:mm').format(order.orderTime)}'),
            trailing: Text('£${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            onTap: () {
              // TODO: This should show a read-only view of the order
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildCardActions(context, orderProvider, salesProvider),
          )
        ],
      ),
    );
  }

  Widget _buildCardActions(BuildContext context, OrderProvider orderProvider,
      SalesProvider salesProvider) {
    bool isCollection =
        order.orderType == 'takeaway' && !order.customerInfo.isDelivery;

    // For collection orders, a payment method must be explicitly chosen.
    // For Dine-in or Delivery, we can assume a default or that it's handled differently.
    bool canComplete = !isCollection ||
        (order.paymentMethod == 'cash' || order.paymentMethod == 'card');

    return Row(
      children: [
        if (isCollection)
          Row(
            children: [
              const Text('Pay with:'),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Cash'),
                selected: order.paymentMethod == 'cash',
                onSelected: (selected) {
                  if (selected)
                    orderProvider.updateLiveOrderPayment(order.id, 'cash');
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.green[200],
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Card'),
                selected: order.paymentMethod == 'card',
                onSelected: (selected) {
                  if (selected)
                    orderProvider.updateLiveOrderPayment(order.id, 'card');
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue[200],
              ),
            ],
          ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: canComplete
              ? () async {
                  final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                title: const Text('Complete Order?'),
                                content: Text(
                                    'This will finalize the sale for ${order.paymentMethod.toUpperCase()} and print the receipt. This cannot be undone.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Complete',
                                        style: TextStyle(color: Colors.white)),
                                    style: TextButton.styleFrom(
                                        backgroundColor: Colors.green),
                                  ),
                                ],
                              )) ??
                      false;

                  if (confirm) {
                    final completedOrder =
                        orderProvider.completeOrder(order.id);
                    if (completedOrder != null) {
                      await salesProvider.addSale(completedOrder);
                      await UnifiedPrinterService.printOrder(completedOrder);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Order completed and sale recorded.'),
                              backgroundColor: Colors.green),
                        );
                      }
                    }
                  }
                }
              : null, // Button is disabled if conditions aren't met
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark as Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor: canComplete ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
