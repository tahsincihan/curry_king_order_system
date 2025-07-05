import 'package:flutter/material.dart';
import '../model/sales_model.dart';
import '../model/order_model.dart';
import 'sales_service.dart';

class SalesProvider extends ChangeNotifier {
  DailySales? _todaySales;
  DailySales? _yesterdaySales;
  List<SaleTransaction> _recentTransactions = [];
  bool _isLoading = false;

  // Getters
  DailySales? get todaySales => _todaySales;
  DailySales? get yesterdaySales => _yesterdaySales;
  List<SaleTransaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;

  // --- NEW METHOD TO FIX THE ERROR ---
  List<DailySales> getAllSales() {
    return SalesService.getAllSales();
  }
  // --- END OF NEW METHOD ---

  // Computed properties
  double get todayTotal => _todaySales?.totalSales ?? 0.0;
  double get todayCash => _todaySales?.cashSales ?? 0.0;
  double get todayCard => _todaySales?.cardSales ?? 0.0;
  int get todayOrders => _todaySales?.totalOrders ?? 0;

  double get yesterdayTotal => _yesterdaySales?.totalSales ?? 0.0;
  double get yesterdayCash => _yesterdaySales?.cashSales ?? 0.0;
  double get yesterdayCard => _yesterdaySales?.cardSales ?? 0.0;
  int get yesterdayOrders => _yesterdaySales?.totalOrders ?? 0;

  double get twoDayTotal => todayTotal + yesterdayTotal;
  double get twoDayCash => todayCash + yesterdayCash;
  double get twoDayCard => todayCard + yesterdayCard;
  int get twoDayOrders => todayOrders + yesterdayOrders;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SalesService.initialize();
      await loadSalesData();
    } catch (e) {
      debugPrint('Error initializing sales provider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load sales data from storage
  Future<void> loadSalesData() async {
    try {
      _todaySales = SalesService.getTodaySales();
      _yesterdaySales = SalesService.getYesterdaySales();

      // Load recent transactions (today's transactions)
      _recentTransactions = _todaySales?.transactions ?? [];

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sales data: $e');
    }
  }

  // Add a new sale
  Future<void> addSale(Order order) async {
    try {
      await SalesService.addSale(order);
      await loadSalesData(); // Refresh data
    } catch (e) {
      debugPrint('Error adding sale: $e');
    }
  }

  // Refresh sales data
  Future<void> refreshSalesData() async {
    await loadSalesData();
  }

  // Clean up old data
  Future<void> cleanupOldData() async {
    try {
      await SalesService.cleanupOldData();
      await loadSalesData();
    } catch (e) {
      debugPrint('Error cleaning up old data: $e');
    }
  }

  // Get sales summary
  Map<String, double> getSalesSummary() {
    return SalesService.getSalesSummary();
  }

  // Get transactions for a specific date
  List<SaleTransaction> getTransactionsForDate(String date) {
    return SalesService.getTransactionsForDate(date);
  }

  // Get percentage breakdown
  Map<String, double> getPaymentMethodPercentages() {
    final total = twoDayTotal;
    if (total == 0) return {'cash': 0.0, 'card': 0.0};

    return {
      'cash': (twoDayCash / total) * 100,
      'card': (twoDayCard / total) * 100,
    };
  }

  // Get hourly breakdown for today
  Map<int, double> getTodayHourlyBreakdown() {
    if (_todaySales == null) return {};

    Map<int, double> hourlyData = {};

    for (final transaction in _todaySales!.transactions) {
      final hour = transaction.timestamp.hour;
      hourlyData[hour] = (hourlyData[hour] ?? 0.0) + transaction.amount;
    }

    return hourlyData;
  }

  // Get average order value
  double getAverageOrderValue() {
    if (twoDayOrders == 0) return 0.0;
    return twoDayTotal / twoDayOrders;
  }

  // Clear all sales data (for testing)
  Future<void> clearAllData() async {
    try {
      await SalesService.clearAllData();
      _todaySales = null;
      _yesterdaySales = null;
      _recentTransactions = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing sales data: $e');
    }
  }

  // Export sales data
  Map<String, dynamic> exportSalesData() {
    return SalesService.exportSalesData();
  }
}
