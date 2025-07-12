import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/menu_data.dart';
import '../model/order_model.dart';
import '../services/order_provider.dart';
import '../services/hybrid_address_service.dart';
import '../Screens/order_summary.dart';
import '../Screens/menu_item_screen.dart';

class TakeawayOrderScreen extends StatefulWidget {
  const TakeawayOrderScreen({Key? key}) : super(key: key);

  @override
  _TakeawayOrderScreenState createState() => _TakeawayOrderScreenState();
}

class _TakeawayOrderScreenState extends State<TakeawayOrderScreen> {
  String selectedCategory = 'Starters';
  bool showCustomerForm = false;
  bool showSearch = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  List<MenuItem> searchResults = [];
  String lastSearchQuery = '';
  List<String> foundAddresses = [];
  String? selectedAddress;
  bool isLookingUp = false;
  
  // NEW: Hybrid address service variables
  late final HybridAddressService hybridAddressService;
  AddressLookupResult? _lastLookupResult;

  @override
  void initState() {
    super.initState();
    
    // Initialize hybrid address service
    final apiKey = dotenv.env['GETADDRESS_API_KEY'];
    hybridAddressService = HybridAddressService(apiKey);
    
    // Log API key status for debugging
    if (apiKey == null || apiKey.isEmpty) {
      print('Warning: GETADDRESS_API_KEY not found in .env file. Will use Postcodes.io and manual entry.');
    } else {
      print('✓ GetAddress API key loaded successfully');
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .setOrderType('takeaway');
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    postcodeController.dispose();
    addressController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    lastSearchQuery = query;

    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      searchResults = MenuData.getAllMenuItems()
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              (item.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      showSearch = !showSearch;
      if (showSearch) {
        // Auto-focus search field when opened
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNode.requestFocus();
        });
      } else {
        // Clear search when closing
        searchController.clear();
        searchResults.clear();
        lastSearchQuery = '';
      }
    });
  }

  // UPDATED: Smart address lookup using hybrid service
  Future<void> _smartAddressLookup() async {
    if (postcodeController.text.isEmpty) {
      _showSnackBar('Please enter a postcode');
      return;
    }

    // Validate basic format first
    if (!hybridAddressService.isValidUKPostcodeFormat(postcodeController.text)) {
      _showSnackBar('Please enter a valid UK postcode (e.g., SW1A 1AA)');
      return;
    }

    setState(() {
      isLookingUp = true;
      foundAddresses = [];
      selectedAddress = null;
      _lastLookupResult = null;
    });

    try {
      final result = await hybridAddressService.lookupAddresses(postcodeController.text);
      
      setState(() {
        _lastLookupResult = result;
        foundAddresses = result.addresses;
        isLookingUp = false;
      });

      // Show appropriate feedback based on result
      if (result.success) {
        if (result.addresses.isNotEmpty) {
          _showSnackBar('Found ${result.addresses.length} addresses via ${hybridAddressService.getProviderName(result.provider)}');
        } else if (result.provider == AddressProvider.postcodesIo) {
          if (result.geocodingData?['within_delivery_radius'] == true) {
            _showSnackBar('Postcode validated! Please enter your address manually.');
          }
        }
      } else if (result.error != null) {
        _showSnackBar(result.error!);
      }
      
    } catch (e) {
      setState(() {
        isLookingUp = false;
        _lastLookupResult = null;
      });
      _showSnackBar('Error looking up addresses: ${e.toString()}');
    }
  }

  // UPDATED: Handle address selection from dropdown
  void _selectAddress(String? address) {
    if (address != null) {
      setState(() {
        selectedAddress = address;
        addressController.text = address; // Populate the address field
        
        // Close the dropdown by clearing the results
        foundAddresses = [];
        _lastLookupResult = null;
      });
      
      // Update the order provider with the selected address
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.updateCustomerInfo(address: address);
      
      _showSnackBar('✓ Address selected and auto-filled');
    }
  }

  // Handle manual address field changes
  void _onAddressChanged(String value) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.updateCustomerInfo(address: value);
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // If search is open, close it first
    if (showSearch) {
      _toggleSearch();
      return false;
    }

    // If customer form is shown, go back to menu
    if (showCustomerForm) {
      setState(() {
        showCustomerForm = false;
      });
      return false;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Check if there are items in the cart
    if (orderProvider.orderItems.isNotEmpty) {
      // Show confirmation dialog
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Discard Order?'),
            content: const Text(
                'Are you sure you want to dismiss this order? All items will be lost.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Don't discard (cancel)
                },
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Clear the cart and return to home
                  orderProvider.clearOrder();
                  Navigator.of(context).pop(true); // Discard order
                },
                child:
                    const Text('DISCARD', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
      return shouldPop ?? false;
    }

    return true; // If no items in cart, allow back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(showSearch ? 'Search Dishes' : 'Takeaway Order'),
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(showSearch ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
              tooltip: showSearch ? 'Close Search' : 'Search',
            ),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        if (orderProvider.orderItems.isNotEmpty) {
                          setState(() {
                            showCustomerForm = true;
                          });
                        } else {
                          _showSnackBar('Add items to cart first');
                        }
                      },
                    ),
                    if (orderProvider.totalItems > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${orderProvider.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: showCustomerForm
            ? _buildCustomerForm()
            : _buildCategoryAndMenuScreen(),
      ),
    );
  }

  Widget _buildCategoryAndMenuScreen() {
    return Column(
      children: [
        // Search bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: showSearch ? 80 : 0,
          child: showSearch
              ? Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange[50],
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search by name, description, or category...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onChanged: _performSearch,
                    textInputAction: TextInputAction.search,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Horizontal category list (hidden when searching)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: showSearch ? 0 : 48,
          child: !showSearch
              ? Container(
                  color: Colors.orange[50],
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: MenuData.getCategories().length,
                    itemBuilder: (context, index) {
                      String category = MenuData.getCategories()[index];
                      bool isSelected = category == selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange[600]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange[600]!
                                    : Colors.grey[400]!,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Category title and items
        Expanded(
          child: showSearch ? _buildSearchResults() : _buildMenuItems(),
        ),

        // Order summary footer
        _buildOrderSummaryFooter(),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastSearchQuery.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      searchResults.isEmpty
                          ? 'No dishes found for "$lastSearchQuery"'
                          : '${searchResults.length} ${searchResults.length == 1 ? 'dish' : 'dishes'} found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  if (searchResults.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        searchController.clear();
                        _performSearch('');
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          lastSearchQuery.isEmpty
                              ? Icons.search
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lastSearchQuery.isEmpty
                              ? 'Start typing to search for dishes'
                              : 'No dishes match your search.\nTry different keywords.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      MenuItem item = searchResults[index];
                      return _buildMenuItem(item, highlightSearch: true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    List<MenuItem> items = MenuData.getItemsByCategory(selectedCategory);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Text(
                  selectedCategory,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${items.length} ${items.length == 1 ? 'item' : 'items'})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No items in this category',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 16)))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      MenuItem item = items[index];
                      return _buildMenuItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item, {bool highlightSearch = false}) {
    // Helper to highlight search terms
    Widget _highlightText(String text, {TextStyle? style}) {
      if (!highlightSearch || lastSearchQuery.isEmpty) {
        return Text(text, style: style);
      }

      final searchLower = lastSearchQuery.toLowerCase();
      final textLower = text.toLowerCase();

      if (!textLower.contains(searchLower)) {
        return Text(text, style: style);
      }

      final startIndex = textLower.indexOf(searchLower);
      final endIndex = startIndex + searchLower.length;

      return RichText(
        text: TextSpan(
          style: style ?? const TextStyle(color: Colors.black),
          children: [
            TextSpan(text: text.substring(0, startIndex)),
            TextSpan(
              text: text.substring(startIndex, endIndex),
              style: TextStyle(
                backgroundColor: Colors.yellow.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: text.substring(endIndex)),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: InkWell(
        onTap: () {
          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuItemDetailScreen(menuItem: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name
                    _highlightText(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Category (always shown in search results)
                    if (showSearch || highlightSearch) ...[
                      const SizedBox(height: 2),
                      _highlightText(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    // Description if available
                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      _highlightText(
                        item.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Price - Show takeaway price
                    Row(
                      children: [
                        Text(
                          '£${item.getTakeawayPrice().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        if (item.takeawayPrice != null &&
                            item.takeawayPrice != item.price) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(Takeaway)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Add button
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryFooter() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.orderItems.isEmpty) {
          return const SizedBox.shrink(); // No footer if cart is empty
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Order summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${orderProvider.totalItems} ${orderProvider.totalItems == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '£${orderProvider.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // View order button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showCustomerForm = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'View Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          showCustomerForm = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...orderProvider.orderItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.menuItem.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if (item.specialInstructions != null)
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    orderProvider.removeItem(
                                        orderProvider.orderItems.indexOf(item));
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(
                                '£${orderProvider.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (orderProvider.deliveryCharge > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery:'),
                              Text(
                                  '£${orderProvider.deliveryCharge.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
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
                              '£${orderProvider.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Collection/Delivery Toggle
                const Text(
                  'Order Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Collection'),
                        selected: !orderProvider.customerInfo.isDelivery,
                        onSelected: (selected) {
                          if (selected) {
                            orderProvider.updateCustomerInfo(isDelivery: false);
                            orderProvider.setDeliveryCharge(0.0);
                            // Clear delivery-specific fields
                            setState(() {
                              postcodeController.clear();
                              addressController.clear();
                              foundAddresses = [];
                              selectedAddress = null;
                              _lastLookupResult = null;
                            });
                          }
                        },
                        labelStyle: TextStyle(
                          color: !orderProvider.customerInfo.isDelivery
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Delivery'),
                        selected: orderProvider.customerInfo.isDelivery,
                        onSelected: (selected) {
                          if (selected) {
                            orderProvider.updateCustomerInfo(isDelivery: true);
                            orderProvider.setDeliveryCharge(2.50);
                          }
                        },
                        labelStyle: TextStyle(
                          color: orderProvider.customerInfo.isDelivery
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Name
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    orderProvider.updateCustomerInfo(name: value);
                  },
                ),

                // DELIVERY ADDRESS SECTION
                if (orderProvider.customerInfo.isDelivery) 
                  _buildDeliveryAddressSection(orderProvider),

                const SizedBox(height: 16),
                
                // Phone Number
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'e.g., 07700 900123',
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    orderProvider.updateCustomerInfo(phoneNumber: value);
                  },
                ),

                const SizedBox(height: 24),

                // Payment Method
                const Text('Payment Method:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('None'),
                        selected: orderProvider.paymentMethod == 'none',
                        onSelected: (selected) {
                          if (selected) orderProvider.setPaymentMethod('none');
                        },
                        labelStyle: TextStyle(
                          color: orderProvider.paymentMethod == 'none'
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Cash'),
                        selected: orderProvider.paymentMethod == 'cash',
                        onSelected: (selected) {
                          if (selected) orderProvider.setPaymentMethod('cash');
                        },
                        labelStyle: TextStyle(
                          color: orderProvider.paymentMethod == 'cash'
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Card'),
                        selected: orderProvider.paymentMethod == 'card',
                        onSelected: (selected) {
                          if (selected) orderProvider.setPaymentMethod('card');
                        },
                        labelStyle: TextStyle(
                          color: orderProvider.paymentMethod == 'card'
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: Colors.orange[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canProceed(orderProvider)
                        ? () async {
                            if (mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrderSummaryScreen(),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Review Order',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  // NEW: Enhanced delivery address section with hybrid service
  Widget _buildDeliveryAddressSection(OrderProvider orderProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        // Postcode Input with Smart Lookup
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: postcodeController,
                decoration: InputDecoration(
                  labelText: 'Postcode *',
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., SW1A 1AA',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: postcodeController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            postcodeController.clear();
                            addressController.clear();
                            setState(() {
                              foundAddresses = [];
                              selectedAddress = null;
                              _lastLookupResult = null;
                            });
                            orderProvider.updateCustomerInfo(postcode: '', address: '');
                          },
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  orderProvider.updateCustomerInfo(postcode: value);
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isLookingUp ? null : _smartAddressLookup,
              icon: isLookingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(isLookingUp ? 'Searching...' : 'Find'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Address Input Field (Always Visible)
        TextFormField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: 'Full Address *',
            border: const OutlineInputBorder(),
            hintText: 'Enter your complete delivery address',
            prefixIcon: const Icon(Icons.home),
            helperText: foundAddresses.isNotEmpty 
                ? 'Select from suggestions below or type manually'
                : 'Enter your full delivery address',
            helperMaxLines: 2,
          ),
          onChanged: _onAddressChanged,
          maxLines: 2,
          textCapitalization: TextCapitalization.words,
        ),
        
        // Smart Address Results Section
        if (isLookingUp) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Searching for addresses...'),
              ],
            ),
          ),
        ],
        
        // Address Selection Results
        if (_lastLookupResult != null && !isLookingUp) ...[
          const SizedBox(height: 16),
          _buildAddressResults(),
        ],
      ],
    );
  }

  Widget _buildAddressResults() {
    if (_lastLookupResult == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getResultContainerColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getResultBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getResultIcon(), color: _getResultIconColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getResultTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getResultTextColor(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProviderChipColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hybridAddressService.getProviderName(_lastLookupResult!.provider),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          
          // Show distance info if available
          if (_lastLookupResult!.geocodingData?['distance_km'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.navigation, size: 16, color: _getResultIconColor()),
                const SizedBox(width: 4),
                Text(
                  '${_lastLookupResult!.geocodingData!['distance_km']}km from restaurant',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getResultTextColor(),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Show addresses if available
          if (foundAddresses.isNotEmpty) ...[
            const Text('Select your address:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...foundAddresses.asMap().entries.map((entry) {
              final index = entry.key;
              final address = entry.value;
              final isSelected = selectedAddress == address;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _selectAddress(address),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[400],
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Colors.blue[600], size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ] else if (_lastLookupResult!.provider == AddressProvider.postcodesIo) ...[
            if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == true) ...[
              Text(
                'Postcode validated! Please type your full address in the field above.',
                style: TextStyle(
                  color: _getResultTextColor(),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Text(
                _lastLookupResult!.error ?? 'Outside delivery area',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ] else if (_lastLookupResult!.error != null) ...[
            Text(
              _lastLookupResult!.error!,
              style: TextStyle(
                color: _getResultTextColor(),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for dynamic styling
  Color _getResultContainerColor() {
    if (_lastLookupResult == null) return Colors.grey[50]!;
    
    // Check for delivery area issues first
    if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == false) {
      return Colors.red[50]!;
    }
    
    switch (_lastLookupResult!.provider) {
      case AddressProvider.getAddress:
        return foundAddresses.isNotEmpty ? Colors.green[50]! : Colors.orange[50]!;
      case AddressProvider.postcodesIo:
        return Colors.blue[50]!;
      case AddressProvider.manual:
        return Colors.grey[50]!;
    }
  }

  Color _getResultBorderColor() {
    if (_lastLookupResult == null) return Colors.grey[200]!;
    
    if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == false) {
      return Colors.red[200]!;
    }
    
    switch (_lastLookupResult!.provider) {
      case AddressProvider.getAddress:
        return foundAddresses.isNotEmpty ? Colors.green[200]! : Colors.orange[200]!;
      case AddressProvider.postcodesIo:
        return Colors.blue[200]!;
      case AddressProvider.manual:
        return Colors.grey[200]!;
    }
  }

  IconData _getResultIcon() {
    if (_lastLookupResult == null) return Icons.info;
    
    if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == false) {
      return Icons.error_outline;
    }
    
    switch (_lastLookupResult!.provider) {
      case AddressProvider.getAddress:
        return foundAddresses.isNotEmpty ? Icons.location_on : Icons.warning;
      case AddressProvider.postcodesIo:
        return Icons.verified;
      case AddressProvider.manual:
        return Icons.edit_location;
    }
  }

  Color _getResultIconColor() {
    if (_lastLookupResult == null) return Colors.grey[600]!;
    
    if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == false) {
      return Colors.red[600]!;
    }
    
    switch (_lastLookupResult!.provider) {
      case AddressProvider.getAddress:
        return foundAddresses.isNotEmpty ? Colors.green[600]! : Colors.orange[600]!;
      case AddressProvider.postcodesIo:
        return Colors.blue[600]!;
      case AddressProvider.manual:
        return Colors.grey[600]!;
    }
  }

  Color _getResultTextColor() {
    if (_lastLookupResult == null) return Colors.grey[700]!;
    
    if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == false) {
      return Colors.red[700]!;
    }
    
    switch (_lastLookupResult!.provider) {
      case AddressProvider.getAddress:
        return foundAddresses.isNotEmpty ? Colors.green[700]! : Colors.orange[700]!;
      case AddressProvider.postcodesIo:
        return Colors.blue[700]!;
      case AddressProvider.manual:
        return Colors.grey[700]!;
    }
  }

  String _getResultTitle() {
    if (_lastLookupResult == null) return 'Enter postcode to find addresses';
    
    if (_lastLookupResult!.geocodingData?['within_delivery_radius'] == false) {
      return 'Outside delivery area';
    }
    
    if (foundAddresses.isNotEmpty) {
      return 'Found ${foundAddresses.length} addresses';
    } else {
      switch (_lastLookupResult!.provider) {
        case AddressProvider.getAddress:
          return 'No addresses found via GetAddress.io';
        case AddressProvider.postcodesIo:
          return 'Postcode validated via Postcodes.io';
        case AddressProvider.manual:
          return 'Manual address entry required';
      }
    }
  }

  Color _getProviderChipColor() {
    if (_lastLookupResult == null) return Colors.grey[200]!;
    
    switch (_lastLookupResult!.provider) {
      case AddressProvider.getAddress:
        return Colors.green[200]!;
      case AddressProvider.postcodesIo:
        return Colors.blue[200]!;
      case AddressProvider.manual:
        return Colors.grey[200]!;
    }
  }

  bool _canProceed(OrderProvider orderProvider) {
    bool hasName = orderProvider.customerInfo.name?.isNotEmpty == true;
    bool hasPhone = orderProvider.customerInfo.phoneNumber?.isNotEmpty == true;

    if (orderProvider.customerInfo.isDelivery) {
      bool hasAddress = orderProvider.customerInfo.address?.isNotEmpty == true;
      bool hasPostcode = orderProvider.customerInfo.postcode?.isNotEmpty == true;
      
      // Check if delivery is allowed (not outside delivery area)
      bool deliveryAllowed = _lastLookupResult?.geocodingData?['within_delivery_radius'] != false;
      
      return hasName && hasAddress && hasPostcode && hasPhone && deliveryAllowed;
    }

    return hasName && hasPhone;
  }
}