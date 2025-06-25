import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_provider.dart';
import 'takeaway_order_screen.dart';
import 'dine_in_screen.dart';
import 'printer_settings_screen.dart';
import 'sales_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1000;
    
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.restaurant, size: 32, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Curry King POS System'),
          ],
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        actions: [
          // Sales Summary in App Bar
          Consumer<SalesProvider>(
            builder: (context, salesProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Today's Sales",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '£${salesProvider.todayTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          
          // Quick Action Buttons
          _buildAppBarButton(
            icon: Icons.analytics,
            label: 'Sales',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildAppBarButton(
            icon: Icons.print,
            label: 'Printer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrinterSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            // Wide screen layout (desktop POS)
            return _buildWideLayout(context);
          } else {
            // Standard layout (tablet POS)
            return _buildStandardLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          onPressed: onPressed,
          tooltip: label,
          padding: const EdgeInsets.all(8),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Main actions
        Expanded(
          flex: 2,
          child: _buildMainContent(context, isWide: true),
        ),
        
        // Right side - Quick info panel
        Container(
          width: 400,
          color: Colors.white,
          child: _buildInfoPanel(context),
        ),
      ],
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return _buildMainContent(context, isWide: false);
  }

  Widget _buildMainContent(BuildContext context, {required bool isWide}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Header
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: isWide ? 120 : 80,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CURRY KING',
                    style: TextStyle(
                      fontSize: isWide ? 48 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    'POINT OF SALE SYSTEM',
                    style: TextStyle(
                      fontSize: isWide ? 20 : 16,
                      color: Colors.orange[600],
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Order Type Selection
            Text(
              'Select Order Type',
              style: TextStyle(
                fontSize: isWide ? 32 : 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Order Buttons
            if (isWide) ...[
              // Wide layout - buttons side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOrderButton(
                    context: context,
                    title: 'TAKEAWAY',
                    subtitle: 'Collection & Delivery Orders',
                    icon: Icons.takeout_dining,
                    color: Colors.orange[600]!,
                    onPressed: () => _navigateToTakeaway(context),
                    width: 280,
                    height: 160,
                  ),
                  const SizedBox(width: 32),
                  _buildOrderButton(
                    context: context,
                    title: 'DINE IN',
                    subtitle: 'Restaurant Table Orders',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange[700]!,
                    onPressed: () => _navigateToDineIn(context),
                    width: 280,
                    height: 160,
                  ),
                ],
              ),
            ] else ...[
              // Standard layout - buttons stacked
              _buildOrderButton(
                context: context,
                title: 'TAKEAWAY',
                subtitle: 'Collection & Delivery Orders',
                icon: Icons.takeout_dining,
                color: Colors.orange[600]!,
                onPressed: () => _navigateToTakeaway(context),
                width: 320,
                height: 120,
              ),
              const SizedBox(height: 20),
              _buildOrderButton(
                context: context,
                title: 'DINE IN',
                subtitle: 'Restaurant Table Orders',
                icon: Icons.restaurant_menu,
                color: Colors.orange[700]!,
                onPressed: () => _navigateToDineIn(context),
                width: 320,
                height: 120,
              ),
            ],

            const SizedBox(height: 40),

            // Quick Actions Row
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildQuickActionButton(
                  context: context,
                  title: 'Sales Dashboard',
                  icon: Icons.analytics,
                  color: Colors.blue[600]!,
                  onPressed: () => _navigateToSales(context),
                ),
                _buildQuickActionButton(
                  context: context,
                  title: 'Printer Setup',
                  icon: Icons.print,
                  color: Colors.green[600]!,
                  onPressed: () => _navigateToPrinter(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today\'s Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildInfoCard(
                title: 'Total Sales',
                value: '£${salesProvider.todayTotal.toStringAsFixed(2)}',
                icon: Icons.monetization_on,
                color: Colors.green,
              ),
              
              _buildInfoCard(
                title: 'Orders Today',
                value: '${salesProvider.todayOrders}',
                icon: Icons.receipt,
                color: Colors.blue,
              ),
              
              _buildInfoCard(
                title: 'Cash Sales',
                value: '£${salesProvider.todayCash.toStringAsFixed(2)}',
                icon: Icons.money,
                color: Colors.orange,
              ),
              
              _buildInfoCard(
                title: 'Card Sales',
                value: '£${salesProvider.todayCard.toStringAsFixed(2)}',
                icon: Icons.credit_card,
                color: Colors.purple,
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToSales(context),
                  icon: const Icon(Icons.analytics),
                  label: const Text('View Detailed Sales'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  Widget _buildOrderButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: height * 0.3),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: height * 0.15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: height * 0.08,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 180,
      height: 80,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTakeaway(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TakeawayOrderScreen()),
    );
  }

  void _navigateToDineIn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DineInOrderScreen()),
    );
  }

  void _navigateToSales(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesScreen()),
    );
  }

  void _navigateToPrinter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrinterSettingsScreen()),
    );
  }
}