import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'product_detail_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _searchResults = [];
  
  // 防抖計時器
  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
    // 在頁面加載後自動顯示鍵盤
    Future.delayed(Duration.zero, () {
      _searchFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // 搜尋產品
  Future<void> _searchProducts(String keyword) async {
    // 如果關鍵字為空，清空結果
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.searchProducts(keyword);
      
      setState(() {
        _isLoading = false;
        if (response.containsKey('products') && response['products'] is List) {
          _searchResults = response['products'];
        } else {
          _searchResults = [];
          _errorMessage = '沒有找到相關產品';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _searchResults = [];
      });
    }
  }
  
  // 處理搜尋輸入
  void _onSearchChanged(String value) {
    // 取消之前的計時器
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // 設置新的計時器
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchProducts(value);
    });
  }
  
  // 清除搜尋
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _errorMessage = '';
    });
  }

  // 構建產品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    // 檢查產品價格是否為0或空字符串
    bool isPriceZeroOrEmpty = false;
    
    if (product['price'] != null) {
      String priceStr = product['price'].toString().trim();
      // 檢查是否為空字符串
      if (priceStr.isEmpty) {
        isPriceZeroOrEmpty = true;
      } else {
        // 移除貨幣符號和空格，轉換為數字
        priceStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
        try {
          double price = double.parse(priceStr);
          isPriceZeroOrEmpty = price == 0;
        } catch (e) {
          // 如果無法解析價格，檢查原始字符串是否為 "$0" 或類似形式
          isPriceZeroOrEmpty = priceStr.contains('0') && !priceStr.contains(RegExp(r'[1-9]'));
        }
      }
    } else {
      // 如果價格為null，視為零價格
      isPriceZeroOrEmpty = true;
    }
    
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
              aspectRatio: 1.0,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: product['thumb'] != null
                    ? Image.network(
                        product['thumb'].startsWith('http')
                            ? product['thumb']
                            : 'https://ismartomo.com.tw/image/${product['thumb']}',
                        fit: BoxFit.cover,
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
                      // 價格佔據約50%的寬度 - 只有當價格不為零或空時才顯示
                      Expanded(
                        flex: 5,
                        child: !isPriceZeroOrEmpty && product['price'] != null
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
                      // 愛心按鈕 - 只有當價格不為零或空時才顯示
                      if (!isPriceZeroOrEmpty)
                        Expanded(
                          flex: 2,
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
                      // 詳細資料按鈕 - 始終顯示
                      Expanded(
                        flex: 3,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: FaIcon(
                            isPriceZeroOrEmpty ? FontAwesomeIcons.circleInfo : FontAwesomeIcons.cartShopping,
                            size: 18,
                          ),
                          onPressed: () {
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: '搜尋產品...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearch,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _searchProducts(_searchController.text);
              }
            },
            child: const Text('搜尋', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                          ? '請輸入關鍵字搜尋產品'
                          : '沒有找到相關產品',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _searchProducts(_searchController.text),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final product = _searchResults[index];
                      return _buildProductCard(product);
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }
} 