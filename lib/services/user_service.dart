import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'api_service.dart';

class UserService extends ChangeNotifier {
  // 單例模式
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  // 登入狀態
  bool _isLoggedIn = false;
  
  // 獲取登入狀態
  bool get isLoggedIn => _isLoggedIn;
  
  UserService._internal() {
    // 初始化時檢查登入狀態
    _initLoginStatus();
  }
  
  // 初始化登入狀態
  Future<void> _initLoginStatus() async {
    try {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('初始化登入狀態錯誤: ${e.toString()}');
      _isLoggedIn = false;
    }
  }
  
  // API 服務
  final ApiService _apiService = ApiService();
  
  // 檢查用戶是否已登入
  Future<bool> checkLoginStatus() async {
    try {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      return _isLoggedIn;
    } catch (e) {
      debugPrint('檢查登入狀態錯誤: ${e.toString()}');
      return false;
    }
  }
  
  // 設置登入狀態
  Future<bool> setLoggedIn(bool value) async {
    try {
      final result = await prefs.setBool('is_logged_in', value);
      if (result) {
        _isLoggedIn = value;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('設置登入狀態錯誤: ${e.toString()}');
      return false;
    }
  }
  
  // 用戶登入
  Future<bool> login(String email, String password) async {
    try {
      // 使用 ApiService 的登入方法
      final loginData = await _apiService.login(email, password);
      
      // 檢查登入是否成功
      if (loginData['login'] != null && 
          loginData['login'] is List && 
          loginData['login'].isNotEmpty && 
          loginData['login'][0]['status'] == true) {
        
        // 獲取用戶資料
        final success = await _fetchUserData(email);
        if (success) {
          _isLoggedIn = true;
          notifyListeners();
        }
        return success;
      } else {
        // 登入失敗
        return false;
      }
    } catch (e) {
      debugPrint('登入錯誤: ${e.toString()}');
      return false;
    }
  }
  
  // 獲取用戶資料
  Future<bool> _fetchUserData(String email) async {
    try {
      // 使用 ApiService 的獲取用戶資料方法
      final userData = await _apiService.getUserData(email);
      
      if (userData['customer'] != null && 
          userData['customer'] is List && 
          userData['customer'].isNotEmpty) {
        
        // 獲取用戶資料
        final customer = userData['customer'][0];
        
        // 儲存用戶資料到本地儲存
        await _saveUserData(
          customer['firstname'],
          customer['lastname'],
          customer['email'],
          customer['default_address_id'],
          customer['customer_id'],
        );
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('獲取用戶資料錯誤: ${e.toString()}');
      return false;
    }
  }
  
  // 儲存用戶資料到本地儲存
  Future<void> _saveUserData(
    String firstname,
    String lastname,
    String email,
    String defaultAddressId,
    String customerId,
  ) async {
    try {
      // 使用全局 SharedPreferences 實例
      await prefs.setString('user_firstname', firstname);
      await prefs.setString('user_lastname', lastname);
      await prefs.setString('user_email', email);
      await prefs.setString('user_default_address_id', defaultAddressId);
      await prefs.setString('user_customer_id', customerId);
      await prefs.setBool('is_logged_in', true);
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      debugPrint('儲存用戶資料錯誤: ${e.toString()}');
    }
  }
  
  // 獲取用戶資料
  Future<Map<String, String>> getUserData() async {
    try {
      return {
        'firstname': prefs.getString('user_firstname') ?? '',
        'lastname': prefs.getString('user_lastname') ?? '',
        'email': prefs.getString('user_email') ?? '',
        'default_address_id': prefs.getString('user_default_address_id') ?? '',
        'customer_id': prefs.getString('user_customer_id') ?? '',
      };
    } catch (e) {
      debugPrint('獲取用戶資料錯誤: ${e.toString()}');
      return {
        'firstname': '用戶',
        'lastname': '',
      };
    }
  }
  
  // 登出功能
  Future<bool> logout() async {
    try {
      // 清除用戶資料
      await prefs.remove('user_firstname');
      await prefs.remove('user_lastname');
      await prefs.remove('user_email');
      await prefs.remove('user_default_address_id');
      await prefs.remove('user_customer_id');
      await prefs.setBool('is_logged_in', false);
      
      _isLoggedIn = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('登出錯誤: ${e.toString()}');
      return false;
    }
  }
} 