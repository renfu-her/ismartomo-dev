import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'services/api_service.dart';
import 'pages/banner_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API 數據展示',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 橫幅數據
  List<Map<String, dynamic>> _banners = [];
  
  // 產品數據
  List<dynamic> _latestProducts = [];
  List<dynamic> _popularProducts = [];
  
  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }
  
  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // 並行獲取所有數據
      final results = await Future.wait([
        _apiService.getHomeBanners(),
        _apiService.getLatestProducts(),
        _apiService.getPopularProducts(),
      ]);
      
      final bannerResponse = results[0];
      final latestResponse = results[1];
      final popularResponse = results[2];
      
      setState(() {
        _isLoading = false;
        
        // 解析橫幅數據
        if (bannerResponse.containsKey('home_full_banner') && bannerResponse['home_full_banner'] is List) {
          _banners = List<Map<String, dynamic>>.from(bannerResponse['home_full_banner']);
        }
        
        // 解析最新產品數據
        if (latestResponse.containsKey('latest_products')) {
          _latestProducts = latestResponse['latest_products'];
        } else if (latestResponse.containsKey('products')) {
          _latestProducts = latestResponse['products'];
        }
        
        // 解析熱門產品數據
        if (popularResponse.containsKey('popular_products')) {
          _popularProducts = popularResponse['popular_products'];
        } else if (popularResponse.containsKey('products')) {
          _popularProducts = popularResponse['products'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取數據失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商城首頁'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 搜索功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('搜索功能待實現')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // 購物車功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('購物車功能待實現')),
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
                    onPressed: _fetchHomeData,
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 輪播圖
                    if (_banners.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200.0,
                          aspectRatio: 16/9,
                          viewportFraction: 1.0,
                          initialPage: 0,
                          enableInfiniteScroll: true,
                          reverse: false,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 3),
                          autoPlayAnimationDuration: const Duration(milliseconds: 800),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enlargeCenterPage: false,
                          scrollDirection: Axis.horizontal,
                        ),
                        items: _banners.map((banner) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () {
                                  if (banner['link'] != null && banner['link'].toString().isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('打開鏈接: ${banner['link']}')),
                                    );
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Image.network(
                                      banner['image'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.image_not_supported, size: 50),
                                        );
                                      },
                                    ),
                                    if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.7),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Text(
                                            banner['title'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // 最新產品
                    if (_latestProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Text(
                            '最新產品',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: _latestProducts.length > 8 ? 8 : _latestProducts.length,
                        itemBuilder: (context, index) {
                          final product = _latestProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () => _showProductDetails(product),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // 熱門產品
                    if (_popularProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Text(
                            '熱門產品',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: _popularProducts.length > 8 ? 8 : _popularProducts.length,
                        itemBuilder: (context, index) {
                          final product = _popularProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () => _showProductDetails(product),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // 處理底部導航項目點擊
          if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('您點擊了: ${_getBottomNavItemName(index)}')),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.list),
            label: '分類',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.cartShopping),
            label: '購物車',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.heart),
            label: '收藏',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user),
            label: '我的',
          ),
        ],
      ),
    );
  }
  
  String _getBottomNavItemName(int index) {
    switch (index) {
      case 0: return '首頁';
      case 1: return '分類';
      case 2: return '購物車';
      case 3: return '收藏';
      case 4: return '我的';
      default: return '';
    }
  }
  
  void _showProductDetails(Map<String, dynamic> product) async {
    if (product['product_id'] != null) {
      try {
        // 顯示加載對話框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        // 獲取產品詳情
        final details = await _apiService.getProductDetails(product['product_id'].toString());
        
        // 關閉加載對話框
        Navigator.of(context).pop();
        
        // 顯示產品詳情頁面
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productDetails: details),
            ),
          );
        }
      } catch (e) {
        // 關閉加載對話框
        Navigator.of(context).pop();
        
        // 顯示錯誤信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法獲取產品詳情: ${e.toString()}')),
        );
      }
    }
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key, 
    required this.title,
    this.initialEndpoint = 'popular',
  });

  final String title;
  final String initialEndpoint;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _statusMessage = '';
  late String _currentEndpoint;

  @override
  void initState() {
    super.initState();
    _currentEndpoint = widget.initialEndpoint;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = '';
    });

    try {
      Map<String, dynamic> response;
      
      // 根據當前選擇的端點獲取不同的產品數據
      switch (_currentEndpoint) {
        case 'popular':
          response = await _apiService.getPopularProducts();
          break;
        case 'latest':
          response = await _apiService.getLatestProducts();
          break;
        case 'special':
          response = await _apiService.getSpecialProducts();
          break;
        default:
          response = await _apiService.getPopularProducts();
      }

      setState(() {
        _isLoading = false;
        
        // 檢查 message 欄位
        if (response.containsKey('message') && response['message'] is List && response['message'].isNotEmpty) {
          _statusMessage = response['message'][0]['msg'] ?? '';
        }
        
        // 檢查各種可能的產品欄位
        if (response.containsKey('popular_products')) {
          _products = response['popular_products'];
        } 
        else if (response.containsKey('latest_products')) {
          _products = response['latest_products'];
        }
        else if (response.containsKey('special_products')) {
          _products = response['special_products'];
        }
        else if (response.containsKey('products')) {
          _products = response['products'];
        } 
        else {
          _products = [];
          _errorMessage = '無法解析產品數據';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取數據失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _currentEndpoint = value;
              });
              _fetchProducts();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'popular',
                child: Text('熱門產品'),
              ),
              const PopupMenuItem(
                value: 'latest',
                child: Text('最新產品'),
              ),
              const PopupMenuItem(
                value: 'special',
                child: Text('特價產品'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('沒有找到產品'),
      );
    }

    return Column(
      children: [
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchProducts,
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ProductCard(
                  product: product,
                  onTap: () => _showProductDetails(product),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  void _showProductDetails(Map<String, dynamic> product) async {
    if (product['product_id'] != null) {
      try {
        // 顯示加載對話框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        // 獲取產品詳情
        final details = await _apiService.getProductDetails(product['product_id'].toString());
        
        // 關閉加載對話框
        Navigator.of(context).pop();
        
        // 顯示產品詳情頁面
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productDetails: details),
            ),
          );
        }
      } catch (e) {
        // 關閉加載對話框
        Navigator.of(context).pop();
        
        // 顯示錯誤信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法獲取產品詳情: ${e.toString()}')),
        );
      }
    }
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key, 
    required this.product, 
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['thumb'] != null)
              AspectRatio(
                aspectRatio: 1.0, // 正方形比例
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
                        child: Icon(Icons.image_not_supported, size: 50),
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
                    product['name'] ?? '未知產品',
                    style: const TextStyle(
                      fontSize: 12,
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
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const SizedBox(),
                      ),
                      // 愛心按鈕
                      Expanded(
                        flex: 2, // 2/10 = 20%
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const FaIcon(FontAwesomeIcons.heart, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已加入收藏')),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已加入購物車')),
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
}

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> productDetails;
  
  const ProductDetailPage({super.key, required this.productDetails});
  
  @override
  Widget build(BuildContext context) {
    // 獲取產品數據
    final product = productDetails.containsKey('product') ? productDetails['product'] : {};
    
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? '產品詳情'),
      ),
      body: product.isEmpty 
        ? const Center(child: Text('無法獲取產品詳情'))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 產品圖片
                if (product['thumb'] != null)
                  SizedBox(
                    width: double.infinity,
                    height: 250,
                    child: Image.network(
                      product['thumb'].startsWith('http') 
                          ? product['thumb'] 
                          : 'https://ismartdemo.com.tw/image/${product['thumb']}',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_not_supported, size: 80),
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
                      Text(
                        product['name'] ?? '未知產品',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (product['price'] != null)
                        Text(
                          '價格: ${product['price']}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (product['model'] != null)
                        Text('型號: ${product['model']}'),
                      if (product['quantity'] != null)
                        Text(
                          '庫存: ${product['quantity']}',
                          style: TextStyle(
                            color: int.parse(product['quantity'].toString()) > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      if (product['manufacturer'] != null)
                        Text('製造商: ${product['manufacturer']}'),
                      
                      const SizedBox(height: 16),
                      const Text(
                        '產品描述',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (product['description'] != null)
                        Text(_stripHtmlTags(product['description'])),
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
}
