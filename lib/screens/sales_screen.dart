import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/sales_provider.dart';
import '../model/sales_model.dart';
import 'order_history_screen.dart'; // --- IMPORT THE NEW SCREEN ---

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load sales data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).refreshSalesData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          // --- ADD THE NEW BUTTON HERE ---
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
            tooltip: 'Order History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<SalesProvider>(context, listen: false)
                  .refreshSalesData();
            },
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final salesProvider =
                  Provider.of<SalesProvider>(context, listen: false);

              switch (value) {
                case 'cleanup':
                  await salesProvider.cleanupOldData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Old data cleaned up')),
                    );
                  }
                  break;
                case 'export':
                  final data = salesProvider.exportSalesData();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Export Data'),
                        content: Text(
                            'Export data generated: ${data['sales'].length} days of data'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  break;
                case 'clear':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Data'),
                      content: const Text(
                          'Are you sure you want to clear all sales data? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await salesProvider.clearAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All sales data cleared')),
                      );
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cleanup',
                child: Text('Cleanup Old Data'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Data'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child:
                    Text('Clear All Data', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, child) {
          if (salesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(salesProvider),
              _buildTodayTab(salesProvider),
              _buildTransactionsTab(salesProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(SalesProvider salesProvider) {
    final percentages = salesProvider.getPaymentMethodPercentages();
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isWideScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Sales (2 Days)',
                              '£${salesProvider.twoDayTotal.toStringAsFixed(2)}',
                              Icons.monetization_on,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Orders',
                              '${salesProvider.twoDayOrders}',
                              Icons.receipt,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Avg Order Value',
                              '£${salesProvider.getAverageOrderValue().toStringAsFixed(2)}',
                              Icons.analytics,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Payment Split',
                              '${percentages['cash']?.toStringAsFixed(0)}% Cash',
                              Icons.payment,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Payment Method Breakdown
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Method Breakdown (2 Days)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildPaymentRow(
                                'Cash Sales',
                                salesProvider.twoDayCash,
                                percentages['cash'] ?? 0,
                                Colors.green,
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentRow(
                                'Card Sales',
                                salesProvider.twoDayCard,
                                percentages['card'] ?? 0,
                                Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Daily Comparison
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Comparison',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildDailyComparisonRow(
                                'Today',
                                salesProvider.todayTotal,
                                salesProvider.todayOrders,
                                true,
                              ),
                              const SizedBox(height: 8),
                              _buildDailyComparisonRow(
                                'Yesterday',
                                salesProvider.yesterdayTotal,
                                salesProvider.yesterdayOrders,
                                false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Sales (2 Days)',
                        '£${salesProvider.twoDayTotal.toStringAsFixed(2)}',
                        Icons.monetization_on,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Orders',
                        '${salesProvider.twoDayOrders}',
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Avg Order Value',
                        '£${salesProvider.getAverageOrderValue().toStringAsFixed(2)}',
                        Icons.analytics,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Payment Split',
                        '${percentages['cash']?.toStringAsFixed(0)}% Cash',
                        Icons.payment,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Payment Method Breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method Breakdown (2 Days)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentRow(
                          'Cash Sales',
                          salesProvider.twoDayCash,
                          percentages['cash'] ?? 0,
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentRow(
                          'Card Sales',
                          salesProvider.twoDayCard,
                          percentages['card'] ?? 0,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Daily Comparison
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Comparison',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildDailyComparisonRow(
                          'Today',
                          salesProvider.todayTotal,
                          salesProvider.todayOrders,
                          true,
                        ),
                        const SizedBox(height: 8),
                        _buildDailyComparisonRow(
                          'Yesterday',
                          salesProvider.yesterdayTotal,
                          salesProvider.yesterdayOrders,
                          false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTodayTab(SalesProvider salesProvider) {
    final hourlyData = salesProvider.getTodayHourlyBreakdown();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today - ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '£${salesProvider.todayTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                            const Text('Total Sales'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${salesProvider.todayOrders}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                            const Text('Orders'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '£${salesProvider.todayCash.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Text('Cash'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '£${salesProvider.todayCard.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Text('Card'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hourly Breakdown
          if (hourlyData.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hourly Sales Breakdown',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...hourlyData.entries.map((entry) {
                      final hour = entry.key;
                      final amount = entry.value;
                      final timeRange =
                          '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(timeRange),
                            Text(
                              '£${amount.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(SalesProvider salesProvider) {
    final transactions = salesProvider.recentTransactions;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${transactions.length} transactions',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No transactions today',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions.reversed.toList()[index];
                    return _buildTransactionTile(transaction);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
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
      ),
    );
  }

  Widget _buildPaymentRow(
      String label, double amount, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          '£${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDailyComparisonRow(
      String day, double amount, int orders, bool isToday) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.orange.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              day,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '£${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.orange[600] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$orders orders',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(SaleTransaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: transaction.paymentMethod == 'cash'
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction.paymentMethod == 'cash'
                ? Icons.money
                : Icons.credit_card,
            color: transaction.paymentMethod == 'cash'
                ? Colors.green
                : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Text(
              '£${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: transaction.paymentMethod == 'cash'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.paymentMethod.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: transaction.paymentMethod == 'cash'
                      ? Colors.green[700]
                      : Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.orderType.toUpperCase()} • ${transaction.itemCount} items',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (transaction.customerName != null)
              Text('Customer: ${transaction.customerName}'),
            if (transaction.tableNumber != null)
              Text('Table: ${transaction.tableNumber}'),
          ],
        ),
        trailing: Text(
          DateFormat('HH:mm').format(transaction.timestamp),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }
}
