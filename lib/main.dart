import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'services/api_service.dart';
import 'services/user_service.dart';
import 'pages/category_page.dart';
import 'pages/cart_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/product_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/information_page.dart';
import 'pages/favorite_page.dart';
import 'pages/bank_transfer_info_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/search_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/cart_service.dart';

// 全局 SharedPreferences 實例
late SharedPreferences prefs;

// 添加一個通用的文字大小計算類
class TextSizeConfig {
  static double? _screenWidth;
  static double? _screenHeight;
  static double _blockSizeHorizontal = 0;
  static double _blockSizeVertical = 0;
  
  static double textMultiplier = 0;
  static double imageSizeMultiplier = 0;
  static double heightMultiplier = 0;
  static double widthMultiplier = 0;
  
  static void init(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    _screenWidth = mediaQueryData.size.width;
    _screenHeight = mediaQueryData.size.height;
    
    _blockSizeHorizontal = _screenWidth! / 100;
    _blockSizeVertical = _screenHeight! / 100;
    
    textMultiplier = _blockSizeVertical;
    imageSizeMultiplier = _blockSizeHorizontal;
    heightMultiplier = _blockSizeVertical;
    widthMultiplier = _blockSizeHorizontal;
  }
  
  // 根據設計稿的文字大小計算實際顯示大小
  static double calculateTextSize(double size) {
    return size * textMultiplier / 6.5; // 6.5 是一個基準值，可以根據需要調整
  }
}

void main() async {
  // 確保 Flutter 綁定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 初始化 SharedPreferences
    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences 初始化成功');
  } catch (e) {
    debugPrint('SharedPreferences 初始化失敗: ${e.toString()}');
  }
  
  // 初始化 WebView
  try {
    // 根據平台選擇適當的 WebView 實現
    if (WebViewPlatform.instance == null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        WebViewPlatform.instance = AndroidWebViewPlatform();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        WebViewPlatform.instance = WebKitWebViewPlatform();
      }
    }
    debugPrint('WebView 平台初始化成功: ${defaultTargetPlatform.toString()}');
  } catch (e) {
    debugPrint('WebView 平台初始化失敗: ${e.toString()}');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化文字大小配置
    TextSizeConfig.init(context);
    
    return MaterialApp(
      title: 'API 數據展示',
      debugShowCheckedModeBanner: false,
      // 添加本地化支援
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'), // 繁體中文
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'TW'), // 設置默認語言為繁體中文
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        canvasColor: Colors.white,
        dividerColor: Colors.grey[300],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: TextSizeConfig.calculateTextSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
        // 設置通用文字主題
        textTheme: TextTheme(
          // 大標題
          headlineLarge: TextStyle(
            fontSize: TextSizeConfig.calculateTextSize(24),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          // 中標題
          headlineMedium: TextStyle(
            fontSize: TextSizeConfig.calculateTextSize(18),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          // 小標題
          headlineSmall: TextStyle(
            fontSize: TextSizeConfig.calculateTextSize(16),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          // 正文
          bodyLarge: TextStyle(
            fontSize: TextSizeConfig.calculateTextSize(14),
            color: Colors.black,
          ),
          // 小正文
          bodyMedium: TextStyle(
            fontSize: TextSizeConfig.calculateTextSize(12),
            color: Colors.black,
          ),
          // 標籤
          labelMedium: TextStyle(
            fontSize: TextSizeConfig.calculateTextSize(10),
            color: Colors.grey,
          ),
        ),
        useMaterial3: true, dialogTheme: DialogThemeData(backgroundColor: Colors.white),
      ),
      home: const HomePage(),
      routes: {
        '/cart': (context) => const CartPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/bank_transfer_info': (context) => const BankTransferInfoPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/product') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return ProductDetailPage(productDetails: args['productDetails']);
            },
          );
        }
        if (settings.name == '/product_detail') {
          final args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) {
              return ProductDetailPage(productDetails: args as Map<String, dynamic>);
            },
          );
        }
        if (settings.name == '/product_list') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return ProductListPage(arguments: args);
            },
          );
        }
        if (settings.name == '/information') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return InformationPage(
                informationId: args['information_id'],
                title: args['title'],
              );
            },
          );
        }
        return null;
      },
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
  
  // 商城設定
  String? _logoUrl;
  
  // 頁面列表
  late List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const CategoryPage(),
      const CartPage(),
      const FavoritePage(),
      const ProfilePage(),
    ];
    _fetchStoreSettings();
  }
  
  Future<void> _fetchStoreSettings() async {
    try {
      final response = await _apiService.getStoreSettings();
      
      setState(() {
        if (response.containsKey('settings') && 
            response['settings'] is Map && 
            response['settings'].containsKey('config_logo')) {
          _logoUrl = response['settings']['config_logo'];
        }
      });
    } catch (e) {
      // 處理錯誤，但不顯示錯誤消息，因為這不是關鍵功能
      print('獲取商城設定失敗: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _logoUrl != null
            ? Image.network(
                _logoUrl!.startsWith('http') 
                    ? _logoUrl! 
                    : 'https://ismartomo.com.tw/image/${_logoUrl!}',
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('商城首頁');
                },
              )
            : const Text('商城首頁'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // 購物車功能
              Navigator.of(context).pushNamed('/cart');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'globalMenu',
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.line,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            title: const Text('LINE'),
                            onTap: () async {
                              final Uri url = Uri.parse('https://lin.ee/fWAyD9T');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('無法開啟 LINE')),
                                  );
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.facebookMessenger,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            title: const Text('Facebook Messenger'),
                            onTap: () async {
                              final Uri url = Uri.parse('https://m.me/107852265523612');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('無法開啟 Messenger')),
                                  );
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: const FaIcon(FontAwesomeIcons.xmark),
                            title: const Text('關閉'),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.solidComments,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
}

