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
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // 切換到首頁
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  '回首頁',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
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
        SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: 12.0,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 導航到結帳頁面
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CheckoutPage(),
                    ),
                  ).then((_) {
                    // 從結帳頁面返回後刷新購物車數據
                    _fetchCartData();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.black),
                ),
                child: const Text(
                  '前往結帳',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(dynamic item) {
    final int quantity = int.tryParse(item['quantity'].toString()) ?? 1;
    
    // 解析選項
    final List<Map<String, String>> options = _parseCartItemOptions(item);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // 跳轉到產品詳情頁面
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productDetails: {
                  'product_id': item['product_id'],
                  'name': item['name'],
                  'thumb': item['thumb'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                  'options': item['option'],
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
                    // 商品名稱 - 使用HTML實體轉換
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
                    
                    // 產品選項 - 顯示在單價上方
                    if (options.isNotEmpty) ...[
                      ...options.map((option) => Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${option['name']}: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                option['value'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      
                      // 如果有選項，添加一個分隔線
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

  // 輔助方法：將HTML實體轉換為實際字符
  String _decodeHtmlEntities(String text) {
    if (text.isEmpty) {
      return '';
    }
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™');
  }
  
  // 解析購物車項目中的選項數據
  List<Map<String, String>> _parseCartItemOptions(dynamic item) {
    List<Map<String, String>> parsedOptions = [];
    
    // 優先使用 optiondata 欄位，如果存在
    if (item.containsKey('optiondata') && item['optiondata'] is List) {
      final List<dynamic> optionDataList = item['optiondata'];
      debugPrint('使用 optiondata 欄位，選項數量: ${optionDataList.length}');
      
      for (var option in optionDataList) {
        if (option is Map && option.containsKey('name') && option.containsKey('value')) {
          parsedOptions.add({
            'name': _decodeHtmlEntities(option['name'] ?? ''),
            'value': _decodeHtmlEntities(option['value'] ?? ''),
            'option_id': option['product_option_id']?.toString() ?? '',
            'value_id': option['product_option_value_id']?.toString() ?? ''
          });
        }
      }
      
      // 如果成功解析了選項，直接返回
      if (parsedOptions.isNotEmpty) {
        debugPrint('從 optiondata 成功解析選項: $parsedOptions');
        return parsedOptions;
      }
    }
    
    // 如果 optiondata 為空或解析失敗，嘗試使用 option 欄位
    if (item.containsKey('option')) {
      try {
        debugPrint('嘗試從 option 欄位解析選項，產品ID: ${item['product_id']}，選項數據: ${item['option']}');
        
        // 處理不同格式的選項數據
        if (item['option'] is String) {
          final String optionStr = item['option'];
          
          // 檢查是否為空選項
          if (optionStr == "[]" || optionStr.isEmpty) {
            debugPrint('選項為空，返回空列表');
            return parsedOptions;
          }
          
          // 解析選項JSON
          final Map<String, dynamic> optionsMap = json.decode(optionStr);
          debugPrint('解析後的選項映射: $optionsMap');
          return _processOptionsMap(item['product_id']?.toString() ?? '', optionsMap);
        } 
        // 處理已經是列表的選項
        else if (item['option'] is List) {
          final List<dynamic> optionsList = item['option'];
          debugPrint('選項是列表格式: $optionsList');
          
          // 直接返回選項列表
          for (var option in optionsList) {
            if (option is Map && option.containsKey('name') && option.containsKey('value')) {
              parsedOptions.add({
                'name': _decodeHtmlEntities(option['name'] ?? ''),
                'value': _decodeHtmlEntities(option['value'] ?? '')
              });
            }
          }
          
          return parsedOptions;
        }
        // 處理已經是Map的選項
        else if (item['option'] is Map) {
          final Map<String, dynamic> optionsMap = Map<String, dynamic>.from(item['option']);
          debugPrint('選項是映射格式: $optionsMap');
          return _processOptionsMap(item['product_id']?.toString() ?? '', optionsMap);
        }
      } catch (e) {
        debugPrint('解析選項失敗: ${e.toString()}');
      }
    }
    
    return parsedOptions;
  }
  
  // 處理選項映射
  List<Map<String, String>> _processOptionsMap(String productId, Map<String, dynamic> optionsMap) {
    List<Map<String, String>> parsedOptions = [];
    
    debugPrint('處理選項映射，產品ID: $productId，選項映射: $optionsMap');
    
    // 獲取產品詳情以獲取選項名稱
    if (productId.isNotEmpty && _productOptionsCache.containsKey(productId)) {
      final productData = _productOptionsCache[productId];
      debugPrint('找到產品緩存數據: ${productData != null}');
      
      // 檢查產品數據中是否包含選項
      if (productData != null && productData.containsKey('options') && productData['options'] is List) {
        final List<dynamic> productOptions = productData['options'];
        debugPrint('產品選項數量: ${productOptions.length}');
        
        // 遍歷選項映射
        optionsMap.forEach((optionId, valueId) {
          debugPrint('處理選項 ID: $optionId，值 ID: $valueId');
          
          // 在產品選項中查找匹配的選項
          for (var option in productOptions) {
            if (option['product_option_id'].toString() == optionId) {
              String optionName = _decodeHtmlEntities(option['name'] ?? '');
              String valueName = '';
              
              debugPrint('找到匹配的選項: $optionName (ID: $optionId)');
              
              // 在選項值中查找匹配的值
              if (option.containsKey('product_option_value') && option['product_option_value'] is List) {
                final List<dynamic> optionValues = option['product_option_value'];
                debugPrint('選項值數量: ${optionValues.length}');
                
                for (var value in optionValues) {
                  if (value['product_option_value_id'].toString() == valueId.toString()) {
                    valueName = _decodeHtmlEntities(value['name'] ?? '');
                    debugPrint('找到匹配的選項值: $valueName (ID: $valueId)');
                    break;
                  }
                }
              }
              
              // 如果找到了選項名稱和值，添加到解析結果中
              if (optionName.isNotEmpty && valueName.isNotEmpty) {
                debugPrint('添加解析結果: $optionName: $valueName');
                parsedOptions.add({
                  'name': optionName,
                  'value': valueName,
                  'option_id': optionId,
                  'value_id': valueId.toString()
                });
              } else {
                debugPrint('未找到完整的選項名稱和值');
              }
              
              break;
            }
          }
        });
      } else {
        debugPrint('產品數據中沒有選項信息');
      }
    } else {
      debugPrint('產品ID為空或未找到產品緩存數據');
    }
    
    debugPrint('解析結果: $parsedOptions');
    return parsedOptions;
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
      final List<Map<String, String>> parsedOptions = _processOptionsMap('3505', optionsMap);
      
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