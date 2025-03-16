import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
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
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.orange),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('尚未設置收件地址，請先在會員中心設置地址'),
              ),
              TextButton(
                onPressed: () {
                  // 導航到會員中心的地址設置頁面
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請前往會員中心設置地址')),
                  );
                },
                child: const Text('會員中心'),
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
                        '$fullName - $zoneName',
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
                          (address) => address['address_id'].toString() == newValue,
                          orElse: () => <String, dynamic>{},
                        );
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 顯示選中地址的詳細信息
              if (_selectedAddressId != null)
                _buildSelectedAddressDetails(),
            ],
          ),
        ),
      );
    }
    
    // 只有一個地址時直接顯示
    return _buildSelectedAddressDetails();
  }
  
  // 顯示選中的地址詳情
  Widget _buildSelectedAddressDetails() {
    // 格式化地址顯示
    final String fullName = '${_addressData['lastname']} ${_addressData['firstname']}';
    final String phone = _addressData['cellphone'] ?? '';
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
              '電話: $phone',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
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
                  Text('NT\$${_shippingFee.toInt()}'),
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
  
  String _calculateFinalTotal() {
    // 查找訂單總計
    double orderTotal = 0.0;
    for (var total in _totals) {
      if (total['code'] == 'total') {
        // 從總計文本中提取數字
        final String totalText = total['text'] ?? '';
        final RegExp regex = RegExp(r'[0-9]+');
        final String numberStr = regex.allMatches(totalText).map((m) => m.group(0)).join();
        
        if (numberStr.isNotEmpty) {
          orderTotal = double.tryParse(numberStr) ?? 0.0;
        }
        break;
      }
    }
    
    // 加上運費
    final double finalTotal = orderTotal + _shippingFee;
    
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
      // 模擬訂單提交過程
      await Future.delayed(const Duration(seconds: 2));
      
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
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
    } catch (e) {
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 顯示錯誤消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('訂單提交失敗: ${e.toString()}')),
      );
    }
  }
} 