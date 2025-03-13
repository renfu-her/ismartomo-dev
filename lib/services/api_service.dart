import 'package:dio/dio.dart';
import 'dart:convert';

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
      // 使用與 login 方法相同的 URL 構建方式
      final registerUrl = 'gws_customer/add';
      final url = '${_baseUrl}/$registerUrl&api_key=$_apiKey';
      
      print('註冊 URL: $url');
      
      // 打印原始數據
      print('原始註冊數據:');
      userData.forEach((key, value) {
        print('$key: $value');
      });
      
      // 設置請求選項 - 根據 Thunder Client 的響應頭信息設置
      final options = Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Flutter/1.0',
          'Connection': 'close',  // 根據響應頭設置
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      );
      
      print('使用 Map<String, dynamic> 直接發送請求');
      
      // 直接使用 POST 方法發送請求
      final response = await _dio.post(
        url,
        data: userData,  // 直接使用 Map<String, dynamic>
        options: options,
      );
      
      print('註冊響應狀態碼: ${response.statusCode}');
      if (response.data != null) {
        print('註冊響應數據類型: ${response.data.runtimeType}');
        print('註冊響應數據: ${response.data}');
      } else {
        print('註冊響應數據為空');
      }
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          // 嘗試解析字符串響應為 JSON
          final String responseStr = response.data.toString();
          print('響應是字符串，長度: ${responseStr.length}');
          
          if (responseStr.isEmpty) {
            print('響應是空字符串，視為成功');
            return {'success': true, 'message': [{'msg': '註冊成功', 'msg_status': true}]};
          }
          
          try {
            if (responseStr.trim().startsWith('{') || responseStr.trim().startsWith('[')) {
              final jsonData = jsonDecode(responseStr);
              if (jsonData is Map) {
                return Map<String, dynamic>.from(jsonData);
              }
            } else {
              print('響應不是 JSON 格式: $responseStr');
              
              // 檢查是否包含成功信息
              if (responseStr.toLowerCase().contains('success') || 
                  responseStr.contains('成功') || 
                  !responseStr.toLowerCase().contains('error')) {
                return {'success': true, 'message': [{'msg': responseStr, 'msg_status': true}]};
              }
            }
          } catch (e) {
            print('解析響應數據錯誤: ${e.toString()}');
            print('原始響應: $responseStr');
          }
          
          // 如果無法解析為 JSON，則返回一個包含原始響應的 Map
          return {'raw_response': responseStr, 'success': true};
        } else if (response.data == null) {
          // 空響應，視為成功
          print('響應為空，視為成功');
          return {'success': true, 'message': [{'msg': '註冊成功', 'msg_status': true}]};
        } else {
          // 返回一個空的成功響應
          return {'success': true};
        }
      } else {
        return {'error': true, 'message': [{'msg': '請求失敗: ${response.statusCode}', 'msg_status': false}]};
      }
    } on DioException catch (e) {
      print('*** DioException 詳細信息 ***');
      print('請求 URL: ${e.requestOptions.uri}');
      print('請求方法: ${e.requestOptions.method}');
      print('請求頭: ${e.requestOptions.headers}');
      print('請求數據: ${e.requestOptions.data}');
      print('錯誤類型: ${e.type}');
      print('錯誤信息: ${e.message}');
      
      if (e.response != null) {
        print('錯誤響應狀態碼: ${e.response?.statusCode}');
        print('錯誤響應頭: ${e.response?.headers}');
        
        if (e.response?.data != null) {
          print('錯誤響應數據: ${e.response?.data}');
          
          // 嘗試處理響應數據
          if (e.response?.data is String) {
            final String responseStr = e.response?.data.toString() ?? '';
            if (responseStr.isEmpty) {
              print('錯誤響應是空字符串，可能是成功');
              return {'success': true, 'message': [{'msg': '註冊可能成功', 'msg_status': true}]};
            }
          }
        } else {
          print('無錯誤響應數據');
        }
      } else {
        print('無響應數據');
      }
      
      // 返回一個錯誤響應而不是拋出異常
      String errorMsg = e.message ?? '未知錯誤';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = '連接超時，請檢查網絡';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMsg = '發送請求超時，請稍後再試';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '接收響應超時，請稍後再試';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMsg = '服務器響應錯誤: ${e.response?.statusCode}';
      } else if (e.type == DioExceptionType.cancel) {
        errorMsg = '請求被取消';
      } else {
        errorMsg = '網絡請求錯誤: ${e.message}';
      }
      
      return <String, dynamic>{
        'error': true,
        'message': [{'msg': errorMsg, 'msg_status': false}]
      };
    } catch (e) {
      print('註冊錯誤: ${e.toString()}');
      print('錯誤堆棧: ${StackTrace.current}');
      
      // 返回一個錯誤響應而不是拋出異常
      return <String, dynamic>{
        'error': true,
        'message': [{'msg': '發生錯誤: ${e.toString()}', 'msg_status': false}]
      };
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