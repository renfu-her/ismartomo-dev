import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../main.dart';

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
        // 移除 print 語句
      },
    ));
  }
  
  // 獲取用戶 ID
  Future<String?> _getCustomerId() async {
    try {
      return prefs.getString('user_customer_id');
    } catch (e) {
      debugPrint('獲取用戶 ID 錯誤: ${e.toString()}');
      return null;
    }
  }
  
  // 用戶登入
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 使用 _get 方法來保持一致性
      final loginUrl = 'gws_appcustomer/login';
      
      final response = await _dio.post(
        '$_baseUrl/$loginUrl&api_key=$_apiKey',
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
  
  // 獲取用戶資料
  Future<Map<String, dynamic>> getUserData(String email) async {
    try {
      // 使用 _get 方法來保持一致性
      return _get('gws_appcustomer', extraParams: {'email': email});
    } catch (e) {
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
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      
      // 直接構建完整的 URL
      String url = '$_baseUrl/gws_appproduct&api_key=$_apiKey&product_id=$productId';
      
      // 添加 customer_id 參數
      if (customerId != null && customerId.isNotEmpty) {
        url += '&customer_id=$customerId';
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
      return response;
    } catch (e) {
      throw Exception('API 請求錯誤: ${e.toString()}');
    }
  }
  
  // 用戶註冊
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      // 使用與 login 方法相同的 URL 構建方式
      final registerUrl = 'gws_customer/add';
      final url = '$_baseUrl/$registerUrl&api_key=$_apiKey';
      
      // 確保包含必要參數
      if (!userData.containsKey('company')) {
        userData['company'] = '';
      }
      
      // 創建 FormData
      final formData = FormData.fromMap(userData);
      
      // 設置請求選項 - 根據 Thunder Client 的響應頭信息設置
      final options = Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        headers: {
          'Accept': 'application/json',
          'Connection': 'close',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      );
      
      // 直接使用 POST 方法發送請求
      final response = await _dio.post(
        url,
        data: formData,
        options: options,
      );

      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          // 嘗試解析字符串響應為 JSON
          final String responseStr = response.data.toString();
          
          if (responseStr.isEmpty) {
            return {'success': true, 'message': [{'msg': '註冊成功', 'msg_status': true}]};
          }
          
          try {
            if (responseStr.trim().startsWith('{') || responseStr.trim().startsWith('[')) {
              final jsonData = jsonDecode(responseStr);
              if (jsonData is Map) {
                return Map<String, dynamic>.from(jsonData);
              }
            } else {
              // 檢查是否包含成功信息
              if (responseStr.toLowerCase().contains('success') || 
                  responseStr.contains('成功') || 
                  !responseStr.toLowerCase().contains('error')) {
                return {'success': true, 'message': [{'msg': responseStr, 'msg_status': true}]};
              }
            }
          } catch (e) {
            // 解析錯誤處理
          }
          
          // 如果無法解析為 JSON，則返回一個包含原始響應的 Map
          return {'raw_response': responseStr, 'success': true};
        } else if (response.data == null) {
          // 空響應，視為成功
          return {'success': true, 'message': [{'msg': '註冊成功', 'msg_status': true}]};
        } else {
          // 返回一個空的成功響應
          return {'success': true};
        }
      } else {
        return {'error': true, 'message': [{'msg': '請求失敗: ${response.statusCode}', 'msg_status': false}]};
      }
    } on DioException catch (e) {
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
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      
      // 構建完整的 URL
      String url;
      
      // 檢查 endpoint 是否包含斜杠
      if (endpoint.contains('/')) {
        // 如果包含斜杠，則使用原始 endpoint
        url = '$_baseUrl/$endpoint&api_key=$_apiKey';
      } else {
        // 如果不包含斜杠，則直接添加 endpoint
        url = '$_baseUrl/$endpoint&api_key=$_apiKey';
      }
      
      // 添加 customer_id 參數
      if (customerId != null && customerId.isNotEmpty) {
        url += '&customer_id=$customerId';
      }
      
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
  
  // 獲取用戶收藏列表
  Future<Map<String, dynamic>> getCustomerWishlist(String customerId) async {
    return _get('gws_customer_wishlist', extraParams: {'customer_id': customerId});
  }
  
  // 添加產品到收藏列表
  Future<Map<String, dynamic>> addToWishlist(String customerId, String productId) async {
    return _get('gws_customer_wishlist/add', extraParams: {
      'customer_id': customerId,
      'product_id': productId
    });
  }
  
  // 從收藏列表中移除產品
  Future<Map<String, dynamic>> removeFromWishlist(String customerId, String productId) async {
    return _get('gws_customer_wishlist/remove', extraParams: {
      'customer_id': customerId,
      'product_id': productId
    });
  }
  
  // 獲取資訊詳情
  Future<Map<String, dynamic>> getInformationById(String informationId) async {
    try {
      final response = await _get('gws_information&information_id=$informationId');
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // 獲取所有資訊
  Future<Map<String, dynamic>> getAllInformation() async {
    try {
      final response = await _get('gws_information');
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // 獲取會員資料
  Future<Map<String, dynamic>> getCustomerProfile() async {
    try {
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('用戶未登入');
      }
      
      final response = await _get('gws_customer&customer_id=$customerId');
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // 獲取客戶地址
  Future<Map<String, dynamic>> getCustomerAddress(String addressId) async {
    try {
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('用戶未登入');
      }
      
      final response = await _get('gws_appcustomer_address&customer_id=$customerId&address_id=$addressId');
      return response;
    } catch (e) {
      throw Exception('獲取地址失敗: ${e.toString()}');
    }
  }
  
  // 獲取客戶所有地址
  Future<Map<String, dynamic>> getCustomerAddressList(String customerId) async {
    try {
      if (customerId.isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      final response = await _get('gws_appcustomer_address&customer_id=$customerId');
      return response;
    } catch (e) {
      throw Exception('獲取地址列表失敗: ${e.toString()}');
    }
  }
  
  // 新增客戶地址
  Future<Map<String, dynamic>> addCustomerAddress(Map<String, dynamic> addressData) async {
    try {
      final customerId = addressData['customer_id'];
      if (customerId == null || customerId.toString().isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      // 構建 URL
      final url = '$_baseUrl/gws_customer_address/add&api_key=$_apiKey&customer_id=$customerId';
      
      // 創建 FormData
      final formData = FormData.fromMap(addressData);
      
      // 發送請求
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
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
      throw Exception('新增地址失敗: ${e.toString()}');
    }
  }
  
  // 修改客戶地址
  Future<Map<String, dynamic>> editCustomerAddress(String addressId, Map<String, dynamic> addressData) async {
    try {
      final customerId = addressData['customer_id'];
      if (customerId == null || customerId.toString().isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      if (addressId.isEmpty) {
        throw Exception('地址ID不能為空');
      }
      
      // 構建 URL
      final url = '$_baseUrl/gws_customer_address/edit&api_key=$_apiKey&customer_id=$customerId&address_id=$addressId';
      
      // 創建 FormData
      final formData = FormData.fromMap(addressData);
      
      // 發送請求
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
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
      throw Exception('修改地址失敗: ${e.toString()}');
    }
  }
  
  // 刪除客戶地址
  Future<Map<String, dynamic>> deleteCustomerAddress(String customerId, String addressId) async {
    try {
      if (customerId.isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      if (addressId.isEmpty) {
        throw Exception('地址ID不能為空');
      }
      
      // 使用 GET 方法刪除地址
      return _get('gws_customer_address/remove', extraParams: {
        'customer_id': customerId,
        'address_id': addressId
      });
    } catch (e) {
      throw Exception('刪除地址失敗: ${e.toString()}');
    }
  }
  
  // 更新會員資料
  Future<Map<String, dynamic>> updateCustomerProfile(String customerId, Map<String, dynamic> data) async {
    try {
      // 構建 URL
      final url = '$_baseUrl/gws_customer/edit&api_key=$_apiKey&customer_id=$customerId';
      
      // 創建 FormData
      final formData = FormData.fromMap(data);
      
      // 發送請求
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          // 嘗試解析字符串響應為 JSON
          final String responseStr = response.data.toString();
          
          if (responseStr.isEmpty) {
            return {'success': true, 'message': [{'msg': '更新成功', 'msg_status': true}]};
          }
          
          try {
            if (responseStr.trim().startsWith('{') || responseStr.trim().startsWith('[')) {
              final jsonData = jsonDecode(responseStr);
              if (jsonData is Map) {
                return Map<String, dynamic>.from(jsonData);
              }
            } else {
              // 檢查是否包含成功信息
              if (responseStr.toLowerCase().contains('success') || 
                  responseStr.contains('成功') || 
                  !responseStr.toLowerCase().contains('error')) {
                return {'success': true, 'message': [{'msg': responseStr, 'msg_status': true}]};
              }
            }
          } catch (e) {
            // 解析錯誤處理
          }
          
          // 如果無法解析為 JSON，則返回一個包含原始響應的 Map
          return {'raw_response': responseStr, 'success': true};
        } else {
          // 返回一個空的成功響應
          return {'success': true, 'message': [{'msg': '更新成功', 'msg_status': true}]};
        }
      } else {
        return {'error': true, 'message': [{'msg': '請求失敗: ${response.statusCode}', 'msg_status': false}]};
      }
    } catch (e) {
      return {'error': true, 'message': [{'msg': '發生錯誤: ${e.toString()}', 'msg_status': false}]};
    }
  }
  
  // 加入購物車
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
    Map<String, String>? options,
  }) async {
    try {
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('用戶未登入');
      }
      
      // 構建 URL
      final url = '$_baseUrl/gws_appcustomer_cart/add&customer_id=$customerId&api_key=$_apiKey';
      
      // 構建表單數據
      Map<String, dynamic> formData = {
        'product_id': productId,
        'quantity': quantity.toString(),
      };
      
      // 添加選項
      if (options != null && options.isNotEmpty) {
        options.forEach((optionId, valueId) {
          formData['option[$optionId]'] = valueId;
        });
      }
      
      // 發送請求
      final response = await _dio.post(
        url,
        data: FormData.fromMap(formData),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          try {
            return jsonDecode(response.data);
          } catch (e) {
            return {'success': true, 'message': response.data};
          }
        } else {
          return {'success': true};
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('加入購物車失敗: ${e.toString()}');
    }
  }
  
  // 獲取購物車
  Future<Map<String, dynamic>> getCart() async {
    try {
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('用戶未登入');
      }
      
      // 構建 URL 並發送請求
      return _get('gws_appcustomer_cart&customer_id=$customerId');
    } catch (e) {
      throw Exception('獲取購物車失敗: ${e.toString()}');
    }
  }
  
  // 更新購物車中的商品數量
  Future<Map<String, dynamic>> updateCartQuantity(String cartId, int quantity) async {
    try {
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('用戶未登入');
      }
      
      // 構建 URL
      final url = '$_baseUrl/gws_appcustomer_cart/update&customer_id=$customerId&api_key=$_apiKey';
      
      // 構建表單數據
      final formData = FormData.fromMap({
        'cart_id': cartId,
        'quantity': quantity.toString(),
      });
      
      // 發送請求
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          try {
            return jsonDecode(response.data);
          } catch (e) {
            return {'success': true, 'message': response.data};
          }
        } else {
          return {'success': true};
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('更新購物車失敗: ${e.toString()}');
    }
  }
  
  // 從購物車中移除商品
  Future<Map<String, dynamic>> removeFromCart(String cartId) async {
    try {
      // 獲取用戶 ID
      final customerId = await _getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('用戶未登入');
      }
      
      // 構建 URL - 使用正確的 API 路徑
      final url = '$_baseUrl/gws_appcustomer_cart/remove&customer_id=$customerId&cart_id=$cartId&api_key=$_apiKey';
      
      // 發送請求
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          try {
            return jsonDecode(response.data);
          } catch (e) {
            return {'success': true, 'message': response.data};
          }
        } else {
          return {'success': true};
        }
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('從購物車移除商品失敗: ${e.toString()}');
    }
  }
  
  // 獲取客戶訂單列表
  Future<Map<String, dynamic>> getCustomerOrders(String customerId) async {
    try {
      if (customerId.isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      final response = await _get('gws_customer_order', extraParams: {'customer_id': customerId});
      return response;
    } catch (e) {
      throw Exception('獲取訂單列表失敗: ${e.toString()}');
    }
  }
  
  // 獲取訂單詳情
  Future<Map<String, dynamic>> getOrderDetail(String customerId, String orderId) async {
    try {
      if (customerId.isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      if (orderId.isEmpty) {
        throw Exception('訂單ID不能為空');
      }
      
      final response = await _get('gws_appcustomer_order/info', extraParams: {
        'customer_id': customerId,
        'order_id': orderId
      });
      return response;
    } catch (e) {
      throw Exception('獲取訂單詳情失敗: ${e.toString()}');
    }
  }
  
  // 創建訂單
  Future<Map<String, dynamic>> createOrder(String customerId, Map<String, dynamic> orderData) async {
    try {
      if (customerId.isEmpty) {
        throw Exception('用戶ID不能為空');
      }
      
      // 構建 URL
      final url = '$_baseUrl/gws_appcustomer_order/add&customer_id=$customerId&api_key=$_apiKey';
      
      // 創建 FormData
      final formData = FormData.fromMap(orderData);
      
      // 發送請求
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return response.data;
        } else if (response.data is String) {
          // 嘗試解析字符串響應為 JSON
          final String responseStr = response.data.toString();
          
          if (responseStr.isEmpty) {
            return {'success': true, 'message': [{'msg': '訂單提交成功', 'msg_status': true}]};
          }
          
          try {
            if (responseStr.trim().startsWith('{') || responseStr.trim().startsWith('[')) {
              final jsonData = jsonDecode(responseStr);
              if (jsonData is Map) {
                return Map<String, dynamic>.from(jsonData);
              }
            } else {
              // 檢查是否包含成功信息
              if (responseStr.toLowerCase().contains('success') || 
                  responseStr.contains('成功') || 
                  !responseStr.toLowerCase().contains('error')) {
                return {'success': true, 'message': [{'msg': responseStr, 'msg_status': true}]};
              }
            }
          } catch (e) {
            // 解析錯誤處理
            debugPrint('解析訂單響應錯誤: ${e.toString()}');
          }
          
          // 如果無法解析為 JSON，則返回一個包含原始響應的 Map
          return {'raw_response': responseStr, 'success': true};
        } else if (response.data == null) {
          // 空響應，視為成功
          return {'success': true, 'message': [{'msg': '訂單提交成功', 'msg_status': true}]};
        } else {
          // 返回一個空的成功響應
          return {'success': true};
        }
      } else {
        return {'error': true, 'message': [{'msg': '請求失敗: ${response.statusCode}', 'msg_status': false}]};
      }
    } catch (e) {
      return {'error': true, 'message': [{'msg': '訂單提交失敗: ${e.toString()}', 'msg_status': false}]};
    }
  }
} 