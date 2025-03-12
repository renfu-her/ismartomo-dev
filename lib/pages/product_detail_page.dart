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
  String? _selectedOptionValue;
  
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
        });
        
        // 如果需要更詳細的產品信息，可以發送 API 請求
        try {
          final response = await _apiService.getProductDetails(widget.productDetails['product_id'].toString());
          print('獲取產品詳情響應: $response');
          
          if (response.containsKey('product') && response['product'] is List && response['product'].isNotEmpty) {
            setState(() {
              _productData = response['product'][0];
              
              // 如果有選項，預設選擇第一個
              if (_productData.containsKey('options') && 
                  _productData['options'] is List && 
                  _productData['options'].isNotEmpty &&
                  _productData['options'][0]['product_option_value'] is List &&
                  _productData['options'][0]['product_option_value'].isNotEmpty) {
                _selectedOptionValue = _productData['options'][0]['product_option_value'][0]['product_option_value_id'];
              }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('產品明細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
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
                                    
                                    // 價格顯示 - 改為紅色
                                    if (_productData['price'] != null)
                                      Text(
                                        '${_productData['price']}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    
                                    // 移除型號和庫存顯示
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // 庫存狀態 - 根據狀態調整顏色
                                if (_productData['stock_status'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: _productData['stock_status'] == '缺貨中-待補貨' 
                                          ? Colors.red.shade50 
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4.0),
                                      border: Border.all(
                                        color: _productData['stock_status'] == '缺貨中-待補貨' 
                                            ? Colors.red.shade100 
                                            : Colors.green.shade100
                                      ),
                                    ),
                                    child: Text(
                                      _productData['stock_status'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _productData['stock_status'] == '缺貨中-待補貨' 
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
                                if (_productData['stock_status'] != '缺貨中-待補貨')
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
                          flex: 3,
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: _productData['stock_status'] == '缺貨中-待補貨' ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('此商品已售完，暫時無法購買')),
                                );
                              } : _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _productData['stock_status'] == '缺貨中-待補貨' 
                                    ? Colors.red.shade400  // 缺貨時使用紅色背景
                                    : const Color(0xFF6A3DE8), // 有庫存時使用紫色背景
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30), // 圓角
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_productData['stock_status'] == '缺貨中-待補貨' 
                                      ? Icons.info_outline  // 缺貨時使用提示圖標
                                      : Icons.shopping_cart, // 有庫存時使用購物車圖標
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _productData['stock_status'] == '缺貨中-待補貨' 
                                        ? '產品已售完'  // 缺貨時顯示"產品已售完"
                                        : '加入購物車', // 有庫存時顯示"加入購物車"
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 收藏按鈕
                        IconButton(
                          icon: const Icon(Icons.favorite_border, color: Colors.pink),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已加入收藏')),
                            );
                          },
                        ),
                        // 分享按鈕
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
                  ),
                ],
              ),
    );
  }
  
  List<Widget> _buildProductOptions() {
    List<Widget> optionWidgets = [];
    
    for (var option in _productData['options']) {
      optionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${option['name']}:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (option['type'] == 'radio')
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (option['product_option_value'] as List).map<Widget>((value) {
                  return ChoiceChip(
                    label: Text(value['name']),
                    selected: _selectedOptionValue == value['product_option_value_id'],
                    onSelected: (isSelected) {
                      if (isSelected) {
                        setState(() {
                          _selectedOptionValue = value['product_option_value_id'];
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }
    
    return optionWidgets;
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
} 