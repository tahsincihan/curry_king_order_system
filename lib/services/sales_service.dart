import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../model/sales_model.dart';
import '../model/order_model.dart';
import 'customer_service.dart';

class SalesService {
  static const String _salesBoxName = 'daily_sales';
  static Box<DailySales>? _salesBox;
  static bool _isInitialized = false;

  // Initialize Hive and open the sales box with comprehensive error handling
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('SalesService already initialized');
      return;
    }

    try {
      print('Starting Hive initialization...');
      
      // Initialize Hive with proper path
      try {
        await Hive.initFlutter();
        print('✓ Hive initialized successfully');
      } catch (e) {
        print('Hive initFlutter failed, trying manual path setup: $e');
        
        // Fallback: try manual initialization
        try {
          final appDocumentDir = await getApplicationDocumentsDirectory();
          final hiveDir = Directory('${appDocumentDir.path}/hive_boxes');
          if (!await hiveDir.exists()) {
            await hiveDir.create(recursive: true);
          }
          Hive.init(hiveDir.path);
          print('✓ Hive initialized with manual path');
        } catch (e2) {
          print('Manual Hive initialization also failed: $e2');
          // Try with temp directory as last resort
          final tempDir = await getTemporaryDirectory();
          Hive.init(tempDir.path);
          print('✓ Hive initialized with temp directory');
        }
      }

      // Register adapters if not already registered
      try {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(DailySalesAdapter());
          print('✓ DailySalesAdapter registered');
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(SaleTransactionAdapter());
          print('✓ SaleTransactionAdapter registered');
        }
      } catch (e) {
        print('Error registering adapters: $e');
        // Continue anyway - adapters might already be registered
      }

      // Open the sales box with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          _salesBox = await Hive.openBox<DailySales>(_salesBoxName);
          print('✓ Sales box opened successfully');
          break;
        } catch (e) {
          retryCount++;
          print('Error opening sales box (attempt $retryCount/$maxRetries): $e');
          
          if (retryCount == maxRetries) {
            // Last resort: try to delete corrupted box and create new one
            try {
              await Hive.deleteBoxFromDisk(_salesBoxName);
              print('Deleted corrupted box, creating new one...');
              _salesBox = await Hive.openBox<DailySales>(_salesBoxName);
              print('✓ New sales box created successfully');
              break;
            } catch (e2) {
              print('Failed to create new box: $e2');
              throw Exception('Failed to initialize sales database after $maxRetries attempts');
            }
          } else {
            // Wait before retry
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      // Clean up old data on initialization
      try {
        await _cleanupOldData();
        print('✓ Old data cleanup completed');
      } catch (e) {
        print('Warning: Old data cleanup failed: $e');
        // Continue anyway
      }

      // Initialize customer service as well
      try {
        await CustomerService.initialize();
        print('✓ Customer service initialized from sales service');
      } catch (e) {
        print('Warning: Customer service initialization failed: $e');
        // Continue anyway - customer features will be disabled
      }

      _isInitialized = true;
      print('✓ SalesService initialization completed successfully');
      
    } catch (e, stackTrace) {
      print('❌ Critical error during SalesService initialization: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  // Check if service is initialized
  static bool get isInitialized => _isInitialized;

  // Get today's date in yyyy-MM-dd format
  static String _getTodayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Get yesterday's date in yyyy-MM-dd format
  static String _getYesterdayKey() {
    return DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
  }

  // Add a sale transaction with error handling
  static Future<void> addSale(Order order) async {
    if (!_isInitialized || _salesBox == null) {
      throw Exception('SalesService not initialized');
    }

    try {
      final today = _getTodayKey();

      // Get or create today's sales record
      DailySales? todaySales = _salesBox!.get(today);
      if (todaySales == null) {
        todaySales = DailySales(date: today, transactions: []);
        print('Created new daily sales record for $today');
      }

      // Convert order items to a storable format
      final storableItems = order.items.map((item) {
        return {
          'name': item.menuItem.name,
          'quantity': item.quantity,
          'price': item.menuItem.price, // Price per item at time of sale
          'specialInstructions': item.specialInstructions,
        };
      }).toList();

      // Create transaction record
      final transaction = SaleTransaction(
        orderId: order.id,
        timestamp: order.orderTime,
        amount: order.total,
        paymentMethod: order.paymentMethod,
        orderType: order.orderType,
        deliveryCharge: order.deliveryCharge,
        itemCount: order.totalItems,
        customerName: order.customerInfo.name,
        tableNumber: order.tableNumber,
        items: storableItems,
      );

      // Add transaction to today's sales
      todaySales.addTransaction(transaction);

      // Save to Hive with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await _salesBox!.put(today, todaySales);
          print('Sale saved successfully: £${order.total.toStringAsFixed(2)}');
          break;
        } catch (e) {
          retryCount++;
          print('Error saving sale (attempt $retryCount/$maxRetries): $e');
          
          if (retryCount == maxRetries) {
            throw Exception('Failed to save sale after $maxRetries attempts: $e');
          }
          
          await Future.delayed(Duration(milliseconds: 100 * retryCount));
        }
      }

      // Save customer information if it's a delivery order
      try {
        if (CustomerService.isInitialized) {
          await CustomerService.saveCustomerFromOrder(order);
          print('Customer information processed for order ${order.id}');
        } else {
          print('CustomerService not initialized, skipping customer save');
        }
      } catch (e) {
        print('Warning: Failed to save customer information: $e');
        // Don't rethrow - sale should still succeed even if customer save fails
      }
      
    } catch (e) {
      print('Error in addSale: $e');
      rethrow;
    }
  }

  // Get today's sales with error handling
  static DailySales? getTodaySales() {
    if (!_isInitialized || _salesBox == null) {
      print('Warning: SalesService not initialized, returning null for today\'s sales');
      return null;
    }

    try {
      return _salesBox!.get(_getTodayKey());
    } catch (e) {
      print('Error getting today\'s sales: $e');
      return null;
    }
  }

  // Get yesterday's sales with error handling
  static DailySales? getYesterdaySales() {
    if (!_isInitialized || _salesBox == null) {
      print('Warning: SalesService not initialized, returning null for yesterday\'s sales');
      return null;
    }

    try {
      return _salesBox!.get(_getYesterdayKey());
    } catch (e) {
      print('Error getting yesterday\'s sales: $e');
      return null;
    }
  }

  // Get all available sales data with error handling
  static List<DailySales> getAllSales() {
    if (!_isInitialized || _salesBox == null) {
      print('Warning: SalesService not initialized, returning empty list');
      return [];
    }

    try {
      return _salesBox!.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    } catch (e) {
      print('Error getting all sales: $e');
      return [];
    }
  }

  // Get sales summary for the last 2 days with error handling
  static Map<String, double> getSalesSummary() {
    try {
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

  // Clean up data to keep only the current day's records
  static Future<void> _cleanupOldData() async {
    if (!_isInitialized || _salesBox == null) {
      return;
    }

    try {
      final todayKey = _getTodayKey();

      // Find all keys that are NOT today's key
      final keysToDelete = _salesBox!.keys
          .where((key) => key.toString() != todayKey)
          .toList();

      // Delete all records except today's
      for (final key in keysToDelete) {
        try {
          await _salesBox!.delete(key);
        } catch (e) {
          print('Warning: Could not delete key $key: $e');
        }
      }

      if (keysToDelete.isNotEmpty) {
        print('Cleaned up ${keysToDelete.length} old sales records');
      }
    } catch (e) {
      print('Error during cleanup: $e');
      // Don't rethrow - cleanup errors shouldn't break the app
    }
  }

  // Manual cleanup method (can be called from UI)
  static Future<void> cleanupOldData() async {
    await _cleanupOldData();
  }

  // Get transactions for a specific date with error handling
  static List<SaleTransaction> getTransactionsForDate(String date) {
    if (!_isInitialized || _salesBox == null) {
      return [];
    }

    try {
      final salesData = _salesBox!.get(date);
      return salesData?.transactions ?? [];
    } catch (e) {
      print('Error getting transactions for date $date: $e');
      return [];
    }
  }

  // Export sales data with error handling
  static Map<String, dynamic> exportSalesData() {
    try {
      final allSales = getAllSales();
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'sales': allSales
            .map((sales) => {
                  'date': sales.date,
                  'cashSales': sales.cashSales,
                  'cardSales': sales.cardSales,
                  'totalOrders': sales.totalOrders,
                  'deliveryCharges': sales.deliveryCharges,
                  'transactions': sales.transactions
                      .map((t) => {
                            'orderId': t.orderId,
                            'timestamp': t.timestamp.toIso8601String(),
                            'amount': t.amount,
                            'paymentMethod': t.paymentMethod,
                            'orderType': t.orderType,
                            'deliveryCharge': t.deliveryCharge,
                            'itemCount': t.itemCount,
                            'customerName': t.customerName,
                            'tableNumber': t.tableNumber,
                          })
                      .toList(),
                })
            .toList(),
      };
    } catch (e) {
      print('Error exporting sales data: $e');
      return {
        'error': e.toString(),
        'exportDate': DateTime.now().toIso8601String(),
        'sales': [],
      };
    }
  }

  // Clear all sales data (for testing or reset) with error handling
  static Future<void> clearAllData() async {
    if (!_isInitialized || _salesBox == null) {
      throw Exception('SalesService not initialized');
    }

    try {
      await _salesBox!.clear();
      print('All sales data cleared successfully');
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  // Close the database (for cleanup)
  static Future<void> close() async {
    try {
      if (_salesBox != null && _salesBox!.isOpen) {
        await _salesBox!.close();
        print('Sales box closed successfully');
      }
      _isInitialized = false;
    } catch (e) {
      print('Error closing sales box: $e');
    }
  }

  // Reinitialize the service (for error recovery)
  static Future<void> reinitialize() async {
    try {
      await close();
      await initialize();
      print('SalesService reinitialized successfully');
    } catch (e) {
      print('Error during reinitialize: $e');
      rethrow;
    }
  }
}