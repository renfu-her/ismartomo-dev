import 'package:dio/dio.dart';

class ApiService {
  static const String _baseUrl = 'https://ismartdemo.com.tw/index.php?route=extension/module/api';
  static const String _apiKey = 'CNQ4eX5WcbgFQVkBXFKmP9AE2AYUpU2HySz2wFhwCZ3qExG6Tep7ZCSZygwzYfsF';
  
  final Dio _dio = Dio();
  
  // 單例模式
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
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
  
  // 獲取產品詳情
  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    return _get('gws_appproduct', extraParams: {'product_id': productId});
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
  
  // 通用 GET 請求方法
  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, dynamic>? extraParams}) async {
    try {
      // 構建完整的 URL
      String url = '$_baseUrl/$endpoint&api_key=$_apiKey';
      
      // 添加額外的參數
      if (extraParams != null && extraParams.isNotEmpty) {
        extraParams.forEach((key, value) {
          url += '&$key=$value';
        });
      }
      
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
  
  // 通用 POST 請求方法
  Future<Map<String, dynamic>> _post(String endpoint, {Map<String, dynamic>? data, Map<String, dynamic>? extraParams}) async {
    try {
      // 構建完整的 URL
      String url = '$_baseUrl/$endpoint&api_key=$_apiKey';
      
      // 添加額外的參數
      if (extraParams != null && extraParams.isNotEmpty) {
        extraParams.forEach((key, value) {
          url += '&$key=$value';
        });
      }
      
      // 發送請求
      final response = await _dio.post(url, data: data);
      
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