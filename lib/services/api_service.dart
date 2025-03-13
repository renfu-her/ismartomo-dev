import 'package:dio/dio.dart';

class ApiService {
  static const String _baseUrl = 'https://ismartdemo.com.tw/index.php?route=extension/module/api';
  static const String _apiKey = 'CNQ4eX5WcbgFQVkBXFKmP9AE2AYUpU2HySz2wFhwCZ3qExG6Tep7ZCSZygwzYfsF';
  
  // 獲取 API Key
  String get apiKey => _apiKey;
  
  // 獲取基礎 URL
  String get baseUrl => _baseUrl;
  
  final Dio _dio = Dio();
  
  // 單例模式
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal() {
    // 初始化 Dio
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 10);
    
    // 添加攔截器，用於日誌記錄
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) {
        print(object.toString());
      },
    ));
  }
  
  // 用戶登入
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 使用 _get 方法來保持一致性
      final loginUrl = 'gws_appcustomer/login';
      print('登入 URL: ${_baseUrl}/$loginUrl&api_key=$_apiKey');
      
      final response = await _dio.post(
        '${_baseUrl}/$loginUrl&api_key=$_apiKey',
        data: FormData.fromMap({
          'email': email,
          'password': password,
        }),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      print('登入響應狀態碼: ${response.statusCode}');
      print('登入響應數據: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else {
          throw Exception('返回數據格式錯誤');
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('登入錯誤: ${e.toString()}');
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
  
  // 獲取用戶資料
  Future<Map<String, dynamic>> getUserData(String email) async {
    try {
      // 使用 _get 方法來保持一致性
      return _get('gws_appcustomer', extraParams: {'email': email});
    } catch (e) {
      print('獲取用戶資料錯誤: ${e.toString()}');
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
  
  // 獲取熱門產品
  Future<Map<String, dynamic>> getPopularProducts() async {
    return _get('gws_appproducts_popular&limit=8');
  }
  
  // 獲取最新產品
  Future<Map<String, dynamic>> getLatestProducts() async {
    return _get('gws_appproducts_latest&limit=8');
  }
  
  // 獲取特價產品
  Future<Map<String, dynamic>> getSpecialProducts() async {
    return _get('gws_appproducts_special&limit=8');
  }
  
  // 獲取首頁橫幅數據
  Future<Map<String, dynamic>> getHomeBanners() async {
    return _get('gws_appservice/allHomeBanner');
  }
  
  // 獲取產品分類
  Future<Map<String, dynamic>> getCategories() async {
    return _get('gws_appcategories');
  }
  
  // 獲取特定分類的產品
  Future<Map<String, dynamic>> getCategoryProducts(String categoryId) async {
    return _get('gws_appcategory_products', extraParams: {'category_id': categoryId});
  }
  
  // 獲取產品列表（根據分類ID，支持排序）
  Future<Map<String, dynamic>> getProductList({
    required String categoryId,
    String? sort,
    String? order,
  }) async {
    Map<String, dynamic> params = {'category_id': categoryId};
    
    // 添加排序參數
    if (sort != null && sort.isNotEmpty) {
      params['sort'] = sort;
    }
    
    // 添加排序方向參數
    if (order != null && order.isNotEmpty) {
      params['order'] = order;
    }
    
    return _get('gws_products', extraParams: params);
  }
  
  // 獲取產品詳情
  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    try {
      // 直接構建完整的 URL
      String url = 'https://ismartdemo.com.tw/index.php?route=extension/module/api/gws_appproduct&api_key=$_apiKey&product_id=$productId';
      
      print('獲取產品詳情，URL: $url');
      
      // 發送請求
      final response = await _dio.get(url);
      
      // 檢查響應
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else {
          throw Exception('返回數據格式錯誤');
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
  
  // 搜索產品
  Future<Map<String, dynamic>> searchProducts(String keyword) async {
    return _get('gws_appsearch', extraParams: {'search': keyword});
  }
  
  // 獲取所有分類
  Future<Map<String, dynamic>> getAllCategories() async {
    return _get('gws_appservice/allCategories');
  }
  
  // 獲取全域網站設定
  Future<Map<String, dynamic>> getStoreSettings() async {
    return _get('gws_store_settings');
  }
  
  // 獲取區域列表
  Future<Map<String, dynamic>> getZones(String countryId) async {
    try {
      final response = await _get('gws_zone', extraParams: {'country_id': countryId});
      print('獲取區域列表響應: ${response.toString()}');
      return response;
    } catch (e) {
      print('獲取區域列表錯誤: ${e.toString()}');
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
  
  // 用戶註冊
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final registerUrl = 'gws_customer/add';
      print('註冊 URL: ${_baseUrl}/$registerUrl&api_key=$_apiKey');
      
      final response = await _dio.post(
        '${_baseUrl}/$registerUrl&api_key=$_apiKey',
        data: FormData.fromMap(userData),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      print('註冊響應狀態碼: ${response.statusCode}');
      print('註冊響應數據: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else {
          throw Exception('返回數據格式錯誤');
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('註冊錯誤: ${e.toString()}');
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
  
  // 通用 GET 請求方法
  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, dynamic>? extraParams}) async {
    try {
      // 構建完整的 URL
      String url;
      
      // 檢查 endpoint 是否包含斜杠
      if (endpoint.contains('/')) {
        // 如果包含斜杠，則使用原始 endpoint
        url = '${_baseUrl}/$endpoint&api_key=$_apiKey';
      } else {
        // 如果不包含斜杠，則直接添加 endpoint
        url = '${_baseUrl}/$endpoint&api_key=$_apiKey';
      }
      
      // 添加額外的參數
      if (extraParams != null && extraParams.isNotEmpty) {
        extraParams.forEach((key, value) {
          url += '&$key=$value';
        });
      }
      
      print('請求 URL: $url'); // 添加日誌以便調試
      
      // 發送請求
      final response = await _dio.get(url);
      
      // 檢查響應
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else {
          throw Exception('返回數據格式錯誤');
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
} 