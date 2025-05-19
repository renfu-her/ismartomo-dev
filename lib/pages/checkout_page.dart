import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ecpay_service.dart';
import 'dart:convert';
import 'address_list_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ApiService _apiService = ApiService();
  final EcpayService _ecpayService = EcpayService();
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

  // 新增折價券相關變數
  List<Map<String, dynamic>> _coupons = [];
  Map<String, dynamic>? _selectedCoupon;
  TextEditingController _couponController = TextEditingController();
  bool _isLoadingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // 輔助方法：將HTML實體轉換為實際字符
  String _decodeHtmlEntities(String text) {
    if (text.isEmpty) {
      return '';
    }
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'");
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initEcpaySettings();
    _fetchCoupons();
  }
  
  // 初始化綠界支付設置
  Future<void> _initEcpaySettings() async {
    try {
      await _ecpayService.initEcpaySettings();
    } catch (e) {
      debugPrint('初始化綠界支付設置錯誤: ${e.toString()}');
    }
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
  
  // 獲取折價券列表
  Future<void> _fetchCoupons() async {
    try {
      final response = await _apiService.getCoupons();
      if (response.containsKey('coupons') && response['coupons'] is List) {
        setState(() {
          _coupons = List<Map<String, dynamic>>.from(response['coupons']);
        });
      }
    } catch (e) {
      debugPrint('獲取折價券失敗: ${e.toString()}');
    }
  }
  
  // 驗證折價券
  void _validateCoupon(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入折價券代碼')),
      );
      return;
    }

    setState(() {
      _isLoadingCoupon = true;
    });

    try {
      // 獲取折價券列表
      final response = await _apiService.getCoupons();
      
      if (response.containsKey('coupons') && response['coupons'] is List) {
        final coupons = List<Map<String, dynamic>>.from(response['coupons']);
        
        // 在折價券列表中查找匹配的折價券
        final now = DateTime.now();
        final coupon = coupons.firstWhere(
          (coupon) {
            final dateStart = DateTime.parse(coupon['date_start']);
            final dateEnd = DateTime.parse(coupon['date_end']);
            return coupon['code'] == code &&
                   coupon['status'] == 'Enabled' &&
                   now.isAfter(dateStart) &&
                   now.isBefore(dateEnd);
          },
          orElse: () => <String, dynamic>{},
        );

        if (coupon.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無效的折價券代碼或已過期')),
          );
          setState(() {
            _isLoadingCoupon = false;
            _selectedCoupon = null;
          });
          return;
        }

        // 檢查訂單金額是否達到折價券使用門檻
        double orderTotal = _calculateSubTotal();
        final couponMinTotal = double.tryParse(coupon['total'] ?? '0') ?? 0.0;
        
        if (orderTotal < couponMinTotal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('訂單金額需滿 NT\$${couponMinTotal.toInt()} 才能使用此折價券')),
          );
          setState(() {
            _isLoadingCoupon = false;
            _selectedCoupon = null;
          });
          return;
        }

        setState(() {
          _isLoadingCoupon = false;
          _selectedCoupon = coupon;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('折價券已套用')),
        );
      } else {
        throw Exception('無法獲取折價券資料');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('驗證折價券時發生錯誤: ${e.toString()}')),
      );
      setState(() {
        _isLoadingCoupon = false;
        _selectedCoupon = null;
      });
    }
  }
  
  // 計算折扣金額
  double _calculateDiscount() {
    if (_selectedCoupon == null) return 0.0;

    double orderTotal = 0.0;
    for (var item in _cartItems) {
      String totalStr = item['total'] ?? '';
      totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
      double total = double.tryParse(totalStr) ?? 0.0;
      orderTotal += total;
    }

    final type = _selectedCoupon!['type'];
    final discount = double.tryParse(_selectedCoupon!['discount'] ?? '0') ?? 0.0;

    if (type == 'F') {
      // 固定金額折扣
      return discount;
    } else if (type == 'P') {
      // 百分比折扣
      return (orderTotal * discount / 100);
    }

    return 0.0;
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
            Row(
              children: [
                Expanded(
                  child: _buildAddressCard(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 3. 確認訂單內容
            _buildSectionTitle('3. 確認訂單內容'),
            const SizedBox(height: 8),
            _buildOrderSummary(),
            const SizedBox(height: 32),
            
            // 底部提交訂單按鈕
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.black),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          _isLoading ? '處理中...' : '確認訂購',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
              child: Column(
                children: [
                  Row(
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
                  
                  // 如果選擇了銀行轉帳，顯示查看銀行資訊按鈕
                  if (isSelected && method['code'] == 'bank_transfer') ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 導航到銀行轉帳信息頁面
                          Navigator.of(context).pushNamed('/bank_transfer_info');
                        },
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('查看銀行轉帳資訊'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.blue[200]!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // 地址操作按鈕（新增、重新整理）
  Widget _buildAddressActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('重新整理'),
          onPressed: () {
            _fetchData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('正在重新整理地址資料...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('新增'),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddressListPage(),
              ),
            );
            if (result == true) {
              _fetchData();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
          ),
        ),
      ],
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
              const SizedBox(height: 8),
              _buildAddressActionButtons(),
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
                  const Expanded(
                    child: Text(
                      '選擇收件地址',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildAddressActionButtons(),
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
                  menuMaxHeight: 400, // 添加這行，設置下拉選單的最大高度
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
    
    // 只有一個地址時直接顯示，並加上操作按鈕
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
            _buildAddressActionButtons(),
            const SizedBox(height: 8),
            _buildSelectedAddressDetails(),
          ],
        ),
      ),
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
            
            // 折價券輸入區域
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用折價券',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: const InputDecoration(
                            hintText: '請輸入折價券代碼',
                            isDense: true,
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoadingCoupon
                            ? null
                            : () => _validateCoupon(_couponController.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoadingCoupon
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('套用'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 顯示已套用的折價券
            if (_selectedCoupon != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '折價券: ${_selectedCoupon!['name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Text(
                    '-NT\$${_calculateDiscount().toInt()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            
            // 商品合計
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '商品合計',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  'NT\$${_calculateSubTotal().toInt()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),

            // 檢查是否有折價券
            if (_totals.any((total) => total['code'] == 'coupon')) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _totals.firstWhere((total) => total['code'] == 'coupon')['title'] ?? '折價券',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    _totals.firstWhere((total) => total['code'] == 'coupon')['text'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            
            // 運費
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '運費',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  _calculateShippingFee() > 0 ? 'NT\$${_calculateShippingFee().toInt()}' : '免運費',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: _calculateShippingFee() > 0 ? Colors.black : Colors.green,
                  ),
                ),
              ],
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
    // 解析選項
    List<Map<String, String>> options = [];
    
    // 只使用 optiondata 欄位，忽略 option 欄位
    if (item.containsKey('optiondata') && item['optiondata'] is List) {
      final List<dynamic> optionDataList = item['optiondata'];
      
      for (var option in optionDataList) {
        if (option is Map && option.containsKey('name') && option.containsKey('value')) {
          options.add({
            'name': _decodeHtmlEntities(option['name'] ?? ''),
            'value': _decodeHtmlEntities(option['value'] ?? '')
          });
        }
      }
    }
    // 移除對 option 欄位的處理
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品圖片 - 調整為與購物車頁面一致的大小
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 80, // 從 60 改為 80
              height: 80, // 從 60 改為 80
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
                // 商品名稱 - 調整字體大小
                Text(
                  _decodeHtmlEntities(item['name'] ?? '未知商品'),
                  style: const TextStyle(
                    fontSize: 18, // 從 14 改為 18
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // 產品ID (設置為白色，實際上是隱藏) - 與購物車頁面一致
                Text(
                  'ID: ${item['product_id']}',
                  style: const TextStyle(
                    fontSize: 1,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 產品選項 - 使用與購物車頁面一致的顯示方式
                if (options.isNotEmpty) ...[
                  ...options.map((option) => Container(
                    margin: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${option['name']}: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            option['value'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  
                  // 如果有選項，添加一個分隔線
                  Divider(color: Colors.grey[200], height: 16),
                ],
                
                // 價格和數量 - 調整為與購物車頁面類似的顯示方式
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '單價: ${item['price'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '數量: ${item['quantity'] ?? '1'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // 小計
                    Text(
                      item['total'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
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
  
  double _calculateSubTotal() {
    double subTotal = 0.0;
    for (var item in _cartItems) {
      String totalStr = item['total'] ?? '';
      totalStr = totalStr.replaceAll(RegExp(r'[^\d.]'), '');
      double total = double.tryParse(totalStr) ?? 0.0;
      subTotal += total;
    }
    return subTotal;
  }
  
  String _calculateFinalTotal() {
    final subTotal = _calculateSubTotal();
    final shippingFee = _calculateShippingFee();
    final discount = _calculateDiscount();
    
    final finalTotal = subTotal + shippingFee - discount;
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
      if (response.containsKey('message') && 
          response['message'] is List && 
          response['message'].isNotEmpty &&
          response['message'][0].containsKey('msg_status') &&
          response['message'][0]['msg_status'] == true) {
        
        // 清空購物車
        try {
          await _apiService.clearCart(customerId);
        } catch (e) {
          debugPrint('清空購物車失敗: ${e.toString()}');
        }
        
        // 顯示成功對話框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('訂單提交成功'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('訂單編號: ${response['order']['order_id']}'),
                    const Divider(),
                    Text('商店名稱: ${response['order']['store_name']}'),
                    const SizedBox(height: 8),
                    const Text('客戶資訊:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('姓名: ${response['order']['lastname']} ${response['order']['firstname']}'),
                    Text('電話: ${response['order']['telephone']}'),
                    Text('Email: ${response['order']['email']}'),
                    const Divider(),
                    const Text('收件資訊:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('收件人: ${response['order']['shipping_lastname']} ${response['order']['shipping_firstname']}'),
                    Text('地址: ${response['order']['shipping_zone']} ${response['order']['shipping_address_1']}'),
                    if (response['order']['shipping_pickupstore']?.isNotEmpty ?? false)
                      Text('取貨門市: ${response['order']['shipping_pickupstore']}'),
                    const Divider(),
                    const Text('付款資訊:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('付款方式: ${response['order']['payment_method']}'),
                    Text('訂單狀態: ${response['order']['order_status']}'),
                    const Divider(),
                    const Text('金額資訊:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('訂單總額: NT\$${double.parse(response['order']['total']).toInt()}'),
                    const SizedBox(height: 8),
                    Text('訂單時間: ${response['order']['date_added']}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // 關閉對話框
                    Navigator.of(context).pop();
                    // 返回首頁
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // 顯示訂單成功提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('訂單 ${response['order']['order_id']} 已成功建立'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      } else {
        // 獲取錯誤消息
        String errorMessage = '結帳系統失敗';
        
        if (response.containsKey('message') && 
            response['message'] is List && 
            response['message'].isNotEmpty &&
            response['message'][0].containsKey('msg')) {
          errorMessage = response['message'][0]['msg'].toString();
        }
        
        // 顯示錯誤對話框
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('結帳系統失敗'),
              content: SingleChildScrollView(
                child: Text(errorMessage),
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
            title: const Text('結帳系統失敗'),
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
    
    // 如果是綠界支付，添加額外的支付信息
    if (_selectedPaymentMethod == 'ecpaypayment') {
      orderData['payment_method[ecpay_payment_method]'] = 'Credit';
    }
    
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

      print('商品資訊: $item');
      
      orderData['products[$i][product_id]'] = item['product_id']?.toString() ?? '';
      orderData['products[$i][name]'] = _decodeHtmlEntities(item['name'] ?? '');
      orderData['products[$i][model]'] = item['model'] ?? '';
      orderData['products[$i][quantity]'] = item['quantity']?.toString() ?? '1';
      orderData['products[$i][price]'] = price.toString();
      orderData['products[$i][total]'] = total.toString();
      orderData['products[$i][tax_class_id]'] = '0';
      orderData['products[$i][download]'] = '';
      orderData['products[$i][subtract]'] = '1';
      orderData['products[$i][reward]'] = '0';
      
      // 處理商品選項
      if (item.containsKey('option') && item['option'] is String) {
        try {
          // 解析 option JSON 字符串
          final Map<String, dynamic> optionMap = jsonDecode(item['option']);
          int optionIndex = 0;
          
          // 遍歷 option 映射
          optionMap.forEach((optionId, valueId) {
            // 在 optiondata 中查找對應的詳細信息
            final optionData = item['optiondata']?.firstWhere(
              (data) => data['product_option_id'].toString() == optionId,
              orElse: () => null,
            );
            
            if (optionData != null) {
              orderData['products[$i][option][$optionIndex][product_option_id]'] = optionId;
              orderData['products[$i][option][$optionIndex][product_option_value_id]'] = valueId.toString();
              orderData['products[$i][option][$optionIndex][name]'] = _decodeHtmlEntities(optionData['name'] ?? '');
              orderData['products[$i][option][$optionIndex][value]'] = _decodeHtmlEntities(optionData['value'] ?? '');
              orderData['products[$i][option][$optionIndex][type]'] = optionData['type'] ?? '';
              optionIndex++;
            }
          });
        } catch (e) {
          debugPrint('解析商品選項失敗: ${e.toString()}');
        }
      }
    }

    // 使用 _calculateFinalTotal 計算的金額
    final subTotal = _calculateSubTotal();
    final shippingFee = _calculateShippingFee();
    final discount = _calculateDiscount();
    final finalTotal = subTotal + shippingFee - discount;
    
    // 設置訂單總金額（加上 .0000 格式）
    orderData['total'] = '${finalTotal.toStringAsFixed(4)}';
    
    // 設置運費資訊
    if (shippingFee > 0) {
      orderData['shipping_method[title]'] = '一般運費';
      orderData['shipping_method[code]'] = 'shipping.regular';
    } else {
      orderData['shipping_method[title]'] = '免運費';
      orderData['shipping_method[code]'] = 'shipping.free';
    }
    
    // 構建訂單摘要
    int totalIndex = 0;
    
    // 1. 商品合計
    orderData['totals[$totalIndex][code]'] = 'sub_total';
    orderData['totals[$totalIndex][title]'] = '商品合計';
    orderData['totals[$totalIndex][value]'] = subTotal.toString();
    orderData['totals[$totalIndex][sort_order]'] = '${totalIndex + 1}';
    totalIndex++;
    
    // 2. 折價券（如果有）
    if (discount > 0) {
      orderData['totals[$totalIndex][code]'] = 'coupon';
      orderData['totals[$totalIndex][title]'] = '折價券';
      orderData['totals[$totalIndex][value]'] = (-discount).toString(); // 負數表示折扣
      orderData['totals[$totalIndex][sort_order]'] = '${totalIndex + 1}';
      totalIndex++;
    }
    
    // 3. 運費
    orderData['totals[$totalIndex][code]'] = 'shipping';
    orderData['totals[$totalIndex][title]'] = shippingFee > 0 ? '一般運費' : '免運費';
    orderData['totals[$totalIndex][value]'] = shippingFee.toString();
    orderData['totals[$totalIndex][sort_order]'] = '${totalIndex + 1}';
    totalIndex++;
    
    // 4. 總計
    orderData['totals[$totalIndex][code]'] = 'total';
    orderData['totals[$totalIndex][title]'] = '訂單總計';
    orderData['totals[$totalIndex][value]'] = finalTotal.toString();
    orderData['totals[$totalIndex][sort_order]'] = '${totalIndex + 1}';
      
    return orderData;
  }
} 