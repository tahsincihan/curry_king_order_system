import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'api_test_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showQuickStats = true;
  String _selectedQuickAction = '';

  @override
  void initState() {
    super.initState();
    // Load sales data for dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).refreshSalesData();
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.f1:
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TakeawayOrderScreen()));
          break;
        case LogicalKeyboardKey.f2:
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DineInOrderScreen()));
          break;
        case LogicalKeyboardKey.f3:
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SalesScreen()));
          break;
        case LogicalKeyboardKey.f4:
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ApiTestScreen()));
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 1200;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(context),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: isWideScreen ? _buildWideScreenLayout() : _buildStandardLayout(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Curry King POS',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Desktop Point of Sale System',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.orange[600],
      foregroundColor: Colors.white,
      toolbarHeight: 80,
      elevation: 4,
      actions: [
        // Quick Stats Toggle
        IconButton(
          icon: Icon(_showQuickStats ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _showQuickStats = !_showQuickStats;
            });
          },
          tooltip: 'Toggle Quick Stats',
        ),
        const SizedBox(width: 8),
        
        // Sales Dashboard
        _buildAppBarButton(
          icon: Icons.analytics,
          label: 'Sales',
          tooltip: 'Sales Dashboard (F3)',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SalesScreen())),
        ),
        
        // API Testing
        _buildAppBarButton(
          icon: Icons.api,
          label: 'API Test',
          tooltip: 'API Testing (F4)',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ApiTestScreen())),
        ),
        
        // Printer Settings
        _buildAppBarButton(
          icon: Icons.print,
          label: 'Print',
          tooltip: 'Printer Settings',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PrinterSettingsScreen())),
        ),
        
        const SizedBox(width: 16),
        
        // Current Time
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm:ss').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideScreenLayout() {
    return Row(
      children: [
        // Left Panel - Main Actions (40%)
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                if (_showQuickStats) ...[
                  _buildQuickStatsPanel(),
                  const SizedBox(height: 16),
                ],
                Expanded(child: _buildMainActionsPanel()),
              ],
            ),
          ),
        ),
        
        // Right Panel - Live Orders (60%)
        Expanded(
          flex: 6,
          child: _buildLiveOrdersPanel(),
        ),
      ],
    );
  }

  Widget _buildStandardLayout() {
    return Column(
      children: [
        if (_showQuickStats) ...[
          _buildQuickStatsPanel(),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Row(
            children: [
              // Main Actions
              Expanded(
                flex: 3,
                child: _buildMainActionsPanel(),
              ),
              const SizedBox(width: 16),
              // Live Orders
              Expanded(
                flex: 2,
                child: _buildLiveOrdersPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsPanel() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Today\'s Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => salesProvider.refreshSalesData(),
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Today\'s Sales',
                        value: '£${salesProvider.todayTotal.toStringAsFixed(2)}',
                        icon: Icons.monetization_on,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Orders Today',
                        value: '${salesProvider.todayOrders}',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Avg Order Value',
                        value: '£${salesProvider.getAverageOrderValue().toStringAsFixed(2)}',
                        icon: Icons.analytics,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<OrderProvider>(
                        builder: (context, orderProvider, child) {
                          return _buildStatCard(
                            title: 'Live Orders',
                            value: '${orderProvider.liveOrders.length}',
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionsPanel() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 80,
              color: Colors.orange[800],
            ),
            const SizedBox(height: 16),
            const Text(
              'New Order',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Select order type to begin',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Main Order Buttons
            _buildLargeOrderButton(
              context: context,
              title: 'TAKEAWAY ORDER',
              subtitle: 'Collection & Delivery • Press F1',
              icon: Icons.takeout_dining,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TakeawayOrderScreen())),
              color: Colors.orange[600]!,
            ),
            
            const SizedBox(height: 20),
            
            _buildLargeOrderButton(
              context: context,
              title: 'DINE IN ORDER',
              subtitle: 'Table Service • Press F2',
              icon: Icons.restaurant_menu,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DineInOrderScreen())),
              color: Colors.blue[600]!,
            ),

            const SizedBox(height: 32),

            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    title: 'Sales Report',
                    icon: Icons.analytics,
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SalesScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    title: 'API Test',
                    icon: Icons.api,
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ApiTestScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    title: 'Printer Setup',
                    icon: Icons.print,
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PrinterSettingsScreen())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeOrderButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(16),
          elevation: 6,
        ),
        child: Row(
          children: [
            Icon(icon, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.orange[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.orange[600]),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveOrdersPanel() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final liveOrders = orderProvider.liveOrders;
        return Card(
          elevation: 4,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Live Orders (${liveOrders.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (liveOrders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${liveOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: liveOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No active orders',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Orders will appear here when placed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: liveOrders.length,
                        itemBuilder: (context, index) {
                          // Display newest orders first
                          return _LiveOrderCard(
                            order: liveOrders[liveOrders.length - 1 - index],
                            isCompactView: MediaQuery.of(context).size.width < 1200,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Enhanced Live Order Card for desktop
class _LiveOrderCard extends StatelessWidget {
  final Order order;
  final bool isCompactView;
  
  const _LiveOrderCard({
    Key? key,
    required this.order,
    this.isCompactView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    IconData icon;
    String title;
    String subtitle;
    Color cardColor = Colors.white;
    Color accentColor = Colors.grey;

    if (order.orderType == 'dine-in') {
      icon = Icons.restaurant_menu;
      title = 'Table ${order.tableNumber ?? 'N/A'}';
      subtitle = 'Dine-In Order';
      cardColor = Colors.blue[50]!;
      accentColor = Colors.blue;
    } else {
      if (order.customerInfo.isDelivery) {
        icon = Icons.delivery_dining;
        title = order.customerInfo.name ?? 'Delivery';
        subtitle = 'Delivery to ${order.customerInfo.address ?? 'N/A'}';
        cardColor = Colors.green[50]!;
        accentColor = Colors.green;
      } else {
        icon = Icons.takeout_dining;
        title = order.customerInfo.name ?? 'Collection';
        subtitle = 'Collection Order';
        cardColor = Colors.orange[50]!;
        accentColor = Colors.orange;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(order.orderTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${order.totalItems} items',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '£${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                if (order.paymentMethod != 'none')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.paymentMethod == 'cash' ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.paymentMethod.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Show order details in a dialog
              _showOrderDetails(context, order);
            },
          ),
          if (!isCompactView) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCardActions(context, orderProvider, salesProvider),
            ),
          ],
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - ${order.id.substring(order.id.length - 5)}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${item.quantity}x '),
                    Expanded(child: Text(item.menuItem.name)),
                    Text('£${item.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('£${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
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

  Widget _buildCardActions(BuildContext context, OrderProvider orderProvider,
      SalesProvider salesProvider) {
    bool canComplete =
        order.paymentMethod == 'cash' || order.paymentMethod == 'card';

    return Row(
      children: [
        // Payment method selection
        if (order.paymentMethod == 'none') ...[
          const Text('Pay with:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Cash', style: TextStyle(fontSize: 12)),
            selected: false,
            onSelected: (selected) {
              if (selected) {
                orderProvider.updateLiveOrderPayment(order.id, 'cash');
              }
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.green[200],
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Card', style: TextStyle(fontSize: 12)),
            selected: false,
            onSelected: (selected) {
              if (selected) {
                orderProvider.updateLiveOrderPayment(order.id, 'card');
              }
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.blue[200],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: order.paymentMethod == 'cash' ? Colors.green[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Paid by ${order.paymentMethod.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: order.paymentMethod == 'cash' ? Colors.green[700] : Colors.blue[700],
              ),
            ),
          ),
        ],
        
        const Spacer(),
        
        // Reprint button
        TextButton.icon(
          onPressed: () async {
            try {
              await UnifiedPrinterService.printOrder(order);
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
          icon: const Icon(Icons.print_outlined, size: 16),
          label: const Text('Reprint', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue[700],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Complete order button
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
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    child: const Text('Complete',
                                        style: TextStyle(color: Colors.white)),
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
              : null,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Complete', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: canComplete ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}