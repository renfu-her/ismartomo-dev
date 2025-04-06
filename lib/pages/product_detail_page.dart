import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productDetails;

  const ProductDetailPage({super.key, required this.productDetails});

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
  final Map<String, String> _selectedOptions = {};
  double _basePrice = 0.0; // 基本價格
  double _finalPrice = 0.0; // 最終價格（含選項）
  bool _isPriceZero = false; // 標記價格是否為零
  bool _isFavorite = false; // 標記是否為收藏

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
          final response = await _apiService.getProductDetails(
            widget.productDetails['product_id'].toString(),
          );
          print('獲取產品詳情響應: $response');

          if (response.containsKey('product') &&
              response['product'] is List &&
              response['product'].isNotEmpty) {
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
      String priceStr = _productData['price'].toString().replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
      try {
        _basePrice = double.parse(priceStr);
        _finalPrice = _basePrice;
        _isPriceZero = _basePrice == 0;
      } catch (e) {
        print('價格轉換錯誤: $e');
        _basePrice = 0.0;
        _finalPrice = 0.0;
        _isPriceZero = true;
      }
    } else {
      _basePrice = 0.0;
      _finalPrice = 0.0;
      _isPriceZero = true;
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
          _selectedOptions[option['name']] =
              option['product_option_value'][0]['product_option_value_id'];
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
            if (_selectedOptions[option['name']] ==
                value['product_option_value_id']) {
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
    if (optionValue.containsKey('price') &&
        optionValue.containsKey('price_prefix')) {
      String priceStr = optionValue['price'].toString().replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
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

  void _addToCart() async {
    try {
      // 檢查登入狀態
      final userService = Provider.of<UserService>(context, listen: false);
      if (!userService.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('請先登入以使用購物車功能'),
            action: SnackBarAction(
              label: '登入',
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
            ),
          ),
        );
        return;
      }

      // 檢查是否有必選選項未選擇
      bool hasRequiredOptions = false;
      bool allRequiredOptionsSelected = true;
      List<String> missingOptions = [];

      if (_productData.containsKey('options') &&
          _productData['options'] is List) {
        for (var option in _productData['options']) {
          // 檢查是否為必填選項類型
          if (option['type'] == 'select' || 
              option['type'] == 'radio' || 
              option['type'] == 'datetime') {
            hasRequiredOptions = true;
            
            // 檢查選項是否已選擇
            if (!_selectedOptions.containsKey(option['product_option_id']) ||
                _selectedOptions[option['product_option_id']] == null ||
                _selectedOptions[option['product_option_id']]!.isEmpty) {
              allRequiredOptionsSelected = false;
              // 獲取選項名稱
              String optionName = option['name']?.toString().trim().isNotEmpty == true
                  ? option['name']
                  : option['disname'] ?? '';
              missingOptions.add(optionName);
            }
          }
        }
      }

      if (hasRequiredOptions && !allRequiredOptionsSelected) {
        // 顯示缺少的選項
        String missingOptionsText = missingOptions.join('、');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('請選擇以下必填選項：$missingOptionsText'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // 準備選項數據
      Map<String, String> options = {};
      if (_productData.containsKey('options') &&
          _productData['options'] is List) {
        for (var option in _productData['options']) {
          if (_selectedOptions.containsKey(option['product_option_id'])) {
            options[option['product_option_id']] =
                _selectedOptions[option['product_option_id']]!;
          }
        }
      }

      // 顯示加載指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // 調用 API 加入購物車
      final response = await _apiService.addToCart(
        productId: _productData['product_id'].toString(),
        quantity: _quantity,
        options: options.isNotEmpty ? options : null,
      );

      // 關閉加載指示器
      Navigator.of(context).pop();

      // 顯示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已將 ${_formatSpecialCharacters(_productData['name'] ?? '')} 加入購物車',
          ),
          action: SnackBarAction(
            label: '查看購物車',
            onPressed: () {
              Navigator.of(context).pushNamed('/cart');
            },
          ),
        ),
      );
    } catch (e) {
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();

      // 顯示錯誤消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加入購物車失敗: ${e.toString()}')));
    }
  }

  // 分享產品資訊
  void _shareProduct() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '分享到',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 系統分享
                    _buildShareButton(
                      icon: Icons.share,
                      label: '分享',
                      color: Colors.blue,
                      onTap: () async {
                        final String productName = _productData['name'] ?? '';
                        final String productPrice = _productData['price'] ?? '';
                        final String shareUrl = _productData['shref'] ?? '';

                        // 構建分享文本
                        final String shareText = '''
$productName
價格: $productPrice

立即購買: $shareUrl
''';

                        await Share.share(shareText);
                        Navigator.pop(context);
                      },
                    ),
                    // 複製連結
                    _buildShareButton(
                      icon: Icons.link,
                      label: '複製連結',
                      color: Colors.grey,
                      onTap: () async {
                        final String shareUrl = _productData['shref'] ?? '';
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('已複製分享連結')));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 添加分享按鈕小工具
  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根據 quantity 判斷產品是否缺貨
    bool isOutOfStock =
        _productData.containsKey('quantity') &&
        (_productData['quantity'] == null ||
            int.tryParse(_productData['quantity'].toString()) == 0 ||
            int.tryParse(_productData['quantity'].toString()) == null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('產品明細'),
        actions: [
          // 只有當價格不為零時才顯示愛心按鈕
          if (!_isPriceZero)
            Consumer<UserService>(
              builder: (context, userService, child) {
                _isFavorite = userService.isLoggedIn && userService.isFavorite(
                  _productData['product_id'],
                );
                return IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    if (!userService.isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('請先登入以使用收藏功能'),
                          action: SnackBarAction(
                            label: '登入',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/login');
                            },
                          ),
                        ),
                      );
                      return;
                    }
                    if (_isFavorite) {
                      userService.removeFavorite(_productData['product_id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已從收藏中移除')),
                      );
                    } else {
                      userService.addFavorite(_productData['product_id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已加入收藏')),
                      );
                    }
                  },
                );
              },
            ),
          // 分享按鈕
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProduct),
        ],
      ),
      body:
          _isLoading
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
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
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
                                      _formatSpecialCharacters(
                                        _productData['name'] ?? '未知產品',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 價格顯示 - 只有當價格不為零時才顯示
                                    if (!_isPriceZero)
                                      Row(
                                        children: [
                                          Text(
                                            '價格: ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // 如果有特價，顯示原價（加上橫線）和特價
                                          if (_productData.containsKey(
                                                'special',
                                              ) &&
                                              _productData['special'] != null &&
                                              _productData['special'] != false)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 原價（加上橫線）
                                                Text(
                                                  '${_productData['price']}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                    decoration:
                                                        TextDecoration
                                                            .lineThrough,
                                                  ),
                                                ),
                                                // 特價
                                                Text(
                                                  '${_productData['special']}',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              _formatPrice(
                                                _finalPrice * _quantity,
                                              ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isOutOfStock
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                      color:
                                          isOutOfStock
                                              ? Colors.red.shade100
                                              : Colors.green.shade100,
                                    ),
                                  ),
                                  child: Text(
                                    isOutOfStock ? '缺貨中' : '有現貨',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isOutOfStock
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

                                // 數量選擇 - 缺貨時或價格為零時隱藏
                                if (!isOutOfStock && !_isPriceZero)
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
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                                child: const Icon(
                                                  Icons.remove,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            // 數量顯示
                                            Container(
                                              width: 60,
                                              height: 40,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  right: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                '$_quantity',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            // 加號按鈕
                                            InkWell(
                                              onTap: _increaseQuantity,
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 20,
                                                ),
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
                                if (_productData.containsKey(
                                      'description_json',
                                    ) &&
                                    _productData['description_json'] is List)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                  // 底部固定的購買區域 - 價格為零時隱藏
                  if (!_isPriceZero)
                    Container(
                      color: Colors.white,
                      child: SafeArea(
                        bottom: true,
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: 12.0,
                            bottom: 12.0,
                          ),
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
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isOutOfStock ? null : _addToCart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(color: Colors.black),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: Text(
                                    isOutOfStock ? '產品已售完' : '加入購物車',
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
              ),
    );
  }

  List<Widget> _buildProductOptions() {
    List<Widget> optionWidgets = [];

    for (var option in _productData['options']) {
      // 獲取選項名稱，優先使用 name，為空時使用 disname
      String optionName = option['name']?.toString().trim().isNotEmpty == true
          ? option['name']
          : option['disname'] ?? '';

      optionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              optionName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 使用正確的條件渲染方式
            if (option['type'] == 'radio')
              optionName.toLowerCase().contains('color') ||
                      optionName.toLowerCase().contains('顏色')
                  ? _buildColorOptions(option)
                  : _buildSizeOptions(option)
            else if (option['type'] == 'select')
              _buildSelectOptions(option)
            else if (option['type'] == 'datetime')
              _buildDateTimeOptions(option),
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
          children:
              (option['product_option_value'] as List).map<Widget>((value) {
                // 構建選項顯示文本，優先使用 name
                String optionText = value['name']?.toString().trim().isNotEmpty == true
                    ? value['name']
                    : value['disname'] ?? '';
                String imageUrl = value['image'] ?? '';
                // 處理圖片路徑
                if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                  imageUrl = 'https://ismartdemo.com.tw/image/$imageUrl';
                }

                return ChoiceChip(
                  avatar: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey,
                            );
                          },
                        )
                      : null,
                  label: Text(optionText),
                  selected:
                      _selectedOptions[option['product_option_id']] ==
                      value['product_option_value_id'],
                  onSelected: (isSelected) {
                    if (isSelected) {
                      setState(() {
                        _selectedOptions[option['product_option_id']] =
                            value['product_option_value_id'];
                        _calculateFinalPrice();
                      });
                    }
                  },
                );
              }).toList(),
        ),

        // 顯示選中的顏色名稱和圖片
        if (_selectedOptions.containsKey(option['product_option_id']))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Builder(
              builder: (context) {
                // 查找選中的選項
                var selectedValue = (option['product_option_value'] as List)
                    .firstWhere(
                      (value) =>
                          value['product_option_value_id'] ==
                          _selectedOptions[option['product_option_id']],
                      orElse: () => {},
                    );

                if (selectedValue.isNotEmpty) {
                  String colorName = selectedValue['name']?.toString().trim().isNotEmpty == true
                      ? selectedValue['name']
                      : selectedValue['disname'] ?? '';
                  String imageUrl = selectedValue['image'] ?? '';
                  // 處理圖片路徑
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = 'https://ismartdemo.com.tw/image/$imageUrl';
                  }

                  return Row(
                    children: [
                      if (imageUrl.isNotEmpty)
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                size: 24,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      Text(
                        '已選: $colorName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
          children:
              (option['product_option_value'] as List).map<Widget>((value) {
                // 構建選項顯示文本，優先使用 name
                String optionText = value['name']?.toString().trim().isNotEmpty == true
                    ? value['name']
                    : value['disname'] ?? '';
                String imageUrl = value['image'] ?? '';
                // 處理圖片路徑
                if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                  imageUrl = 'https://ismartdemo.com.tw/image/$imageUrl';
                }

                return ChoiceChip(
                  avatar: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey,
                            );
                          },
                        )
                      : null,
                  label: Text(optionText),
                  selected:
                      _selectedOptions[option['product_option_id']] ==
                      value['product_option_value_id'],
                  onSelected: (isSelected) {
                    if (isSelected) {
                      setState(() {
                        _selectedOptions[option['product_option_id']] =
                            value['product_option_value_id'];
                        _calculateFinalPrice();
                      });
                    }
                  },
                );
              }).toList(),
        ),

        // 顯示選中的尺寸和圖片
        if (_selectedOptions.containsKey(option['product_option_id']))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Builder(
              builder: (context) {
                // 查找選中的選項
                var selectedValue = (option['product_option_value'] as List)
                    .firstWhere(
                      (value) =>
                          value['product_option_value_id'] ==
                          _selectedOptions[option['product_option_id']],
                      orElse: () => {},
                    );

                if (selectedValue.isNotEmpty) {
                  String sizeName = selectedValue['name']?.toString().trim().isNotEmpty == true
                      ? selectedValue['name']
                      : selectedValue['disname'] ?? '';
                  String imageUrl = selectedValue['image'] ?? '';
                  // 處理圖片路徑
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = 'https://ismartdemo.com.tw/image/$imageUrl';
                  }

                  return Row(
                    children: [
                      if (imageUrl.isNotEmpty)
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                size: 24,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      Text(
                        '已選: $sizeName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
    } else if (colorName.contains('灰') ||
        colorName.contains('grey') ||
        colorName.contains('gray')) {
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
              child: Text(content, style: const TextStyle(fontSize: 16)),
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
              child: Text(content, style: const TextStyle(fontSize: 16)),
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
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
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

  // 處理特殊字符轉換
  String _formatSpecialCharacters(String text) {
    if (text.isEmpty) {
      return '';
    }

    // 創建一個映射表，將HTML實體轉換為對應的特殊字符
    final Map<String, String> htmlEntities = {
      '&quot;': '"',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&apos;': "'",
      '&#39;': "'",
      '&lsquo;': "'",
      '&rsquo;': "'",
      '&ldquo;': '"',
      '&rdquo;': '"',
      '&ndash;': '–',
      '&mdash;': '—',
      '&nbsp;': ' ',
      '&iexcl;': '¡',
      '&cent;': '¢',
      '&pound;': '£',
      '&curren;': '¤',
      '&yen;': '¥',
      '&brvbar;': '¦',
      '&sect;': '§',
      '&uml;': '¨',
      '&copy;': '©',
      '&ordf;': 'ª',
      '&laquo;': '«',
      '&not;': '¬',
      '&reg;': '®',
      '&macr;': '¯',
      '&deg;': '°',
      '&plusmn;': '±',
      '&sup2;': '²',
      '&sup3;': '³',
      '&acute;': '´',
      '&micro;': 'µ',
      '&para;': '¶',
      '&middot;': '·',
      '&cedil;': '¸',
      '&sup1;': '¹',
      '&ordm;': 'º',
      '&raquo;': '»',
      '&frac14;': '¼',
      '&frac12;': '½',
      '&frac34;': '¾',
      '&iquest;': '¿',
    };

    // 替換所有HTML實體
    String result = text;
    htmlEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });

    return result;
  }

  // 構建下拉選單選項
  Widget _buildSelectOptions(Map<String, dynamic> option) {
    // 獲取選項列表
    List<dynamic> optionValues = option['product_option_value'] as List;

    // 確保有選中的選項
    if (!_selectedOptions.containsKey(option['product_option_id']) &&
        optionValues.isNotEmpty) {
      _selectedOptions[option['product_option_id']] =
          optionValues[0]['product_option_value_id'];
    }

    // 獲取當前選中的選項名稱和圖片
    String selectedName = '';
    String selectedImage = '';
    for (var value in optionValues) {
      if (value['product_option_value_id'] ==
          _selectedOptions[option['product_option_id']]) {
        selectedName = value['name']?.toString().trim().isNotEmpty == true
            ? value['name']
            : value['disname'] ?? '';
        selectedImage = value['image'] ?? '';
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 下拉選單
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedOptions[option['product_option_id']],
            isExpanded: true,
            underline: Container(), // 移除下劃線
            icon: const Icon(Icons.arrow_drop_down),
            hint: const Text('請選擇'),
            items: optionValues.map<DropdownMenuItem<String>>((value) {
              // 構建選項顯示文本，優先使用 name
              String optionText = value['name']?.toString().trim().isNotEmpty == true
                  ? value['name']
                  : value['disname'] ?? '';
              String imageUrl = value['image'] ?? '';
              // 處理圖片路徑
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl = 'https://ismartdemo.com.tw/image/$imageUrl';
              }

              return DropdownMenuItem<String>(
                value: value['product_option_value_id'],
                child: Row(
                  children: [
                    // 如果有圖片，顯示圖片
                    if (imageUrl.isNotEmpty)
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                    // 選項文字
                    Expanded(
                      child: Text(optionText),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedOptions[option['product_option_id']] = newValue;
                  _calculateFinalPrice();
                });
              }
            },
          ),
        ),

        // 顯示選中的選項名稱和圖片
        if (selectedName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                // 如果有圖片，顯示圖片
                if (selectedImage.isNotEmpty)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      selectedImage.startsWith('http')
                          ? selectedImage
                          : 'https://ismartdemo.com.tw/image/$selectedImage',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                Text(
                  '已選: $selectedName',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 構建日期時間選項
  Widget _buildDateTimeOptions(Map<String, dynamic> option) {
    // 獲取當前選中的日期時間值
    String currentValue = _selectedOptions[option['product_option_id']] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期時間選擇按鈕
        InkWell(
          onTap: () async {
            // 選擇日期
            final DateTime? date = await showDatePicker(
              context: context,
              initialDate: currentValue.isNotEmpty 
                  ? DateTime.parse(currentValue.split(' ')[0])
                  : DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('zh', 'TW'), // 設置為繁體中文
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    dialogTheme: DialogTheme(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (date != null) {
              // 選擇時間
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: currentValue.isNotEmpty
                    ? TimeOfDay.fromDateTime(DateTime.parse(currentValue))
                    : TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: TimePickerThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: Localizations.override(
                      context: context,
                      locale: const Locale('zh', 'TW'),
                      child: child!,
                    ),
                  );
                },
              );

              if (time != null) {
                // 組合日期和時間
                final DateTime selectedDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                setState(() {
                  _selectedOptions[option['product_option_id']] = 
                      selectedDateTime.toString().substring(0, 16);
                  _calculateFinalPrice();
                });
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentValue.isNotEmpty 
                        ? currentValue 
                        : '請選擇日期和時間',
                    style: TextStyle(
                      color: currentValue.isNotEmpty 
                          ? Colors.black 
                          : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
        // 顯示已選擇的日期時間
        if (currentValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '已選: $currentValue',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