// 將原來的首頁內容提取為單獨的Widget
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 橫幅數據
  List<Map<String, dynamic>> _banners = [];
  
  // 產品數據
  List<dynamic> _latestProducts = [];
  List<dynamic> _specialProducts = [];
  List<dynamic> _bestsellerProducts = [];
  
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
        _apiService.getSpecialProducts(),
        _apiService.getBestsellerProducts(),
      ]);
      
      final bannerResponse = results[0];
      final latestResponse = results[1];
      final specialResponse = results[2];
      final bestsellerResponse = results[3];
      
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
        
        // 解析特價產品數據
        if (specialResponse.containsKey('special_products')) {
          _specialProducts = specialResponse['special_products'];
        } else if (specialResponse.containsKey('products')) {
          _specialProducts = specialResponse['products'];
        }
        
        // 解析熱銷產品數據
        if (bestsellerResponse.containsKey('bestseller_products')) {
          _bestsellerProducts = bestsellerResponse['bestseller_products'];
        } else if (bestsellerResponse.containsKey('products')) {
          _bestsellerProducts = bestsellerResponse['products'];
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
    return _isLoading 
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
            child: Container(
              color: Colors.white, // 確保整個首頁背景為白色
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
                            style: TextStyle(
                              fontSize: TextSizeConfig.calculateTextSize(18),
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
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: _latestProducts.length > 8 ? 8 : _latestProducts.length,
                        itemBuilder: (context, index) {
                          final product = _latestProducts[index];
                          return ProductCard(
                            product: product,
                            onFavoritePressed: () => _showProductDetails(product),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // 特價產品
                    if (_specialProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Text(
                            '特價產品',
                            style: TextStyle(
                              fontSize: TextSizeConfig.calculateTextSize(18),
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
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: _specialProducts.length > 8 ? 8 : _specialProducts.length,
                        itemBuilder: (context, index) {
                          final product = _specialProducts[index];
                          return ProductCard(
                            product: product,
                            onFavoritePressed: () => _showProductDetails(product),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // 熱銷產品
                    if (_bestsellerProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Text(
                            '熱銷產品',
                            style: TextStyle(
                              fontSize: TextSizeConfig.calculateTextSize(18),
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
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: _bestsellerProducts.length > 8 ? 8 : _bestsellerProducts.length,
                        itemBuilder: (context, index) {
                          final product = _bestsellerProducts[index];
                          return ProductCard(
                            product: product,
                            onFavoritePressed: () => _showProductDetails(product),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
  }
  
  void _showProductDetails(Map<String, dynamic> product) async {
    if (product['product_id'] != null) {
      print('顯示產品詳情，產品ID: ${product['product_id']}');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(productDetails: product),
        ),
      );
    }
  }
}

class ProductListPageOld extends StatefulWidget {
  const ProductListPageOld({
    super.key, 
    required this.title,
    this.initialEndpoint = 'bestseller',
  });

  final String title;
  final String initialEndpoint;

  @override
  State<ProductListPageOld> createState() => _ProductListPageOldState();
}

class _ProductListPageOldState extends State<ProductListPageOld> {
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
        case 'bestseller':
          response = await _apiService.getBestsellerProducts();
          break;
        case 'latest':
          response = await _apiService.getLatestProducts();
          break;
        case 'special':
          response = await _apiService.getSpecialProducts();
          break;
        default:
          response = await _apiService.getBestsellerProducts();
      }

      setState(() {
        _isLoading = false;
        
        // 檢查 message 欄位
        if (response.containsKey('message') && response['message'] is List && response['message'].isNotEmpty) {
          _statusMessage = response['message'][0]['msg'] ?? '';
        }
        
        // 檢查各種可能的產品欄位
        if (response.containsKey('bestseller_products')) {
          _products = response['bestseller_products'];
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
                value: 'bestseller',
                child: Text('熱銷產品'),
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
          Container(
            color: Colors.white, // 確保狀態消息區域背景為白色
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
          child: Container(
            color: Colors.white, // 確保列表區域背景為白色
            child: RefreshIndicator(
              onRefresh: _fetchProducts,
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ProductCard(
                    product: product,
                    onFavoritePressed: () => _showProductDetails(product),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showProductDetails(Map<String, dynamic> product) async {
    if (product['product_id'] != null) {
      print('顯示產品詳情，產品ID: ${product['product_id']}');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(productDetails: product),
        ),
      );
    }
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onFavoritePressed;

  const ProductCard({
    Key? key,
    required this.product,
    this.onFavoritePressed,
  }) : super(key: key);

  String _formatPriceString(String? price) {
    if (price == null || price.isEmpty) return '\$0';
    // 移除所有非數字字符
    String numericPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    if (numericPrice.isEmpty) return '\$0';
    try {
      // 轉換為整數並格式化
      return '\$${int.parse(numericPrice)}';
    } catch (e) {
      return '\$0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPriceZeroOrEmpty = product['price'] == null || 
                              product['price'].toString().isEmpty || 
                              product['price'].toString() == '0';
    
    final hasSpecialPrice = product['special'] != null && 
                           product['special'] != false && 
                           product['special'].toString().isNotEmpty;

    final isDisPriceOne = product['dis_price'] == 1;

    return Card(
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
                      : 'https://ismartomo.com.tw/image/${product['thumb']}',
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
                if (!isDisPriceOne && !isPriceZeroOrEmpty) ...[
                  Row(
                    children: [
                      if (hasSpecialPrice) ...[
                        Text(
                          _formatPriceString(product['price'].toString()),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPriceString(product['special'].toString()),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else
                        Text(
                          _formatPriceString(product['price'].toString()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isPriceZeroOrEmpty)
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: onFavoritePressed,
                        ),
                      ElevatedButton(
                        onPressed: () {
                          if (!isPriceZeroOrEmpty) {
                            context.read<CartService>().addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已加入購物車'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(productDetails: product),
                              ),
                            );
                          }
                        },
                        child: Text(isPriceZeroOrEmpty ? '查看詳情' : '加入購物車'),
                      ),
                    ],
                  ),
                ] else if (isDisPriceOne) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: onFavoritePressed,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(productDetails: product),
                            ),
                          );
                        },
                        child: const Text('查看詳情'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
