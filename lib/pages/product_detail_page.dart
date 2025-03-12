import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productDetails;

  const ProductDetailPage({
    super.key,
    required this.productDetails,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _productData = {};
  int _quantity = 1;
  // 使用 Map 存儲不同選項類型的選擇
  Map<String, String> _selectedOptions = {};
  double _basePrice = 0.0; // 基本價格
  double _finalPrice = 0.0; // 最終價格（含選項）
  
  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }
  
  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      if (widget.productDetails['product_id'] != null) {
        print('正在獲取產品詳情，產品ID: ${widget.productDetails['product_id']}');
        
        // 直接使用 widget.productDetails 中的數據，不再發送 API 請求
        setState(() {
          _isLoading = false;
          _productData = widget.productDetails;
          _initializePrice();
        });
        
        // 如果需要更詳細的產品信息，可以發送 API 請求
        try {
          final response = await _apiService.getProductDetails(widget.productDetails['product_id'].toString());
          print('獲取產品詳情響應: $response');
          
          if (response.containsKey('product') && response['product'] is List && response['product'].isNotEmpty) {
            setState(() {
              _productData = response['product'][0];
              _initializePrice();
              
              // 初始化選項
              _initializeOptions();
            });
          }
        } catch (e) {
          print('獲取詳細產品信息失敗，使用基本信息: ${e.toString()}');
          // 如果 API 請求失敗，我們仍然使用 widget.productDetails 中的基本數據
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '產品ID不存在';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取產品詳情失敗: ${e.toString()}';
      });
    }
  }
  
  // 初始化基本價格
  void _initializePrice() {
    if (_productData['price'] != null) {
      // 移除貨幣符號和空格，轉換為數字
      String priceStr = _productData['price'].toString().replaceAll(RegExp(r'[^\d.]'), '');
      try {
        _basePrice = double.parse(priceStr);
        _finalPrice = _basePrice;
      } catch (e) {
        print('價格轉換錯誤: $e');
        _basePrice = 0.0;
        _finalPrice = 0.0;
      }
    }
  }
  
  // 初始化選項
  void _initializeOptions() {
    if (_productData.containsKey('options') && 
        _productData['options'] is List && 
        _productData['options'].isNotEmpty) {
      
      // 遍歷所有選項類型
      for (var option in _productData['options']) {
        if (option['product_option_value'] is List && 
            option['product_option_value'].isNotEmpty) {
          
          // 為每個選項類型選擇第一個值
          _selectedOptions[option['name']] = option['product_option_value'][0]['product_option_value_id'];
        }
      }
      
      // 計算初始價格
      _calculateFinalPrice();
    }
  }
  
  // 計算最終價格，考慮所有選中的選項
  void _calculateFinalPrice() {
    // 重置為基本價格
    _finalPrice = _basePrice;
    
    if (_productData.containsKey('options') && 
        _productData['options'] is List) {
      
      // 遍歷所有選項類型
      for (var option in _productData['options']) {
        if (option['product_option_value'] is List) {
          // 查找當前選中的選項值
          for (var value in option['product_option_value']) {
            if (_selectedOptions[option['name']] == value['product_option_value_id']) {
              // 應用價格調整
              _applyPriceAdjustment(value);
              break;
            }
          }
        }
      }
    }
    
    // 確保價格不為負數
    if (_finalPrice < 0) {
      _finalPrice = 0;
    }
  }
  
  // 應用價格調整
  void _applyPriceAdjustment(Map<String, dynamic> optionValue) {
    if (optionValue.containsKey('price') && optionValue.containsKey('price_prefix')) {
      String priceStr = optionValue['price'].toString().replaceAll(RegExp(r'[^\d.]'), '');
      double optionPrice = 0.0;
      
      try {
        optionPrice = double.parse(priceStr);
      } catch (e) {
        print('選項價格轉換錯誤: $e');
        return;
      }
      
      String prefix = optionValue['price_prefix'];
      
      switch (prefix) {
        case '+':
          _finalPrice += optionPrice;
          break;
        case '-':
          _finalPrice -= optionPrice;
          break;
        case '=':
          _finalPrice = optionPrice;
          break;
      }
    }
  }
  
  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }
  
  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }
  
  void _addToCart() {
    // 這裡可以實現添加到購物車的邏輯
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已將 ${_productData['name']} 加入購物車'),
        action: SnackBarAction(
          label: '查看購物車',
          onPressed: () {
            Navigator.of(context).pushNamed('/cart');
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 根據 quantity 判斷產品是否缺貨
    bool isOutOfStock = _productData.containsKey('quantity') && 
                        (_productData['quantity'] == null || 
                         int.tryParse(_productData['quantity'].toString()) == 0 ||
                         int.tryParse(_productData['quantity'].toString()) == null);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('產品明細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已加入收藏')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能待實現')),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchProductDetails,
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
          : _productData.isEmpty
            ? const Center(child: Text('沒有找到產品詳情'))
            : Column(
                children: [
                  // 主要內容區域（可滾動）
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 產品圖片
                          if (_productData['thumb'] != null)
                            Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.white,
                              child: Image.network(
                                _productData['thumb'].startsWith('http') 
                                    ? _productData['thumb'] 
                                    : 'https://ismartdemo.com.tw/image/${_productData['thumb']}',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          
                          // 產品信息
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 產品標題和價格區域
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _productData['name'] ?? '未知產品',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // 價格顯示
                                    Row(
                                      children: [
                                        Text(
                                          '價格: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(_finalPrice * _quantity),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // 庫存狀態 - 根據 quantity 調整顏色和顯示
                                Container(
                                  margin: const EdgeInsets.only(top: 8.0),
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red.shade50 
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                      color: isOutOfStock
                                          ? Colors.red.shade100 
                                          : Colors.green.shade100
                                    ),
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? '缺貨中'
                                        : '有現貨',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isOutOfStock
                                          ? Colors.red.shade700 
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // 產品選項
                                if (_productData.containsKey('options') && 
                                    _productData['options'] is List && 
                                    _productData['options'].isNotEmpty)
                                  ..._buildProductOptions(),
                                
                                const SizedBox(height: 24),
                                
                                // 數量選擇 - 缺貨時隱藏
                                if (!isOutOfStock)
                                  Row(
                                    children: [
                                      const Text(
                                        '數量',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            // 減號按鈕
                                            InkWell(
                                              onTap: _decreaseQuantity,
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.remove, size: 20),
                                              ),
                                            ),
                                            // 數量顯示
                                            Container(
                                              width: 60,
                                              height: 40,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(color: Colors.grey.shade300),
                                                  right: BorderSide(color: Colors.grey.shade300),
                                                ),
                                              ),
                                              child: Text(
                                                '$_quantity',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ),
                                            // 加號按鈕
                                            InkWell(
                                              onTap: _increaseQuantity,
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.add, size: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                const SizedBox(height: 24),
                                
                                // 描述標題
                                const Text(
                                  '描述',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // 產品描述 - 使用 description_json
                                if (_productData.containsKey('description_json') && 
                                    _productData['description_json'] is List)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _buildDescriptionFromJson(),
                                  )
                                // 如果沒有 description_json，則使用 description
                                else if (_productData['description'] != null)
                                  Html(
                                    data: _productData['description'],
                                    style: {
                                      "body": Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                      ),
                                      "p": Style(
                                        margin: Margins(bottom: Margin(8)),
                                      ),
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 底部固定的購買區域
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 加入購物車按鈕
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isOutOfStock
                                ? null
                                : () {
                                    // 加入購物車邏輯
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('已加入購物車'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOutOfStock ? Colors.grey : Colors.white,
                              foregroundColor: isOutOfStock ? Colors.white : Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isOutOfStock ? Colors.grey : Colors.black, width: 1),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              isOutOfStock ? '產品已售完' : '加入購物車',
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
                ],
              ),
    );
  }
  
  List<Widget> _buildProductOptions() {
    List<Widget> optionWidgets = [];
    
    for (var option in _productData['options']) {
      // 獲取選項名稱
      String optionName = option['name'];
      
      optionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$optionName:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (option['type'] == 'radio')
              // 根據選項類型使用不同的顯示方式
              optionName.toLowerCase().contains('color') || optionName.toLowerCase().contains('顏色')
                ? _buildColorOptions(option)
                : _buildSizeOptions(option),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
    
    return optionWidgets;
  }
  
  // 構建顏色選項
  Widget _buildColorOptions(Map<String, dynamic> option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顏色選項
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (option['product_option_value'] as List).map<Widget>((value) {
            // 構建選項顯示文本，包含價格信息
            String optionText = value['name'];
            if (value.containsKey('price') && value['price'] != '0') {
              String pricePrefix = value['price_prefix'] ?? '+';
              optionText += ' (${pricePrefix}${_formatOptionPrice(value['price'])})';
            }
            
            return ChoiceChip(
              label: Text(optionText),
              selected: _selectedOptions[option['name']] == value['product_option_value_id'],
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    _selectedOptions[option['name']] = value['product_option_value_id'];
                    _calculateFinalPrice();
                  });
                }
              },
            );
          }).toList(),
        ),
        
        // 顯示選中的顏色名稱和價格
        if (_selectedOptions.containsKey(option['name']))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Builder(
              builder: (context) {
                // 查找選中的選項
                var selectedValue = (option['product_option_value'] as List).firstWhere(
                  (value) => value['product_option_value_id'] == _selectedOptions[option['name']],
                  orElse: () => {},
                );
                
                if (selectedValue != null) {
                  String colorName = selectedValue['name'];
                  String priceInfo = '';
                  if (selectedValue.containsKey('price') && selectedValue['price'] != '0') {
                    String pricePrefix = selectedValue['price_prefix'] ?? '+';
                    priceInfo = ' (${pricePrefix}${_formatOptionPrice(selectedValue['price'])})';
                  }
                  
                  return Text(
                    '已選: $colorName$priceInfo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }
  
  // 構建尺寸選項
  Widget _buildSizeOptions(Map<String, dynamic> option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 尺寸選項
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (option['product_option_value'] as List).map<Widget>((value) {
            // 構建選項顯示文本，包含價格信息
            String optionText = value['name'];
            if (value.containsKey('price') && value['price'] != '0') {
              String pricePrefix = value['price_prefix'] ?? '+';
              optionText += ' (${pricePrefix}${_formatOptionPrice(value['price'])})';
            }
            
            return ChoiceChip(
              label: Text(optionText),
              selected: _selectedOptions[option['name']] == value['product_option_value_id'],
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    _selectedOptions[option['name']] = value['product_option_value_id'];
                    _calculateFinalPrice();
                  });
                }
              },
            );
          }).toList(),
        ),
        
        // 顯示選中的尺寸和價格
        if (_selectedOptions.containsKey(option['name']))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Builder(
              builder: (context) {
                // 查找選中的選項
                var selectedValue = (option['product_option_value'] as List).firstWhere(
                  (value) => value['product_option_value_id'] == _selectedOptions[option['name']],
                  orElse: () => {},
                );
                
                if (selectedValue != null) {
                  String sizeName = selectedValue['name'];
                  String priceInfo = '';
                  if (selectedValue.containsKey('price') && selectedValue['price'] != '0') {
                    String pricePrefix = selectedValue['price_prefix'] ?? '+';
                    priceInfo = ' (${pricePrefix}${_formatOptionPrice(selectedValue['price'])})';
                  }
                  
                  return Text(
                    '已選: $sizeName$priceInfo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }
  
  // 根據顏色名稱獲取對應的顏色
  Color _getColorFromName(String colorName) {
    colorName = colorName.toLowerCase();
    
    if (colorName.contains('黑') || colorName.contains('black')) {
      return Colors.black;
    } else if (colorName.contains('白') || colorName.contains('white')) {
      return Colors.white;
    } else if (colorName.contains('紅') || colorName.contains('red')) {
      return Colors.red;
    } else if (colorName.contains('藍') || colorName.contains('blue')) {
      return Colors.blue;
    } else if (colorName.contains('綠') || colorName.contains('green')) {
      return Colors.green;
    } else if (colorName.contains('黃') || colorName.contains('yellow')) {
      return Colors.yellow;
    } else if (colorName.contains('粉') || colorName.contains('pink')) {
      return Colors.pink;
    } else if (colorName.contains('紫') || colorName.contains('purple')) {
      return Colors.purple;
    } else if (colorName.contains('橙') || colorName.contains('orange')) {
      return Colors.orange;
    } else if (colorName.contains('灰') || colorName.contains('grey') || colorName.contains('gray')) {
      return Colors.grey;
    } else if (colorName.contains('棕') || colorName.contains('brown')) {
      return Colors.brown;
    } else {
      return Colors.grey.shade300; // 默認顏色
    }
  }
  
  List<Widget> _buildDescriptionFromJson() {
    List<Widget> descriptionWidgets = [];
    
    // 檢查是否有產品屬性信息（類別、運費、單位等）
    bool hasProductAttributes = false;
    List<Widget> attributeWidgets = [];
    
    // 先遍歷一次找出產品屬性信息
    for (var item in _productData['description_json']) {
      if (item['type'] == 'p' && 
          item['content'] != null && 
          item['content'].toString().isNotEmpty) {
        String content = item['content'].toString();
        if (content.contains('類別：') || 
            content.contains('運費：') || 
            content.contains('單位：')) {
          hasProductAttributes = true;
          attributeWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
      }
    }
    
    // 如果有產品屬性信息，先添加這些信息
    if (hasProductAttributes) {
      descriptionWidgets.addAll(attributeWidgets);
      // 添加一個分隔線
      descriptionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
      );
    }
    
    // 再次遍歷，添加其他描述內容
    for (var item in _productData['description_json']) {
      if (item['type'] == 'p') {
        String content = item['content']?.toString() ?? '';
        // 跳過已經添加過的產品屬性信息
        if (content.contains('類別：') || 
            content.contains('運費：') || 
            content.contains('單位：')) {
          continue;
        }
        
        // 處理段落，包括空行
        if (content.isEmpty) {
          // 如果內容為空，添加一個空行
          descriptionWidgets.add(
            const SizedBox(height: 16), // 空行的高度
          );
        } else {
          // 如果有內容，顯示文本
          descriptionWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
      } else if (item['type'] == 'img' && item['content'] != null) {
        // 處理圖片
        descriptionWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.network(
              item['content'],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
        );
      }
    }
    
    return descriptionWidgets;
  }
  
  // 格式化價格顯示
  String _formatPrice(double price) {
    // 四捨五入到小數點後兩位
    double roundedPrice = (price * 100).round() / 100;
    // 如果是整數，不顯示小數部分
    if (roundedPrice == roundedPrice.toInt()) {
      return 'NT\$${roundedPrice.toInt()}';
    }
    return 'NT\$${roundedPrice.toStringAsFixed(2)}';
  }
  
  // 格式化選項價格
  String _formatOptionPrice(String priceStr) {
    // 移除貨幣符號和空格，轉換為數字
    priceStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    try {
      double price = double.parse(priceStr);
      // 如果是整數，不顯示小數部分
      if (price == price.toInt()) {
        return 'NT\$${price.toInt()}';
      }
      return 'NT\$${price.toStringAsFixed(2)}';
    } catch (e) {
      print('選項價格轉換錯誤: $e');
      return priceStr;
    }
  }
} 