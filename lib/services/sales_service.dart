import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../model/sales_model.dart';
import '../model/order_model.dart';

class SalesService {
  static const String _salesBoxName = 'daily_sales';
  static late Box<DailySales> _salesBox;

  // Initialize Hive and open the sales box
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters (manual adapters included in sales_model.dart)
    Hive.registerAdapter(DailySalesAdapter());
    Hive.registerAdapter(SaleTransactionAdapter());
    
    _salesBox = await Hive.openBox<DailySales>(_salesBoxName);
    
    // Clean up old data on initialization
    await _cleanupOldData();
  }

  // Get today's date in yyyy-MM-dd format
  static String _getTodayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Get yesterday's date in yyyy-MM-dd format
  static String _getYesterdayKey() {
    return DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1))
    );
  }

  // Add a sale transaction
  static Future<void> addSale(Order order) async {
    final today = _getTodayKey();
    
    // Get or create today's sales record
    DailySales? todaySales = _salesBox.get(today);
    if (todaySales == null) {
      todaySales = DailySales(date: today, transactions: []);
    }

    // Create transaction record
    final transaction = SaleTransaction(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: order.orderTime,
      amount: order.total,
      paymentMethod: order.paymentMethod,
      orderType: order.orderType,
      deliveryCharge: order.deliveryCharge,
      itemCount: order.totalItems,
      customerName: order.customerInfo.name,
      tableNumber: order.tableNumber,
    );

    // Add transaction to today's sales
    todaySales.addTransaction(transaction);
    
    // Save to Hive
    await _salesBox.put(today, todaySales);
  }

  // Get today's sales
  static DailySales? getTodaySales() {
    return _salesBox.get(_getTodayKey());
  }

  // Get yesterday's sales
  static DailySales? getYesterdaySales() {
    return _salesBox.get(_getYesterdayKey());
  }

  // Get all available sales data (max 2 days)
  static List<DailySales> getAllSales() {
    return _salesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  // Get sales summary for the last 2 days
  static Map<String, double> getSalesSummary() {
    final today = getTodaySales();
    final yesterday = getYesterdaySales();
    
    double totalCash = 0.0;
    double totalCard = 0.0;
    double totalDelivery = 0.0;
    int totalOrders = 0;
    
    if (today != null) {
      totalCash += today.cashSales;
      totalCard += today.cardSales;
      totalDelivery += today.deliveryCharges;
      totalOrders += today.totalOrders;
    }
    
    if (yesterday != null) {
      totalCash += yesterday.cashSales;
      totalCard += yesterday.cardSales;
      totalDelivery += yesterday.deliveryCharges;
      totalOrders += yesterday.totalOrders;
    }
    
    return {
      'totalSales': totalCash + totalCard,
      'cashSales': totalCash,
      'cardSales': totalCard,
      'deliveryCharges': totalDelivery,
      'totalOrders': totalOrders.toDouble(),
    };
  }

  // Clean up data older than 2 days
  static Future<void> _cleanupOldData() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 2));
    final cutoffKey = DateFormat('yyyy-MM-dd').format(cutoffDate);
    
    // Get all keys that are older than 2 days
    final keysToDelete = _salesBox.keys
        .where((key) => key.toString().compareTo(cutoffKey) < 0)
        .toList();
    
    // Delete old records
    for (final key in keysToDelete) {
      await _salesBox.delete(key);
    }
  }

  // Manual cleanup method (can be called from UI)
  static Future<void> cleanupOldData() async {
    await _cleanupOldData();
  }

  // Get transactions for a specific date
  static List<SaleTransaction> getTransactionsForDate(String date) {
    final salesData = _salesBox.get(date);
    return salesData?.transactions ?? [];
  }

  // Export sales data (for debugging or backup)
  static Map<String, dynamic> exportSalesData() {
    final allSales = getAllSales();
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'sales': allSales.map((sales) => {
        'date': sales.date,
        'cashSales': sales.cashSales,
        'cardSales': sales.cardSales,
        'totalOrders': sales.totalOrders,
        'deliveryCharges': sales.deliveryCharges,
        'transactions': sales.transactions.map((t) => {
          'orderId': t.orderId,
          'timestamp': t.timestamp.toIso8601String(),
          'amount': t.amount,
          'paymentMethod': t.paymentMethod,
          'orderType': t.orderType,
          'deliveryCharge': t.deliveryCharge,
          'itemCount': t.itemCount,
          'customerName': t.customerName,
          'tableNumber': t.tableNumber,
        }).toList(),
      }).toList(),
    };
  }

  // Clear all sales data (for testing or reset)
  static Future<void> clearAllData() async {
    await _salesBox.clear();
  }
}