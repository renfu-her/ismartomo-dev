import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'checkout_page.dart';
import 'product_detail_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _cartItems = [];
  List<dynamic> _totals = [];
  bool _isUpdating = false;
  
  // 產品選項緩存，避免重複請求
  final Map<String, Map<String, dynamic>> _productOptionsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchCartData();
    
    // 測試選項解析功能
    _testOptionsProcessing();
  }

  Future<void> _fetchCartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getCart();
      
      if (response.containsKey('customer_cart')) {
        setState(() {
          _cartItems = response['customer_cart'] ?? [];
          _totals = response['totals'] ?? [];
          _isLoading = false;
        });
        
        // 預加載產品選項信息
        _preloadProductOptions();
      } else {
        setState(() {
          _cartItems = [];
          _totals = [];
          _isLoading = false;
          _errorMessage = '購物車為空';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // 檢查錯誤信息是否包含「用戶未登入」
        if (e.toString().contains('用戶未登入')) {
          _cartItems = [];
          _totals = [];
          _errorMessage = '購物車為空';
        } else {
          _errorMessage = '獲取購物車數據失敗: ${e.toString()}';
        }
      });
    }
  }
  
  // 預加載購物車中所有產品的選項信息
  Future<void> _preloadProductOptions() async {
    for (var item in _cartItems) {
      final productId = item['product_id']?.toString();
      if (productId != null && !_productOptionsCache.containsKey(productId)) {
        try {
          await _getProductOptions(productId);
        } catch (e) {
          // 忽略錯誤，繼續處理其他產品
          debugPrint('獲取產品 $productId 選項失敗: ${e.toString()}');
        }
      }
    }
  }
  
  // 獲取產品選項信息
  Future<Map<String, dynamic>> _getProductOptions(String productId) async {
    // 如果已經有緩存，直接返回
    if (_productOptionsCache.containsKey(productId)) {
      return _productOptionsCache[productId]!;
    }
    
    try {
      // 調用 API 獲取產品詳情
      final response = await _apiService.getProductDetails(productId);
      
      // 檢查響應結構
      if (response.containsKey('product')) {
        Map<String, dynamic> productData;
        
        // 處理不同的響應結構
        if (response['product'] is Map) {
          productData = response['product'];
        } else if (response['product'] is List && response['product'].isNotEmpty) {
          productData = response['product'][0];
        } else {
          productData = {};
        }
        
        // 緩存產品選項信息
        _productOptionsCache[productId] = productData;
        
        // 如果產品數據包含選項，創建簡化的選項結構
        if (productData.containsKey('options') && productData['options'] is List && (productData['options'] as List).isNotEmpty) {
          // 創建簡化的選項結構
          final Map<String, List<String>> simplifiedOptions = createSimplifiedOptions(productData);
          
          // 將簡化的選項結構添加到產品數據中
          productData['simplified_options'] = simplifiedOptions;
          
          debugPrint('產品 $productId 的簡化選項結構已創建: $simplifiedOptions');
        }
        
        return productData;
      }
      
      return {};
    } catch (e) {
      debugPrint('獲取產品選項失敗: ${e.toString()}');
      return {};
    }
  }

  Future<void> _updateCartItemQuantity(String cartId, int newQuantity) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 獲取當前商品的數量
      final currentItem = _cartItems.firstWhere(
        (item) => item['cart_id'] == cartId,
        orElse: () => {'quantity': '0'},
      );
      final currentQuantity = int.tryParse(currentItem['quantity']?.toString() ?? '0') ?? 0;
      
      // 判斷是增加還是減少數量
      final isIncrease = newQuantity > currentQuantity;
      
      // 調用 API 更新數量
      await _apiService.updateCartQuantity(cartId, newQuantity, isIncrease);
      
      // 重新獲取購物車數據
      await _fetchCartData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新數量失敗: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _removeCartItem(String cartId) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 顯示確認對話框
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('確認移除'),
            content: const Text('確定要從購物車中移除此商品嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('確定'),
              ),
            ],
          );
        },
      ) ?? false;
      
      if (!confirmDelete) {
        setState(() {
          _isUpdating = false;
        });
        return;
      }
      
      // 顯示加載指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // 調用 API 移除購物車項目
      await _apiService.removeFromCart(cartId);
      
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 重新獲取購物車數據
      await _fetchCartData();
      
      // 顯示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品已從購物車中移除')),
      );
    } catch (e) {
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 顯示錯誤消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('移除商品失敗: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('購物車'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCartData,
              tooltip: '刷新購物車',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _cartItems.isEmpty
              ? _buildEmptyCart()
              : _cartItems.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return SafeArea(
      child: Column(
        children: [
          // 主要內容區域 - 佔據大部分空間
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 購物車圖標
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 120,
                    color: Colors.grey[350],
                  ),
                  const SizedBox(height: 20),
                  // 空購物車提示文字
                  Text(
                    '您的購物車是空的！',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_errorMessage.isNotEmpty && _errorMessage != '購物車為空')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 200), // 增加底部空間，使按鈕位置更接近圖片
                ],
              ),
            ),
          ),
          
          // 底部按鈕區域
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                  bottom: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // 切換到首頁
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.black),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          '回首頁',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // 購物車商品列表
        Expanded(
          child: ListView.builder(
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item);
            },
          ),
        ),
        
        // 購物車總計
        _buildCartTotals(),
        
        // 結帳按鈕
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 8.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : _proceedToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Colors.black),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        _cartItems.isEmpty ? '購物車是空的' : '前往結帳',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(dynamic item) {
    // 解析選項
    final List<Map<String, String>> options = _parseCartItemOptions(item);
    final int quantity = int.tryParse(item['quantity'].toString()) ?? 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productDetails: {
                  'product_id': item['product_id'],
                  'name': item['name'],
                  'thumb': item['thumb'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                  'options': options,
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品圖片
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    item['thumb'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 商品信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名稱
                    Text(
                      _decodeHtmlEntities(item['name'] ?? '未知商品'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 產品ID (設置為白色，實際上是隱藏)
                    Text(
                      'ID: ${item['product_id']}',
                      style: const TextStyle(
                        fontSize: 1,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 產品選項
                    if (options.isNotEmpty) ...[
                      ...options.map((option) {
                        String displayValue = option['value'] ?? '';
                        String optionName = option['name'] ?? '';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$optionName: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  displayValue,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      Divider(color: Colors.grey[200], height: 16),
                    ],
                    
                    // 價格和數量
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 價格
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '單價: ${item['price'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '小計: ${item['total'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        
                        // 數量調整
                        Row(
                          children: [
                            // 減號按鈕
                            InkWell(
                              onTap: () {
                                if (quantity > 1) {
                                  _updateCartItemQuantity(item['cart_id'], quantity - 1);
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            
                            // 數量顯示
                            Container(
                              width: 40,
                              height: 28,
                              alignment: Alignment.center,
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            
                            // 加號按鈕
                            InkWell(
                              onTap: () {
                                _updateCartItemQuantity(item['cart_id'], quantity + 1);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 刪除按鈕
              InkWell(
                onTap: () {
                  _removeCartItem(item['cart_id']);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartTotals() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          ..._totals.map((total) {
            final bool isTotal = total['code'] == 'total';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _decodeHtmlEntities(total['title'] ?? ''),
                    style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    _decodeHtmlEntities(total['text'] ?? ''),
                    style: TextStyle(
                      fontSize: isTotal ? 18 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // HTML實體解碼
  String _decodeHtmlEntities(String text) {
    return text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&nbsp;', ' ');
  }
  
  // 解析購物車項目中的選項數據
  List<Map<String, String>> _parseCartItemOptions(dynamic item) {
    List<Map<String, String>> options = [];
    
    try {
      // 檢查optiondata字段
      if (item['optiondata'] != null && item['optiondata'] is List) {
        List<dynamic> optionDataList = item['optiondata'];
        
        for (var optionData in optionDataList) {
          String optionId = optionData['product_option_id']?.toString() ?? '';
          String valueId = optionData['product_option_value_id']?.toString() ?? '';
          String productId = item['product_id']?.toString() ?? '';
          
          if (optionId.isNotEmpty && valueId.isNotEmpty && productId.isNotEmpty) {
            // 從產品選項快取中查找選項信息
            if (_productOptionsCache.containsKey(productId)) {
              var productData = _productOptionsCache[productId]!;
              if (productData.containsKey('options') && productData['options'] is List) {
                for (var option in productData['options']) {
                  if (option['product_option_id'].toString() == optionId) {
                    // 查找選項值
                    if (option['product_option_value'] is List) {
                      for (var value in option['product_option_value']) {
                        if (value['product_option_value_id'].toString() == valueId) {
                          options.add({
                            'name': _decodeHtmlEntities(option['name'] ?? ''),
                            'value': _decodeHtmlEntities(value['name'] ?? ''),
                            'option_id': optionId,
                            'value_id': valueId
                          });
                          break;
                        }
                      }
                    }
                    break;
                  }
                }
              }
            }
          }
        }
      }
      
      // 如果optiondata為空，嘗試解析option字段
      if (options.isEmpty && item['option'] != null) {
        Map<String, dynamic> optionsMap;
        if (item['option'] is String) {
          optionsMap = json.decode(item['option']);
        } else if (item['option'] is Map) {
          optionsMap = Map<String, dynamic>.from(item['option']);
        } else {
          return options;
        }
        
        String productId = item['product_id']?.toString() ?? '';
        if (productId.isNotEmpty && _productOptionsCache.containsKey(productId)) {
          var productData = _productOptionsCache[productId]!;
          
          optionsMap.forEach((optionId, valueId) {
            if (productData.containsKey('options') && productData['options'] is List) {
              for (var option in productData['options']) {
                if (option['product_option_id'].toString() == optionId) {
                  if (option['product_option_value'] is List) {
                    for (var value in option['product_option_value']) {
                      if (value['product_option_value_id'].toString() == valueId.toString()) {
                        options.add({
                          'name': _decodeHtmlEntities(option['name'] ?? ''),
                          'value': _decodeHtmlEntities(value['name'] ?? ''),
                          'option_id': optionId,
                          'value_id': valueId.toString()
                        });
                        break;
                      }
                    }
                  }
                  break;
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('解析購物車選項時出錯: $e');
    }
    
    debugPrint('解析到的選項: $options');
    return options;
  }

  // 處理選項映射
  List<Map<String, String>> _processOptionsMap(Map<String, dynamic> optionsMap, String productId) {
    List<Map<String, String>> options = [];
    
    if (_productOptionsCache.containsKey(productId)) {
      var productData = _productOptionsCache[productId]!;
      
      optionsMap.forEach((optionId, valueId) {
        if (productData.containsKey('options') && productData['options'] is List) {
          for (var option in productData['options']) {
            if (option['product_option_id'].toString() == optionId) {
              if (option['product_option_value'] is List) {
                for (var value in option['product_option_value']) {
                  if (value['product_option_value_id'].toString() == valueId.toString()) {
                    options.add({
                      'name': _decodeHtmlEntities(option['name'] ?? ''),
                      'value': _decodeHtmlEntities(value['name'] ?? ''),
                      'option_id': optionId,
                      'value_id': valueId.toString()
                    });
                    break;
                  }
                }
              }
              break;
            }
          }
        }
      });
    }
    
    return options;
  }

  void _proceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CheckoutPage(),
      ),
    ).then((_) {
      // 從結帳頁面返回後刷新購物車數據
      _fetchCartData();
    });
  }

  // 測試選項解析功能
  void _testOptionsProcessing() {
    // 模擬購物車項目中的選項數據
    final testOptionStr = '{"3563":"19189","3564":"19193"}';
    
    debugPrint('===== 測試選項解析功能 =====');
    debugPrint('測試選項字符串: $testOptionStr');
    
    try {
      // 解析選項 JSON
      final Map<String, dynamic> optionsMap = json.decode(testOptionStr);
      debugPrint('解析後的選項映射: $optionsMap');
      
      // 創建模擬的產品選項數據
      final Map<String, dynamic> mockProductData = {
        'options': [
          {
            'product_option_id': '3563',
            'name': 'color(顏色)',
            'product_option_value': [
              {
                'product_option_value_id': '19189',
                'name': '粉紅'
              },
              {
                'product_option_value_id': '19190',
                'name': '藍色'
              }
            ]
          },
          {
            'product_option_id': '3564',
            'name': 'Size(尺寸)',
            'product_option_value': [
              {
                'product_option_value_id': '19193',
                'name': 'L'
              },
              {
                'product_option_value_id': '19194',
                'name': 'M'
              }
            ]
          }
        ]
      };
      
      // 模擬緩存產品選項數據
      _productOptionsCache['3505'] = mockProductData;
      
      // 測試處理選項映射
      final List<Map<String, String>> parsedOptions = _processOptionsMap(optionsMap, '3505');
      
      debugPrint('解析結果: $parsedOptions');
      
      // 將解析結果轉換為 JSON 字符串
      final String parsedOptionsJson = json.encode(parsedOptions);
      debugPrint('解析結果 JSON: $parsedOptionsJson');
      
      // 測試創建簡化的選項結構
      final Map<String, List<String>> simplifiedOptions = createSimplifiedOptions(mockProductData);
      debugPrint('簡化的選項結構: $simplifiedOptions');
      
      // 測試從映射創建選項
      final List<Map<String, String>> createdOptions = createOptionsFromMap(optionsMap, simplifiedOptions);
      debugPrint('從映射創建的選項: $createdOptions');
      
      // 將創建的選項轉換為 JSON 字符串
      final String createdOptionsJson = json.encode(createdOptions);
      debugPrint('創建的選項 JSON: $createdOptionsJson');
      
      // 創建選項示例
      _createOptionsExample();
      
    } catch (e) {
      debugPrint('測試選項解析失敗: ${e.toString()}');
    }
    
    debugPrint('===== 測試結束 =====');
  }
  
  // 創建選項示例
  void _createOptionsExample() {
    debugPrint('===== 創建選項示例 =====');
    
    // 示例產品數據
    final Map<String, dynamic> productData = {
      'product_id': '3505',
      'name': 'test454645',
      'options': [
        {
          'product_option_id': '3563',
          'name': 'color(顏色)',
          'product_option_value': [
            {
              'product_option_value_id': '19189',
              'name': '粉紅'
            },
            {
              'product_option_value_id': '19190',
              'name': '藍色'
            }
          ]
        },
        {
          'product_option_id': '3564',
          'name': 'Size(尺寸)',
          'product_option_value': [
            {
              'product_option_value_id': '19193',
              'name': 'L'
            },
            {
              'product_option_value_id': '19194',
              'name': 'M'
            }
          ]
        }
      ]
    };
    
    // 示例選項映射
    final Map<String, dynamic> optionsMap = {
      '3563': '19189',
      '3564': '19193'
    };
    
    // 創建簡化的選項結構
    final Map<String, List<String>> simplifiedOptions = createSimplifiedOptions(productData);
    debugPrint('簡化的選項結構: $simplifiedOptions');
    
    // 將簡化的選項結構轉換為 JSON 字符串
    final String simplifiedOptionsJson = json.encode(simplifiedOptions);
    debugPrint('簡化的選項結構 JSON: $simplifiedOptionsJson');
    
    // 從映射創建選項
    final List<Map<String, String>> createdOptions = createOptionsFromMap(optionsMap, simplifiedOptions);
    debugPrint('創建的選項: $createdOptions');
    
    // 將創建的選項轉換為 JSON 字符串
    final String createdOptionsJson = json.encode(createdOptions);
    debugPrint('創建的選項 JSON: $createdOptionsJson');
    
    debugPrint('===== 示例結束 =====');
  }
  
  // 創建簡化的選項結構
  Map<String, List<String>> createSimplifiedOptions(Map<String, dynamic> productData) {
    Map<String, List<String>> simplifiedOptions = {};
    
    if (productData.containsKey('options') && productData['options'] is List) {
      final List<dynamic> options = productData['options'];
      
      for (var option in options) {
        if (option.containsKey('product_option_id') && 
            option.containsKey('name') && 
            option.containsKey('product_option_value') && 
            option['product_option_value'] is List) {
          
          final String optionId = option['product_option_id'].toString();
          final String optionName = _decodeHtmlEntities(option['name'] ?? '');
          final List<dynamic> optionValues = option['product_option_value'];
          
          // 創建選項值映射
          List<List<String>> values = [];
          
          for (var value in optionValues) {
            if (value.containsKey('product_option_value_id') && value.containsKey('name')) {
              final String valueId = value['product_option_value_id'].toString();
              final String valueName = _decodeHtmlEntities(value['name'] ?? '');
              
              values.add([valueId, valueName, optionName]);
            }
          }
          
          simplifiedOptions[optionId] = values.expand((v) => v).toList();
        }
      }
    }
    
    return simplifiedOptions;
  }
  
  // 從映射創建選項
  List<Map<String, String>> createOptionsFromMap(
    Map<String, dynamic> optionsMap, 
    Map<String, List<String>> simplifiedOptions
  ) {
    List<Map<String, String>> parsedOptions = [];
    
    optionsMap.forEach((optionId, valueId) {
      if (simplifiedOptions.containsKey(optionId)) {
        final List<String> values = simplifiedOptions[optionId]!;
        
        // 查找匹配的值 ID
        for (int i = 0; i < values.length; i += 3) {
          if (values[i] == valueId.toString()) {
            parsedOptions.add({
              'name': values[i + 2],
              'value': values[i + 1],
              'option_id': optionId,
              'value_id': valueId.toString()
            });
            break;
          }
        }
      }
    });
    
    return parsedOptions;
  }
} 