import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class EcpayService {
  // 單例模式
  static final EcpayService _instance = EcpayService._internal();
  
  factory EcpayService() {
    return _instance;
  }
  
  EcpayService._internal();
  
  // API 服務
  final ApiService _apiService = ApiService();
  
  // 綠界支付設置
  Map<String, dynamic> _ecpaySettings = {};
  
  // 初始化綠界支付設置
  Future<void> initEcpaySettings() async {
    try {
      _ecpaySettings = await _apiService.getEcpaySettings();
      // 添加調試信息
      debugPrint('綠界支付設置: $_ecpaySettings');
    } catch (e) {
      debugPrint('初始化綠界支付設置錯誤: ${e.toString()}');
    }
  }
  
  // 獲取綠界支付設置
  Map<String, dynamic> get ecpaySettings => _ecpaySettings;
  
  // 檢查綠界支付設置是否完整
  bool isEcpaySettingsComplete() {
    final bool isComplete = _ecpaySettings.containsKey('merchant_id') && 
           _ecpaySettings.containsKey('hash_key') && 
           _ecpaySettings.containsKey('hash_iv') &&
           _ecpaySettings['merchant_id'] != null &&
           _ecpaySettings['hash_key'] != null &&
           _ecpaySettings['hash_iv'] != null;
    
    // 添加調試信息
    debugPrint('綠界支付設置是否完整: $isComplete');
    if (!isComplete) {
      debugPrint('缺少的設置: ${!_ecpaySettings.containsKey('merchant_id') ? 'merchant_id, ' : ''}${!_ecpaySettings.containsKey('hash_key') ? 'hash_key, ' : ''}${!_ecpaySettings.containsKey('hash_iv') ? 'hash_iv, ' : ''}');
      debugPrint('設置值: merchant_id=${_ecpaySettings['merchant_id']}, hash_key=${_ecpaySettings['hash_key']}, hash_iv=${_ecpaySettings['hash_iv']}');
    }
    
    return isComplete;
  }
  
  // 生成綠界支付表單
  Future<Map<String, dynamic>> generateEcpayForm({
    required String orderId,
    required String totalAmount,
    required String itemName,
    required String returnUrl,
    required String clientBackUrl,
    required String orderDate,
  }) async {
    if (!isEcpaySettingsComplete()) {
      await initEcpaySettings();
      if (!isEcpaySettingsComplete()) {
        debugPrint('綠界支付設置不完整，使用測試環境默認值');
        // 使用測試環境的默認值
        _ecpaySettings = {
          'merchant_id': '2000132',
          'hash_key': '5294y06JbISpM5x9',
          'hash_iv': 'v77hoKGq4kWxNNIS',
          'payment_methods': 'Credit'
        };
      }
    }
    
    // 確保訂單編號不超過20個字符
    if (orderId.length > 20) {
      orderId = orderId.substring(0, 20);
    }
    
    // 確保商品名稱不超過200個字符
    if (itemName.length > 200) {
      itemName = itemName.substring(0, 197) + '...';
    }
    
    // 綠界支付參數
    final Map<String, String> formData = {
      'MerchantID': _ecpaySettings['merchant_id'],
      'MerchantTradeNo': orderId,
      'MerchantTradeDate': orderDate, // 格式: yyyy/MM/dd HH:mm:ss
      'PaymentType': 'aio',
      'TotalAmount': totalAmount,
      'TradeDesc': Uri.encodeComponent('APP訂單'),
      'ItemName': itemName,
      'ReturnURL': returnUrl,
      'ClientBackURL': clientBackUrl,
      'ChoosePayment': 'Credit',
      'EncryptType': '1',
    };
    
    debugPrint('綠界支付表單數據: $formData');
    
    // 按照參數名稱的字母順序排序
    final List<String> sortedKeys = formData.keys.toList()..sort();
    
    // 構建檢查碼字符串
    String checkString = 'HashKey=${_ecpaySettings['hash_key']}&';
    
    for (String key in sortedKeys) {
      checkString += '$key=${formData[key]}&';
    }
    
    checkString += 'HashIV=${_ecpaySettings['hash_iv']}';
    
    debugPrint('檢查碼字符串: $checkString');
    
    // URL 編碼
    checkString = Uri.encodeFull(checkString).toLowerCase();
    
    debugPrint('URL編碼後的檢查碼字符串: $checkString');
    
    // 計算 SHA256 檢查碼
    final checksum = sha256.convert(utf8.encode(checkString)).toString().toUpperCase();
    
    debugPrint('SHA256 檢查碼: $checksum');
    
    // 添加檢查碼到表單數據
    formData['CheckMacValue'] = checksum;
    
    return {
      'formData': formData,
      'actionUrl': 'https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5', // 測試環境
      // 正式環境: 'https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5'
    };
  }
  
  // 處理綠界支付
  Future<void> processEcpayPayment({
    required BuildContext context,
    required String orderId,
    required String totalAmount,
    required String itemName,
    required Function(bool success, String? message) onPaymentComplete,
  }) async {
    try {
      // 獲取當前日期時間，格式: yyyy/MM/dd HH:mm:ss
      final now = DateTime.now();
      final orderDate = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      // 生成綠界支付表單
      final ecpayForm = await generateEcpayForm(
        orderId: orderId,
        totalAmount: totalAmount,
        itemName: itemName,
        returnUrl: '${_apiService.baseUrl}/ecpay_callback&api_key=${_apiService.apiKey}',
        clientBackUrl: '${_apiService.baseUrl}/ecpay_client_back&api_key=${_apiService.apiKey}&order_id=$orderId',
        orderDate: orderDate,
      );
      
      // 使用臨時表單提交方式
      _showPaymentDialog(context, ecpayForm, onPaymentComplete);
    } catch (e) {
      debugPrint('處理綠界支付失敗: ${e.toString()}');
      onPaymentComplete(false, '處理綠界支付失敗: ${e.toString()}');
    }
  }
  
  // 顯示支付對話框
  void _showPaymentDialog(
    BuildContext context,
    Map<String, dynamic> ecpayForm,
    Function(bool success, String? message) onPaymentComplete
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('綠界支付'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('由於平台限制，無法直接打開支付頁面。'),
                const SizedBox(height: 10),
                const Text('請選擇以下操作：'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showOrderInfo(context, ecpayForm, onPaymentComplete);
                  },
                  child: const Text('查看訂單信息'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _simulatePayment(context, onPaymentComplete);
                  },
                  child: const Text('模擬支付完成（測試用）'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPaymentComplete(false, '用戶取消支付');
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 顯示訂單信息
  void _showOrderInfo(
    BuildContext context,
    Map<String, dynamic> ecpayForm,
    Function(bool success, String? message) onPaymentComplete
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('訂單信息'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('綠界支付測試環境信息：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('網址: https://payment-stage.ecpay.com.tw/'),
                const SizedBox(height: 10),
                const Text('請在綠界網站手動輸入以下信息：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('商店代號: ${ecpayForm['formData']['MerchantID']}'),
                Text('訂單編號: ${ecpayForm['formData']['MerchantTradeNo']}'),
                Text('訂單金額: ${ecpayForm['formData']['TotalAmount']}'),
                Text('訂單日期: ${ecpayForm['formData']['MerchantTradeDate']}'),
                const SizedBox(height: 20),
                const Text('完成支付後請點擊下方按鈕'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _copyOrderInfoToClipboard(ecpayForm);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('訂單信息已複製到剪貼板')),
                );
              },
              child: const Text('複製信息'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPaymentComplete(true, '支付完成');
              },
              child: const Text('支付完成'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPaymentComplete(false, '支付取消');
              },
              child: const Text('取消支付'),
            ),
          ],
        );
      },
    );
  }
  
  // 複製訂單信息到剪貼板
  void _copyOrderInfoToClipboard(Map<String, dynamic> ecpayForm) {
    final formData = ecpayForm['formData'] as Map<String, String>;
    final String orderInfo = '''
綠界支付測試環境信息：
網址: https://payment-stage.ecpay.com.tw/

請在綠界網站手動輸入以下信息：
商店代號: ${formData['MerchantID']}
訂單編號: ${formData['MerchantTradeNo']}
訂單金額: ${formData['TotalAmount']}
訂單日期: ${formData['MerchantTradeDate']}
''';
    
    Clipboard.setData(ClipboardData(text: orderInfo));
    debugPrint('訂單信息已複製到剪貼板');
  }
  
  // 模擬支付完成（僅用於測試）
  void _simulatePayment(
    BuildContext context,
    Function(bool success, String? message) onPaymentComplete
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('模擬支付'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('正在模擬支付過程...'),
              SizedBox(height: 10),
              Text('（此功能僅用於測試環境）'),
            ],
          ),
        );
      },
    );
    
    // 延遲 2 秒後模擬支付完成
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        onPaymentComplete(true, '模擬支付完成');
      }
    });
  }
} 