import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _favoriteProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchFavoriteProducts();
  }

  Future<void> _fetchFavoriteProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 獲取用戶服務
      final userService = Provider.of<UserService>(context, listen: false);
      
      // 檢查用戶是否已登入
      if (!userService.isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = '請先登入以查看收藏';
        });
        return;
      }

      // 獲取用戶資料
      final userData = await userService.getUserData();
      final customerId = userData['customer_id'];

      if (customerId == null || customerId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '無法獲取用戶ID';
        });
        return;
      }

      // 獲取收藏列表
      final response = await _apiService.getCustomerWishlist(customerId);

      if (response.containsKey('customer_wishlist') && 
          response['customer_wishlist'] is List) {
        
        // 解析收藏列表
        final wishlistItems = List<Map<String, dynamic>>.from(response['customer_wishlist']);
        
        // 提取產品ID列表
        final productIds = wishlistItems.map((item) => item['product_id'].toString()).toList();
        
        // 如果沒有收藏的產品
        if (productIds.isEmpty) {
          setState(() {
            _isLoading = false;
            _favoriteProducts = [];
          });
          return;
        }
        
        // 獲取每個產品的詳細信息
        List<Map<String, dynamic>> products = [];
        
        // 為了避免過多的API請求，我們可以使用批量獲取產品的API
        // 但如果沒有這樣的API，我們可以逐個獲取
        for (String productId in productIds) {
          try {
            final productResponse = await _apiService.getProductDetails(productId);
            if (productResponse.containsKey('product') && 
                productResponse['product'] is List && 
                productResponse['product'].isNotEmpty) {
              products.add(productResponse['product'][0]);
            }
          } catch (e) {
            print('獲取產品 $productId 詳情失敗: ${e.toString()}');
          }
        }
        
        setState(() {
          _isLoading = false;
          _favoriteProducts = products;
        });
      } else {
        setState(() {
          _isLoading = false;
          _favoriteProducts = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取收藏列表失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
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
                    onPressed: _fetchFavoriteProducts,
                    child: const Text('重試'),
                  ),
                  if (_errorMessage == '請先登入以查看收藏')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        child: const Text('前往登入'),
                      ),
                    ),
                ],
              ),
            )
          : _favoriteProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.heart, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      '您的收藏列表是空的',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '瀏覽商品並點擊愛心圖標來添加收藏',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // 返回首頁
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('瀏覽商品'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchFavoriteProducts,
                child: GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                  ),
                  itemCount: _favoriteProducts.length,
                  itemBuilder: (context, index) {
                    final product = _favoriteProducts[index];
                    return _buildProductCard(product);
                  },
                ),
              ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        if (product['product_id'] != null) {
          // 導航到產品詳情頁面
          Navigator.of(context).pushNamed(
            '/product',
            arguments: {'productDetails': product},
          ).then((_) {
            // 返回時刷新收藏列表
            _fetchFavoriteProducts();
          });
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['thumb'] != null)
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Image.network(
                    product['thumb'].startsWith('http') 
                        ? product['thumb'] 
                        : 'https://ismartdemo.com.tw/image/${product['thumb']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatProductName(product['name'] ?? '未知產品'),
                    style: TextStyle(
                      fontSize: TextSizeConfig.calculateTextSize(12),
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
                          ? Text(
                              '${product['price']}',
                              style: TextStyle(
                                fontSize: TextSizeConfig.calculateTextSize(14),
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const SizedBox(),
                      ),
                      // 愛心按鈕
                      Expanded(
                        flex: 2, // 2/10 = 20%
                        child: Consumer<UserService>(
                          builder: (context, userService, child) {
                            final productId = product['product_id'].toString();
                            
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const FaIcon(
                                FontAwesomeIcons.solidHeart,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                // 從收藏中移除
                                await userService.removeFavorite(productId);
                                // 刷新列表
                                _fetchFavoriteProducts();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已從收藏中移除')),
                                );
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
                            // 添加商品到購物車
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已將 ${_formatProductName(product['name'])} 加入購物車'),
                                action: SnackBarAction(
                                  label: '查看購物車',
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/cart');
                                  },
                                ),
                              ),
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
  
  // 移除 HTML 標籤的輔助函數
  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
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
  
  // 格式化產品名稱，移除HTML標籤並處理特殊字符
  String _formatProductName(String name) {
    if (name.isEmpty) {
      return '未知產品';
    }
    
    // 先移除HTML標籤
    String strippedText = _stripHtmlTags(name);
    // 再處理特殊字符
    return _formatSpecialCharacters(strippedText);
  }
} 