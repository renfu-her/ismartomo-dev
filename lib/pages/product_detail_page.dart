import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
  final Map<String, String> _selectedOptions = {};
  double _basePrice = 0.0;
  double _finalPrice = 0.0;
  bool _isPriceZero = false;
  bool _isFavorite = false;
  String _currentImage = '';
  int _currentImageIndex = 0;
  List<String> _carouselImages = [];

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

        setState(() {
          _isLoading = false;
          _productData = widget.productDetails;
          _initializePrice();
          _carouselImages = _getAllProductImages();
          if (_carouselImages.isNotEmpty) {
            _currentImage = _carouselImages[0].startsWith('http')
                ? _carouselImages[0]
                : 'https://ismartomo.com.tw/image/${_carouselImages[0]}';
          }
        });

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
              _carouselImages = _getAllProductImages();
              if (_carouselImages.isNotEmpty) {
                _currentImage = _carouselImages[0].startsWith('http')
                    ? _carouselImages[0]
                    : 'https://ismartomo.com.tw/image/${_carouselImages[0]}';
              }
              _initializeOptions();
            });
          }
        } catch (e) {
          print('獲取詳細產品信息失敗，使用基本信息: ${e.toString()}');
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

  void _initializePrice() {
    if (_productData['price'] != null) {
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

  void _initializeOptions() {
    if (_productData.containsKey('options') &&
        _productData['options'] is List &&
        _productData['options'].isNotEmpty) {
      for (var option in _productData['options']) {
        if (option['product_option_value'] is List &&
            option['product_option_value'].isNotEmpty) {
          // 不設置預設值，讓用戶自己選擇
          // _selectedOptions[option['product_option_id']] =
          //     option['product_option_value'][0]['product_option_value_id'];
        }
      }

      // 初始價格為基礎價格，不包含選項調整
      _finalPrice = _basePrice;
    }
  }

  void _calculateFinalPrice() {
    _finalPrice = _basePrice;

    if (_productData.containsKey('options') &&
        _productData['options'] is List) {
      for (var option in _productData['options']) {
        if (option['product_option_value'] is List) {
          for (var value in option['product_option_value']) {
            if (_selectedOptions[option['product_option_id']] ==
                value['product_option_value_id']) {
              _applyPriceAdjustment(value);
              break;
            }
          }
        }
      }
    }

    if (_finalPrice < 0) {
      _finalPrice = 0;
    }
  }

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

      bool hasRequiredOptions = false;
      bool allRequiredOptionsSelected = true;
      List<String> missingOptions = [];

      if (_productData.containsKey('options') &&
          _productData['options'] is List) {
        for (var option in _productData['options']) {
          if (option['type'] == 'select' || 
              option['type'] == 'radio' || 
              option['type'] == 'datetime') {
            hasRequiredOptions = true;
            
            if (!_selectedOptions.containsKey(option['product_option_id']) ||
                _selectedOptions[option['product_option_id']] == null ||
                _selectedOptions[option['product_option_id']]!.isEmpty) {
              allRequiredOptionsSelected = false;
              String optionName = option['name']?.toString().trim().isNotEmpty == true
                  ? option['name']
                  : option['disname'] ?? '';
              missingOptions.add(optionName);
            }
          }
        }
      }

      if (hasRequiredOptions && !allRequiredOptionsSelected) {
        String missingOptionsText = missingOptions.join('、');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('請選擇以下必填選項：$missingOptionsText'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final response = await _apiService.addToCart(
        productId: _productData['product_id'].toString(),
        quantity: _quantity,
        options: options.isNotEmpty ? options : null,
      );

      Navigator.of(context).pop();

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
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加入購物車失敗: ${e.toString()}')));
    }
  }

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
                    _buildShareButton(
                      icon: Icons.share,
                      label: '分享',
                      color: Colors.blue,
                      onTap: () async {
                        final String productName = _productData['name'] ?? '';
                        final String productPrice = _productData['price'] ?? '';
                        final String shareUrl = _productData['shref'] ?? '';

                        final String shareText = '''
$productName
價格: $productPrice

立即購買: $shareUrl
''';

                        await Share.share(shareText);
                        Navigator.pop(context);
                      },
                    ),
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
    bool isOutOfStock =
        _productData.containsKey('quantity') &&
        (_productData['quantity'] == null ||
            int.tryParse(_productData['quantity'].toString()) == 0 ||
            int.tryParse(_productData['quantity'].toString()) == null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('產品明細'),
        actions: [
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_carouselImages.isNotEmpty)
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 250,
                                  color: Colors.white,
                                  child: CarouselSlider(
                                    options: CarouselOptions(
                                      height: 250,
                                      viewportFraction: 1.0,
                                      initialPage: _currentImageIndex,
                                      enableInfiniteScroll: _carouselImages.length > 1,
                                      onPageChanged: (index, reason) {
                                        _updateCurrentImageIndex(index);
                                      },
                                    ),
                                    items: _carouselImages.map((image) {
                                      return Builder(
                                        builder: (BuildContext context) {
                                          return Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                            child: Image.network(
                                              image.startsWith('http')
                                                  ? image
                                                  : 'https://ismartomo.com.tw/image/$image',
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
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if (_carouselImages.length > 1)
                                  Positioned(
                                    bottom: 10,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: _carouselImages.asMap().entries.map((entry) {
                                        return Container(
                                          width: 8.0,
                                          height: 8.0,
                                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).primaryColor.withOpacity(
                                              _currentImageIndex == entry.key ? 0.9 : 0.4,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                          if (_productData.containsKey(
                                                'special',
                                              ) &&
                                              _productData['special'] != null &&
                                              _productData['special'] != false)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _formatPriceString(_productData['price']),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                    decoration:
                                                        TextDecoration
                                                            .lineThrough,
                                                  ),
                                                ),
                                                Text(
                                                  _formatPriceString(_productData['special']),
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

                                if (_productData.containsKey('options') &&
                                    _productData['options'] is List &&
                                    _productData['options'].isNotEmpty)
                                  ..._buildProductOptions(),

                                const SizedBox(height: 24),

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

                                const Text(
                                  '描述',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (_productData.containsKey('description_json') &&
                                    _productData['description_json'] is List &&
                                    _productData['description_json'].isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _buildDescriptionFromJson(),
                                  )
                                else if (_productData['description'] != null &&
                                    _productData['description'].toString().isNotEmpty)
                                  Html(
                                    data: _productData['description'].toString(),
                                    style: {
                                      "body": Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                      ),
                                      "p": Style(
                                        margin: Margins(bottom: Margin(8)),
                                      ),
                                    },
                                  )
                                else
                                  const Text(
                                    '暫無描述',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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

  Widget _buildColorOptions(Map<String, dynamic> option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              (option['product_option_value'] as List).map<Widget>((value) {
            String optionText = value['name']?.toString().trim().isNotEmpty == true
                ? value['name']
                : value['disname'] ?? '';
            String imageUrl = value['image'] ?? '';
            
            return ChoiceChip(
              avatar: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl.startsWith('http')
                          ? imageUrl
                          : 'https://ismartomo.com.tw/image/$imageUrl',
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
              selected: _selectedOptions.containsKey(option['product_option_id']) &&
                  _selectedOptions[option['product_option_id']] ==
                  value['product_option_value_id'],
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    _selectedOptions[option['product_option_id']] =
                        value['product_option_value_id'];
                    _calculateFinalPrice();
                    if (value['image'] != null && value['image'].isNotEmpty) {
                      _updateCurrentImage(value['image']);
                    }
                  });
                }
              },
            );
          }).toList(),
        ),

        if (_selectedOptions.containsKey(option['product_option_id']))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Builder(
              builder: (context) {
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
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = 'https://ismartomo.com.tw/image/$imageUrl';
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

  Widget _buildSizeOptions(Map<String, dynamic> option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              (option['product_option_value'] as List).map<Widget>((value) {
            String optionText = value['name']?.toString().trim().isNotEmpty == true
                ? value['name']
                : value['disname'] ?? '';
            String imageUrl = value['image'] ?? '';
            
            return ChoiceChip(
              avatar: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl.startsWith('http')
                          ? imageUrl
                          : 'https://ismartomo.com.tw/image/$imageUrl',
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
              selected: _selectedOptions.containsKey(option['product_option_id']) &&
                  _selectedOptions[option['product_option_id']] ==
                  value['product_option_value_id'],
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    _selectedOptions[option['product_option_id']] =
                        value['product_option_value_id'];
                    _calculateFinalPrice();
                    _updateCurrentImage(value['image']);
                  });
                }
              },
            );
          }).toList(),
        ),

        if (_selectedOptions.containsKey(option['product_option_id']))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Builder(
              builder: (context) {
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
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = 'https://ismartomo.com.tw/image/$imageUrl';
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
      return Colors.grey.shade300;
    }
  }

  List<Widget> _buildDescriptionFromJson() {
    List<Widget> descriptionWidgets = [];

    bool hasProductAttributes = false;
    List<Widget> attributeWidgets = [];

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

    if (hasProductAttributes) {
      descriptionWidgets.addAll(attributeWidgets);
      descriptionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
      );
    }

    for (var item in _productData['description_json']) {
      if (item['type'] == 'p') {
        String content = item['content']?.toString() ?? '';
        if (content.contains('類別：') ||
            content.contains('運費：') ||
            content.contains('單位：')) {
          continue;
        }

        if (content.isEmpty) {
          descriptionWidgets.add(
            const SizedBox(height: 16),
          );
        } else {
          descriptionWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(content, style: const TextStyle(fontSize: 16)),
            ),
          );
        }
      } else if (item['type'] == 'img' && item['content'] != null) {
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

  String _formatPrice(double price) {
    double roundedPrice = (price * 100).round() / 100;
    return '\$${roundedPrice.toInt()}';
  }

  String _formatSpecialCharacters(String text) {
    if (text.isEmpty) {
      return '';
    }

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

    String result = text;
    htmlEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });

    return result;
  }

  Widget _buildSelectOptions(Map<String, dynamic> option) {
    List<dynamic> optionValues = option['product_option_value'] as List;

    String selectedName = '';
    String selectedImage = '';
    for (var value in optionValues) {
      if (_selectedOptions.containsKey(option['product_option_id']) &&
          _selectedOptions[option['product_option_id']] == value['product_option_value_id']) {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedOptions.containsKey(option['product_option_id']) 
                ? _selectedOptions[option['product_option_id']] 
                : null,
            isExpanded: true,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text('請選擇${option['name'] ?? ''}...'),
            items: optionValues.map<DropdownMenuItem<String>>((value) {
              String optionText = value['name']?.toString().trim().isNotEmpty == true
                  ? value['name']
                  : value['disname'] ?? '';
              String imageUrl = value['image'] ?? '';

              return DropdownMenuItem<String>(
                value: value['product_option_value_id'],
                child: Row(
                  children: [
                    if (imageUrl.isNotEmpty)
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        child: Image.network(
                          imageUrl.startsWith('http')
                              ? imageUrl
                              : 'https://ismartomo.com.tw/image/$imageUrl',
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
                  
                  var selectedOption = optionValues.firstWhere(
                    (value) => value['product_option_value_id'] == newValue,
                    orElse: () => null,
                  );
                  if (selectedOption != null && 
                      selectedOption['image'] != null && 
                      selectedOption['image'].isNotEmpty) {
                    _updateCurrentImage(selectedOption['image']);
                  }
                });
              }
            },
          ),
        ),

        if (selectedName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                if (selectedImage.isNotEmpty)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      selectedImage.startsWith('http')
                          ? selectedImage
                          : 'https://ismartomo.com.tw/image/$selectedImage',
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

  Widget _buildDateTimeOptions(Map<String, dynamic> option) {
    String currentValue = _selectedOptions[option['product_option_id']] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final DateTime? date = await showDatePicker(
              context: context,
              initialDate: currentValue.isNotEmpty 
                  ? DateTime.parse(currentValue.split(' ')[0])
                  : DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('zh', 'TW'),
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

  List<String> _getAllProductImages() {
    List<String> images = [];
    
    if (_productData['thumb'] != null) {
      images.add(_productData['thumb']);
    }
    
    if (_productData['images'] != null && _productData['images'] is List) {
      for (var image in _productData['images']) {
        if (image['image'] != null) {
          images.add(image['image']);
        }
      }
    }
    
    return images;
  }

  void _updateCurrentImage(String? newImage) {
    if (newImage != null && newImage.isNotEmpty) {
      setState(() {
        String fullImageUrl = newImage.startsWith('http')
            ? newImage
            : 'https://ismartomo.com.tw/image/$newImage';
        
        _currentImage = fullImageUrl;
        
        if (!_carouselImages.contains(newImage)) {
          _carouselImages = [newImage];
          _currentImageIndex = 0;
        }
      });
    }
  }

  void _updateCurrentImageIndex(int index) {
    setState(() {
      _currentImageIndex = index;
      if (index < _carouselImages.length) {
        _currentImage = _carouselImages[index].startsWith('http')
            ? _carouselImages[index]
            : 'https://ismartomo.com.tw/image/${_carouselImages[index]}';
      }
    });
  }

  String _formatPriceString(dynamic price) {
    if (price == null) return '\$0';
    
    String priceStr = price.toString().trim();
    if (priceStr.isEmpty) return '\$0';
    
    // 如果已經包含 $ 符號，則直接返回
    if (priceStr.contains('\$')) return priceStr;
    
    // 移除所有非數字和小數點的字符
    String numericStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    
    try {
      double priceValue = double.parse(numericStr);
      // 轉換為整數，不顯示小數點
      return '\$${priceValue.toInt()}';
    } catch (e) {
      // 如果無法解析為數字，則直接添加 $ 符號
      return '\$$priceStr';
    }
  }
}
