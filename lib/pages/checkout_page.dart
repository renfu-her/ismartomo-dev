import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert'; // 添加 dart:convert 導入
import 'dart:io'; // 添加 dart:io 導入
import 'package:path_provider/path_provider.dart'; // 添加 path_provider 導入
import 'package:permission_handler/permission_handler.dart'; // 添加 permission_handler 導入

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 客戶數據
  Map<String, dynamic> _customerData = {};
  
  // 地址數據
  Map<String, dynamic> _addressData = {};
  
  // 地址列表
  List<Map<String, dynamic>> _addressList = [];
  
  // 選擇的地址ID
  String? _selectedAddressId;
  
  // 購物車數據
  List<dynamic> _cartItems = [];
  List<dynamic> _totals = [];
  
  // 選擇的付款方式
  String _selectedPaymentMethod = 'bank_transfer';
  
  // 付款方式列表
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': '銀行轉帳',
      'code': 'bank_transfer',
      'description': '請將款項轉帳至指定銀行帳戶',
      'icon': Icons.account_balance,
    },
    {
      'title': '線上刷卡',
      'code': 'ecpaypayment',
      'description': '使用綠界金流進行線上刷卡付款',
      'icon': Icons.credit_card,
    },
  ];
  
  // 固定運費
  final double _shippingFee = 60.0;
  
  // 免運費門檻
  final double _freeShippingThreshold = 1000.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      // 清空之前的數據，確保完全重新讀取
      _customerData = {};
      _addressData = {};
      _addressList = [];
      _selectedAddressId = null;
      _cartItems = [];
      _totals = [];
    });
    
    try {
      // 獲取客戶數據
      final customerResponse = await _apiService.getCustomerProfile();
      
      if (customerResponse.containsKey('customer') && 
          customerResponse['customer'] is List && 
          customerResponse['customer'].isNotEmpty) {
        
        _customerData = customerResponse['customer'][0];
        
        // 獲取用戶的所有地址
        final customerId = _customerData['customer_id']?.toString();
        if (customerId != null) {
          final addressResponse = await _apiService.getCustomerAddressList(customerId);
          
          if (addressResponse.containsKey('customer_address') && 
              addressResponse['customer_address'] is List) {
            
            // 將地址列表轉換為List<Map<String, dynamic>>
            _addressList = List<Map<String, dynamic>>.from(addressResponse['customer_address']);
            
            // 查找默認地址
            final defaultAddress = _addressList.firstWhere(
              (address) => address['default'] == true,
              orElse: () => _addressList.isNotEmpty ? _addressList.first : <String, dynamic>{},
            );
            
            if (defaultAddress.isNotEmpty) {
              _addressData = defaultAddress;
              _selectedAddressId = defaultAddress['address_id']?.toString();
            } else if (_addressList.isNotEmpty) {
              // 如果沒有默認地址但有其他地址，選擇第一個
              _addressData = _addressList.first;
              _selectedAddressId = _addressList.first['address_id']?.toString();
            }
          }
        }
      }
      
      // 獲取購物車數據
      final cartResponse = await _apiService.getCart();
      
      if (cartResponse.containsKey('customer_cart')) {
        _cartItems = cartResponse['customer_cart'] ?? [];
        _totals = cartResponse['totals'] ?? [];
      }
      
      setState(() {
        _isLoading = false;
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
        title: const Text('結帳'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildCheckoutContent(),
    );
  }
  
  Widget _buildCheckoutContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 結帳步驟標題
            const Text(
              '結帳流程',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // 1. 選擇付款方式
            _buildSectionTitle('1. 選擇付款方式'),
            const SizedBox(height: 8),
            _buildPaymentMethodSelection(),
            const SizedBox(height: 24),
            
            // 2. 確認收件地址
            _buildSectionTitle('2. 確認收件地址'),
            const SizedBox(height: 8),
            _buildAddressCard(),
            const SizedBox(height: 24),
            
            // 3. 選擇貨運方式
            _buildSectionTitle('3. 選擇貨運方式'),
            const SizedBox(height: 8),
            _buildShippingMethod(),
            const SizedBox(height: 24),
            
            // 4. 確認訂單內容
            _buildSectionTitle('4. 確認訂單內容'),
            const SizedBox(height: 8),
            _buildOrderSummary(),
            const SizedBox(height: 32),
            
            // 提交訂單按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 提交訂單功能
                  _submitOrder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  '提交訂單',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildPaymentMethodSelection() {
    return Column(
      children: _paymentMethods.map((method) {
        final bool isSelected = _selectedPaymentMethod == method['code'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['code'];
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    method['icon'],
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: method['code'],
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildAddressCard() {
    if (_addressList.isEmpty) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('尚未設置收件地址'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // 如果有多個地址，顯示地址選擇器
    if (_addressList.length > 1) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 地址選擇標題
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    '選擇收件地址',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 使用下拉選單選擇地址
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedAddressId,
                  isExpanded: true,
                  underline: Container(), // 移除下劃線
                  icon: const Icon(Icons.arrow_drop_down),
                  hint: const Text('請選擇收件地址'),
                  items: _addressList.map((address) {
                    final String addressId = address['address_id']?.toString() ?? '';
                    final String fullName = '${address['lastname']} ${address['firstname']}';
                    final String zoneName = _getZoneName(address['zone_id'] ?? '');
                    final String addressText = address['address_1'] ?? '';
                    
                    return DropdownMenuItem<String>(
                      value: addressId,
                      child: Text(
                        '$fullName - $zoneName $addressText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedAddressId = newValue;
                        // 更新選中的地址數據
                        _addressData = _addressList.firstWhere(
                          (address) => address['address_id'] != null && address['address_id'].toString() == newValue,
                          orElse: () => <String, dynamic>{},
                        );
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 顯示選中地址的詳細信息
              if (_selectedAddressId != null) ...[
                _buildSelectedAddressDetails(),
              ],
            ],
          ),
        ),
      );
    }
    
    // 只有一個地址時直接顯示
    return Column(
      children: [
        _buildSelectedAddressDetails(),
      ],
    );
  }
  
  // 顯示選中的地址詳情
  Widget _buildSelectedAddressDetails() {
    // 格式化地址顯示
    final String fullName = '${_addressData['lastname']} ${_addressData['firstname']}';
    final String zoneName = _getZoneName(_addressData['zone_id'] ?? '');
    final String address1 = _addressData['address_1'] ?? '';
    final String pickupStore = _addressData['pickupstore'] ?? '';
    
    // 完整地址格式化
    final String fullAddress = '$zoneName $address1';
    
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '地址: $fullAddress',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (pickupStore.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '取貨門市: $pickupStore',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // 根據 zone_id 獲取縣市名稱
  String _getZoneName(String zoneId) {
    // 台灣縣市對照表
    final Map<String, String> zoneMap = {
      '3135': '基隆市',
      '3136': '臺北市',
      '3137': '新北市',
      '3138': '桃園市',
      '3139': '新竹市',
      '3140': '新竹縣',
      '3141': '苗栗縣',
      '3142': '臺中市',
      '3143': '彰化縣',
      '3144': '南投縣',
      '3145': '雲林縣',
      '3146': '嘉義市',
      '3147': '嘉義縣',
      '3148': '臺南市',
      '3149': '高雄市',
      '3150': '屏東縣',
      '3151': '臺東縣',
      '3152': '花蓮縣',
      '3153': '宜蘭縣',
      '3154': '澎湖縣',
      '3155': '金門縣',
      '3156': '連江縣',
    };
    
    return zoneMap[zoneId] ?? '';
  }
  
  Widget _buildShippingMethod() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.blue),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '標準配送',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3-5 個工作日送達',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'NT\$${_shippingFee.toInt()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderSummary() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 購物車商品列表
            ..._cartItems.map((item) => _buildCartItem(item)).toList(),
            
            const Divider(height: 32),
            
            // 訂單總計
            ..._totals.map((total) {
              final bool isTotal = total['code'] == 'total';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      total['title'] ?? '',
                      style: TextStyle(
                        fontSize: isTotal ? 16 : 14,
                        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      total['text'] ?? '',
                      style: TextStyle(
                        fontSize: isTotal ? 18 : 14,
                        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                        color: isTotal ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            // 運費
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('運費'),
                  _calculateShippingFee() > 0
                    ? Text('NT\$${_calculateShippingFee().toInt()}')
                    : const Text('免運費', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
            
            const Divider(height: 24),
            
            // 最終總計
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '訂單總計',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _calculateFinalTotal(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCartItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品圖片
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image.network(
                item['thumb'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品名稱
                Text(
                  item['name'] ?? '未知商品',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // 價格和數量
                Row(
                  children: [
                    Text(
                      '${item['price'] ?? ''} × ${item['quantity'] ?? '1'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 小計
          Text(
            item['total'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculateShippingFee() {
    // 計算商品小計
    double subTotal = 0.0;
    for (var item in _cartItems) {
      String totalStr = item['total'] ?? '';
      totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
      double total = double.tryParse(totalStr) ?? 0.0;
      subTotal += total;
    }
    
    // 如果商品小計大於等於免運費門檻，則免運費
    if (subTotal >= _freeShippingThreshold) {
      return 0.0;
    }
    
    // 否則返回固定運費 60
    return 60.0;
  }
  
  String _calculateFinalTotal() {
    // 計算商品小計
    double subTotal = 0.0;
    for (var item in _cartItems) {
      String totalStr = item['total'] ?? '';
      totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
      double total = double.tryParse(totalStr) ?? 0.0;
      subTotal += total;
    }
    
    // 計算運費
    final double shippingFee = _calculateShippingFee();
    
    // 加上運費
    final double finalTotal = subTotal + shippingFee;
    
    return 'NT\$${finalTotal.toInt()}';
  }
  
  // 提交訂單
  Future<void> _submitOrder() async {
    // 檢查地址是否存在
    if (_addressData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先設置收件地址')),
      );
      return;
    }
    
    // 顯示確認對話框
    bool confirmOrder = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認訂單'),
          content: const Text('確定要提交此訂單嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('確定'),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (!confirmOrder) {
      return;
    }
    
    // 顯示加載指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    
    try {
      // 構建訂單數據
      final Map<String, dynamic> orderData = await _buildOrderData();
      
      // 獲取用戶 ID
      final customerId = _customerData['customer_id']?.toString();
      if (customerId == null || customerId.isEmpty) {
        throw Exception('無法獲取用戶 ID');
      }
      
      // 發送 API 請求
      final response = await _apiService.createOrder(customerId, orderData);
      
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 檢查響應
      if (response.containsKey('success') && response['success'] == true) {
        // 顯示成功對話框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('訂單提交成功'),
              content: const Text('您的訂單已成功提交，我們將盡快處理您的訂單。'),
              actions: [
                TextButton(
                  onPressed: () {
                    // 關閉對話框
                    Navigator.of(context).pop();
                    // 返回首頁
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      } else {
        // 顯示錯誤信息
        String errorMessage = '訂單提交失敗';
        
        // 獲取狀態碼
        String statusCode = '';
        if (response.containsKey('status_code')) {
          statusCode = '狀態碼: ${response['status_code']}';
        }
        
        // 獲取響應數據
        String responseData = '';
        if (response.containsKey('response_data')) {
          responseData = '響應數據: ${response['response_data']}';
        }
        
        // 獲取錯誤消息
        if (response.containsKey('message') && response['message'] is List && response['message'].isNotEmpty) {
          errorMessage = response['message'][0]['msg'] ?? errorMessage;
        }
        
        // 構建完整錯誤信息
        String fullErrorMessage = errorMessage;
        if (statusCode.isNotEmpty) {
          fullErrorMessage += '\n$statusCode';
        }
        if (responseData.isNotEmpty) {
          fullErrorMessage += '\n$responseData';
        }
        
        // 顯示詳細錯誤對話框
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('訂單提交失敗'),
              content: SingleChildScrollView(
                child: Text(fullErrorMessage),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 顯示錯誤信息
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('訂單提交失敗'),
            content: SingleChildScrollView(
              child: Text('發生錯誤: ${e.toString()}'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('確定'),
              ),
            ],
          );
        },
      );
    }
  }
  
  // 構建訂單數據
  Future<Map<String, dynamic>> _buildOrderData() async {
    final Map<String, dynamic> orderData = {};
    
    // 客戶信息
    orderData['customer[customer_id]'] = _customerData['customer_id']?.toString() ?? '';
    orderData['customer[customer_group_id]'] = _customerData['customer_group_id']?.toString() ?? '1';
    orderData['customer[firstname]'] = _customerData['firstname'] ?? '';
    orderData['customer[lastname]'] = _customerData['lastname'] ?? '';
    orderData['customer[email]'] = _customerData['email'] ?? '';
    orderData['customer[telephone]'] = _customerData['telephone'] ?? '';
    orderData['customer[fax]'] = _customerData['fax'] ?? '';
    orderData['customer[custom_field]'] = _customerData['custom_field'] ?? '[]';
    
    // 付款地址
    orderData['payment_address[firstname]'] = _addressData['firstname'] ?? '';
    orderData['payment_address[lastname]'] = _addressData['lastname'] ?? '';
    orderData['payment_address[company]'] = _addressData['company'] ?? '';
    orderData['payment_address[address_1]'] = _addressData['address_1'] ?? '';
    orderData['payment_address[address_2]'] = _addressData['address_2'] ?? '';
    orderData['payment_address[city]'] = _addressData['city'] ?? '';
    orderData['payment_address[postcode]'] = _addressData['postcode'] ?? '';
    orderData['payment_address[zone]'] = _getZoneName(_addressData['zone_id'] ?? ''); // 確保設置區域名稱
    orderData['payment_address[zone_id]'] = _addressData['zone_id']?.toString() ?? '';
    orderData['payment_address[country]'] = '台灣'; // 設置國家名稱
    orderData['payment_address[country_id]'] = '206'; // 台灣的國家ID
    orderData['payment_address[address_format]'] = '';
    orderData['payment_address[custom_field][1]'] = _addressData['custom_field'] != null && _addressData['custom_field'] is Map ? _addressData['custom_field']['1'] ?? '711' : '711';
    
    // 額外的地址欄位（可能不是標準欄位，但您的系統需要）
    orderData['payment_address[cellphone]'] = _addressData['cellphone'] ?? '';
    orderData['payment_address[pickupstore]'] = _addressData['pickupstore'] ?? '';
    
    // 付款方式
    final paymentMethod = _paymentMethods.firstWhere(
      (method) => method['code'] == _selectedPaymentMethod,
      orElse: () => _paymentMethods.first,
    );
    
    orderData['payment_method[title]'] = paymentMethod['title'] ?? '';
    orderData['payment_method[code]'] = paymentMethod['code'] ?? '';
    
    // 配送地址（與付款地址相同）
    orderData['shipping_address[firstname]'] = _addressData['firstname'] ?? '';
    orderData['shipping_address[lastname]'] = _addressData['lastname'] ?? '';
    orderData['shipping_address[company]'] = _addressData['company'] ?? '';
    orderData['shipping_address[address_1]'] = _addressData['address_1'] ?? '';
    orderData['shipping_address[address_2]'] = _addressData['address_2'] ?? '';
    orderData['shipping_address[city]'] = _addressData['city'] ?? '';
    orderData['shipping_address[postcode]'] = _addressData['postcode'] ?? '';
    orderData['shipping_address[zone]'] = _getZoneName(_addressData['zone_id'] ?? ''); // 確保設置區域名稱
    orderData['shipping_address[zone_id]'] = _addressData['zone_id']?.toString() ?? '';
    orderData['shipping_address[country]'] = '台灣'; // 設置國家名稱
    orderData['shipping_address[country_id]'] = '206'; // 台灣的國家ID
    orderData['shipping_address[address_format]'] = '';
    orderData['shipping_address[custom_field][1]'] = _addressData['custom_field'] != null && _addressData['custom_field'] is Map ? _addressData['custom_field']['1'] ?? '711' : '711';
    
    // 額外的地址欄位（可能不是標準欄位，但您的系統需要）
    orderData['shipping_address[cellphone]'] = _addressData['cellphone'] ?? '';
    orderData['shipping_address[pickupstore]'] = _addressData['pickupstore'] ?? '';
    
    // 配送方式
    final shippingFee = _calculateShippingFee();
    orderData['shipping_method[title]'] = shippingFee > 0 ? '一般運費' : '免運費';
    orderData['shipping_method[code]'] = shippingFee > 0 ? 'shipping.flat' : 'shipping.free';
    
    // 商品信息
    for (int i = 0; i < _cartItems.length; i++) {
      final item = _cartItems[i];
      
      // 提取價格中的數字
      String priceStr = item['price'] ?? '';
      priceStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
      double price = double.tryParse(priceStr) ?? 0.0;
      
      // 提取總價中的數字
      String totalStr = item['total'] ?? '';
      totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
      double total = double.tryParse(totalStr) ?? 0.0;
      
      orderData['products[$i][product_id]'] = item['product_id']?.toString() ?? '';
      orderData['products[$i][name]'] = item['name'] ?? '';
      orderData['products[$i][model]'] = item['model'] ?? '';
      orderData['products[$i][quantity]'] = item['quantity']?.toString() ?? '1';
      orderData['products[$i][price]'] = price.toString();
      orderData['products[$i][total]'] = total.toString();
      orderData['products[$i][tax_class_id]'] = '0'; // 不使用稅金
      orderData['products[$i][download]'] = ''; // 添加下載欄位
      orderData['products[$i][subtract]'] = '1';
      orderData['products[$i][reward]'] = '0'; // 添加獎勵點數欄位
      
      // 處理商品選項
      if (item.containsKey('option') && item['option'] is List) {
        final options = item['option'];
        for (int j = 0; j < options.length; j++) {
          final option = options[j];
          orderData['products[$i][option][$j][product_option_id]'] = option['product_option_id']?.toString() ?? '';
          orderData['products[$i][option][$j][product_option_value_id]'] = option['product_option_value_id']?.toString() ?? '';
          orderData['products[$i][option][$j][name]'] = option['name'] ?? '';
          orderData['products[$i][option][$j][value]'] = option['value'] ?? '';
          orderData['products[$i][option][$j][type]'] = option['type'] ?? '';
        }
      }
    }
    
    // 計算商品小計（不含運費）
    double subTotal = 0.0;
    for (var item in _cartItems) {
      String totalStr = item['total'] ?? '';
      totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
      double total = double.tryParse(totalStr) ?? 0.0;
      subTotal += total;
    }
    
    // 計算運費
    final double shippingFeeValue = _calculateShippingFee();
    
    // 計算最終總金額（商品小計 + 運費）
    final double finalTotal = subTotal + shippingFeeValue;
    
    // 設置訂單總金額
    orderData['total'] = finalTotal.toString();
    
    // 重新構建訂單摘要，只包含小計、運費和總計
    // 1. 小計
    orderData['totals[0][code]'] = 'sub_total';
    orderData['totals[0][title]'] = '小計';
    orderData['totals[0][value]'] = subTotal.toString();
    orderData['totals[0][sort_order]'] = '1';
    
    // 2. 運費
    orderData['totals[1][code]'] = 'shipping';
    orderData['totals[1][title]'] = shippingFeeValue > 0 ? '一般運費' : '免運費';
    orderData['totals[1][value]'] = shippingFeeValue.toString();
    orderData['totals[1][sort_order]'] = '2';
    
    // 3. 總計
    orderData['totals[2][code]'] = 'total';
    orderData['totals[2][title]'] = '總計';
    orderData['totals[2][value]'] = finalTotal.toString();
    orderData['totals[2][sort_order]'] = '3';
    
    // 將完整的 orderData 輸出到調試控制台和日誌文件
    debugPrint('==================== 訂單數據開始 ====================');
    
    // 創建日誌內容
    StringBuffer logContent = StringBuffer();
    logContent.writeln('==================== 訂單數據開始 ====================');
    
    // 以簡潔的格式輸出所有欄位和值
    try {
      // 輸出訂單數據的總數
      debugPrint('訂單數據總數: ${orderData.length} 個鍵值對');
      logContent.writeln('訂單數據總數: ${orderData.length} 個鍵值對');
      logContent.writeln('');
      
      // 按照類別分組輸出所有欄位
      debugPrint('【客戶信息】');
      logContent.writeln('【客戶信息】');
      orderData.keys.where((key) => key.startsWith('customer[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【付款地址】');
      logContent.writeln('【付款地址】');
      orderData.keys.where((key) => key.startsWith('payment_address[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【配送地址】');
      logContent.writeln('【配送地址】');
      orderData.keys.where((key) => key.startsWith('shipping_address[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【付款方式】');
      logContent.writeln('【付款方式】');
      orderData.keys.where((key) => key.startsWith('payment_method[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【配送方式】');
      logContent.writeln('【配送方式】');
      orderData.keys.where((key) => key.startsWith('shipping_method[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【商品信息】');
      logContent.writeln('【商品信息】');
      orderData.keys.where((key) => key.startsWith('products[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【訂單總計】');
      logContent.writeln('【訂單總計】');
      orderData.keys.where((key) => key.startsWith('totals[')).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      debugPrint('');
      logContent.writeln('');
      
      debugPrint('【其他參數】');
      logContent.writeln('【其他參數】');
      orderData.keys.where((key) => 
        !key.startsWith('customer[') && 
        !key.startsWith('payment_address[') && 
        !key.startsWith('shipping_address[') && 
        !key.startsWith('payment_method[') && 
        !key.startsWith('shipping_method[') && 
        !key.startsWith('products[') && 
        !key.startsWith('totals[')
      ).forEach((key) {
        debugPrint('$key = ${orderData[key]}');
        logContent.writeln('$key = ${orderData[key]}');
      });
      
      // 將完整的 JSON 數據添加到日誌
      logContent.writeln('');
      logContent.writeln('【完整 JSON 數據】');
      final JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(orderData);
      logContent.writeln(prettyJson);
      
    } catch (e) {
      final errorMsg = '輸出訂單數據時發生錯誤: ${e.toString()}';
      debugPrint(errorMsg);
      logContent.writeln(errorMsg);
    }
    
    debugPrint('==================== 訂單數據結束 ====================');
    logContent.writeln('==================== 訂單數據結束 ====================');
    
    // 將日誌內容寫入文件
    try {
      // 請求存儲權限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('存儲權限被拒絕');
      }
      
      // 獲取外部存儲目錄
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('無法獲取外部存儲目錄');
      }
      
      // 創建日誌目錄
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // 創建帶時間戳的日誌文件名
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final file = File('${logDir.path}/order_$timestamp.log');
      
      // 寫入日誌文件
      await file.writeAsString(logContent.toString());
      
      // 同時寫入一個固定名稱的最新日誌文件
      final latestFile = File('${logDir.path}/order_latest.log');
      await latestFile.writeAsString(logContent.toString());
      
      debugPrint('訂單數據已寫入日誌文件: ${file.path}');
      debugPrint('最新訂單數據也已寫入: ${latestFile.path}');
      
      // 顯示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('訂單數據已寫入日誌文件'),
          action: SnackBarAction(
            label: '查看位置',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('日誌文件位置: ${logDir.path}')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('寫入日誌文件時發生錯誤: ${e.toString()}');
      
      // 如果外部存儲不可用，嘗試使用應用文檔目錄
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/order.log');
        await file.writeAsString(logContent.toString(), mode: FileMode.append);
        debugPrint('訂單數據已寫入備用日誌文件: ${file.path}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('訂單數據已寫入備用日誌文件: ${file.path}')),
        );
      } catch (e2) {
        debugPrint('寫入備用日誌文件時也發生錯誤: ${e2.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法寫入日誌文件，請檢查應用權限')),
        );
      }
    }
    
    return orderData;
  }
} 