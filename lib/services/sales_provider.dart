import 'package:flutter/material.dart';
import '../model/sales_model.dart';
import '../model/order_model.dart';
import 'sales_service.dart';

class SalesProvider extends ChangeNotifier {
  DailySales? _todaySales;
  DailySales? _yesterdaySales;
  List<SaleTransaction> _recentTransactions = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _initializationError;

  // Getters
  DailySales? get todaySales => _todaySales;
  DailySales? get yesterdaySales => _yesterdaySales;
  List<SaleTransaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  // Get all sales - safe method
  List<DailySales> getAllSales() {
    try {
      if (!_isInitialized) {
        print('Warning: SalesProvider not initialized, returning empty list');
        return [];
      }
      return SalesService.getAllSales();
    } catch (e) {
      print('Error getting all sales: $e');
      return [];
    }
  }

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

  // Initialize the provider with comprehensive error handling
  Future<void> initialize() async {
    if (_isInitialized) {
      print('SalesProvider already initialized');
      return;
    }

    _isLoading = true;
    _initializationError = null;
    notifyListeners();

    try {
      print('Initializing SalesService...');
      await SalesService.initialize();
      print('✓ SalesService initialized successfully');
      
      print('Loading sales data...');
      await loadSalesData();
      print('✓ Sales data loaded successfully');
      
      _isInitialized = true;
      print('✓ SalesProvider initialization complete');
    } catch (e, stackTrace) {
      _initializationError = e.toString();
      print('❌ Error initializing sales provider: $e');
      print('Stack trace: $stackTrace');
      
      // Try to continue with empty data
      _todaySales = null;
      _yesterdaySales = null;
      _recentTransactions = [];
      
      // Mark as initialized even with error to prevent retry loops
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load sales data from storage with error handling
  Future<void> loadSalesData() async {
    try {
      if (!_isInitialized && _initializationError == null) {
        print('Warning: Attempting to load data before initialization');
        return;
      }

      _todaySales = SalesService.getTodaySales();
      _yesterdaySales = SalesService.getYesterdaySales();

      // Load recent transactions (today's transactions)
      _recentTransactions = _todaySales?.transactions ?? [];

      print('Sales data loaded: Today: £${todayTotal.toStringAsFixed(2)}, Yesterday: £${yesterdayTotal.toStringAsFixed(2)}');
      notifyListeners();
    } catch (e) {
      print('Error loading sales data: $e');
      // Continue with empty data
      _todaySales = null;
      _yesterdaySales = null;
      _recentTransactions = [];
      notifyListeners();
    }
  }

  // Add a new sale with error handling
  Future<void> addSale(Order order) async {
    try {
      if (!_isInitialized) {
        throw Exception('SalesProvider not initialized');
      }
      
      await SalesService.addSale(order);
      await loadSalesData(); // Refresh data
      print('Sale added successfully: £${order.total.toStringAsFixed(2)}');
    } catch (e) {
      print('Error adding sale: $e');
      rethrow; // Re-throw so UI can show error
    }
  }

  // Refresh sales data
  Future<void> refreshSalesData() async {
    if (!_isInitialized) {
      print('Cannot refresh data - provider not initialized');
      return;
    }
    await loadSalesData();
  }

  // Clean up old data with error handling
  Future<void> cleanupOldData() async {
    try {
      if (!_isInitialized) {
        throw Exception('SalesProvider not initialized');
      }
      
      await SalesService.cleanupOldData();
      await loadSalesData();
      print('Old data cleaned up successfully');
    } catch (e) {
      print('Error cleaning up old data: $e');
      rethrow;
    }
  }

  // Get sales summary with error handling
  Map<String, double> getSalesSummary() {
    try {
      if (!_isInitialized) {
        return {
          'totalSales': 0.0,
          'cashSales': 0.0,
          'cardSales': 0.0,
          'deliveryCharges': 0.0,
          'totalOrders': 0.0,
        };
      }
      return SalesService.getSalesSummary();
    } catch (e) {
      print('Error getting sales summary: $e');
      return {
        'totalSales': 0.0,
        'cashSales': 0.0,
        'cardSales': 0.0,
        'deliveryCharges': 0.0,
        'totalOrders': 0.0,
      };
    }
  }

  // Get transactions for a specific date with error handling
  List<SaleTransaction> getTransactionsForDate(String date) {
    try {
      if (!_isInitialized) {
        return [];
      }
      return SalesService.getTransactionsForDate(date);
    } catch (e) {
      print('Error getting transactions for date $date: $e');
      return [];
    }
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

    try {
      for (final transaction in _todaySales!.transactions) {
        final hour = transaction.timestamp.hour;
        hourlyData[hour] = (hourlyData[hour] ?? 0.0) + transaction.amount;
      }
    } catch (e) {
      print('Error calculating hourly breakdown: $e');
    }

    return hourlyData;
  }

  // Get average order value
  double getAverageOrderValue() {
    if (twoDayOrders == 0) return 0.0;
    return twoDayTotal / twoDayOrders;
  }

  // Clear all sales data (for testing) with error handling
  Future<void> clearAllData() async {
    try {
      if (!_isInitialized) {
        throw Exception('SalesProvider not initialized');
      }
      
      await SalesService.clearAllData();
      _todaySales = null;
      _yesterdaySales = null;
      _recentTransactions = [];
      notifyListeners();
      print('All sales data cleared successfully');
    } catch (e) {
      print('Error clearing sales data: $e');
      rethrow;
    }
  }

  // Export sales data with error handling
  Map<String, dynamic> exportSalesData() {
    try {
      if (!_isInitialized) {
        return {
          'error': 'SalesProvider not initialized',
          'exportDate': DateTime.now().toIso8601String(),
          'sales': [],
        };
      }
      return SalesService.exportSalesData();
    } catch (e) {
      print('Error exporting sales data: $e');
      return {
        'error': e.toString(),
        'exportDate': DateTime.now().toIso8601String(),
        'sales': [],
      };
    }
  }

  // Force re-initialization (for error recovery)
  Future<void> reinitialize() async {
    _isInitialized = false;
    _initializationError = null;
    await initialize();
  }
}