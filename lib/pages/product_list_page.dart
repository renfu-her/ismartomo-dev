import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

// 排序選項枚舉
enum SortOption {
  defaultSort,
  nameAsc,
  nameDesc,
  priceLowHigh,
  priceHighLow,
  modelAsc,
  modelDesc,
}

class ProductListPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const ProductListPage({
    super.key,
    required this.arguments,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _products = [];
  String _categoryName = '';
  String _categoryId = '';
  SortOption _currentSortOption = SortOption.defaultSort;
  
  // 排序選項下拉菜單是否顯示
  bool _showSortOptions = false;
  
  @override
  void initState() {
    super.initState();
    _categoryId = widget.arguments['category_id'] ?? '';
    _categoryName = widget.arguments['category_name'] ?? '產品列表';
    _fetchProducts();
  }
  
  // 獲取產品列表
  Future<void> _fetchProducts() async {
    if (_categoryId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '分類ID不存在';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // 根據當前排序選項獲取排序參數
      String sortParam = '';
      String orderParam = '';
      
      switch (_currentSortOption) {
        case SortOption.defaultSort:
          sortParam = 'p.sort_order';
          orderParam = 'ASC';
          break;
        case SortOption.nameAsc:
          sortParam = 'pd.name';
          orderParam = 'ASC';
          break;
        case SortOption.nameDesc:
          sortParam = 'pd.name';
          orderParam = 'DESC';
          break;
        case SortOption.priceLowHigh:
          sortParam = 'p.price';
          orderParam = 'ASC';
          break;
        case SortOption.priceHighLow:
          sortParam = 'p.price';
          orderParam = 'DESC';
          break;
        case SortOption.modelAsc:
          sortParam = 'p.model';
          orderParam = 'ASC';
          break;
        case SortOption.modelDesc:
          sortParam = 'p.model';
          orderParam = 'DESC';
          break;
      }
      
      // 發送 API 請求
      final response = await _apiService.getProductList(
        categoryId: _categoryId,
        sort: sortParam,
        order: orderParam,
      );
      
      setState(() {
        _isLoading = false;
        if (response.containsKey('products') && response['products'] is List) {
          _products = response['products'];
        } else {
          _errorMessage = '無法獲取產品數據';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取產品失敗: ${e.toString()}';
      });
    }
  }
  
  // 切換排序選項
  void _changeSortOption(SortOption option) {
    setState(() {
      _currentSortOption = option;
      _showSortOptions = false;
    });
    _fetchProducts();
  }
  
  // 獲取排序選項的顯示文本
  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.defaultSort:
        return '預設';
      case SortOption.nameAsc:
        return '名稱 (A-Z)';
      case SortOption.nameDesc:
        return '名稱 (Z-A)';
      case SortOption.priceLowHigh:
        return '價格 (低 > 高)';
      case SortOption.priceHighLow:
        return '價格 (高 > 低)';
      case SortOption.modelAsc:
        return '型號 (A-Z)';
      case SortOption.modelDesc:
        return '型號 (Z-A)';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryName),
        actions: [
          // 排序按鈕
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              setState(() {
                _showSortOptions = !_showSortOptions;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要內容
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
                        onPressed: _fetchProducts,
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                ? const Center(child: Text('沒有找到產品'))
                : RefreshIndicator(
                    onRefresh: _fetchProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _buildProductCard(product);
                      },
                    ),
                  ),
          
          // 排序選項下拉菜單
          if (_showSortOptions)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(top: 8.0, right: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '排序方式',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSortOption(SortOption.defaultSort),
                    _buildSortOption(SortOption.nameAsc),
                    _buildSortOption(SortOption.nameDesc),
                    _buildSortOption(SortOption.priceLowHigh),
                    _buildSortOption(SortOption.priceHighLow),
                    _buildSortOption(SortOption.modelAsc),
                    _buildSortOption(SortOption.modelDesc),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 構建排序選項項目
  Widget _buildSortOption(SortOption option) {
    return InkWell(
      onTap: () => _changeSortOption(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: _currentSortOption == option ? Colors.grey.shade200 : Colors.transparent,
        child: Text(_getSortOptionText(option)),
      ),
    );
  }
  
  // 構建產品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product',
            arguments: {'productDetails': product},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 產品圖片 - 使用 AspectRatio 確保圖片為正方形
            AspectRatio(
              aspectRatio: 1.0, // 1:1 比例，確保為正方形
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: product['thumb'] != null
                    ? Image.network(
                        product['thumb'].startsWith('http')
                            ? product['thumb']
                            : 'https://ismartdemo.com.tw/image/${product['thumb']}',
                        fit: BoxFit.cover, // 使用 cover 而不是 contain，確保圖片填滿整個區域
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            
            // 產品信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 產品名稱
                  Text(
                    _formatSpecialCharacters(product['name'] ?? '未知產品'),
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 底部區域：價格、愛心、購物車分為三欄
                  Row(
                    children: [
                      // 價格佔據約50%的寬度
                      Expanded(
                        flex: 5, // 5/10 = 50%
                        child: product['price'] != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 如果有特價，顯示原價（加上橫線）和特價
                                if (product['special'] != null && product['special'] != false)
                                  Text(
                                    '${product['price']}',
                                    style: const TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                // 顯示價格（如果有特價則顯示特價，否則顯示原價）
                                Text(
                                  product['special'] != null && product['special'] != false
                                      ? '${product['special']}'
                                      : '${product['price']}',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                      ),
                      // 愛心按鈕
                      Expanded(
                        flex: 2, // 2/10 = 20%
                        child: Consumer<UserService>(
                          builder: (context, userService, child) {
                            final productId = product['product_id'].toString();
                            final isFavorite = userService.isFavorite(productId);
                            
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: FaIcon(
                                isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                if (userService.isLoggedIn) {
                                  if (isFavorite) {
                                    userService.removeFavorite(productId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('已從收藏中移除')),
                                    );
                                  } else {
                                    userService.addFavorite(productId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('已加入收藏')),
                                    );
                                  }
                                } else {
                                  // 提示用戶登入
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
                                }
                              },
                            );
                          },
                        ),
                      ),
                      // 購物車按鈕
                      Expanded(
                        flex: 3, // 3/10 = 30%
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const FaIcon(FontAwesomeIcons.cartShopping, size: 18),
                          onPressed: () {
                            // 導航到產品詳情頁面，與點擊產品卡片的行為一致
                            Navigator.pushNamed(
                              context,
                              '/product',
                              arguments: {'productDetails': product},
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
} 