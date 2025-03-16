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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text('尚未設置收件地址，請先新增地址'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAddAddressDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新增地址'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: () {
                      _showAddAddressDialog();
                    },
                    tooltip: '新增地址',
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showEditAddressDialog(_addressData);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('修改'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _showDeleteAddressConfirmation(_addressData);
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('刪除'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                _showAddAddressDialog();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新增'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _showEditAddressDialog(_addressData);
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('修改'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _showDeleteAddressConfirmation(_addressData);
              },
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('刪除'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // 顯示新增地址對話框
  Future<void> _showAddAddressDialog() async {
    // 獲取區域列表
    List<Map<String, dynamic>> zones = [];
    try {
      final response = await _apiService.getZones('206'); // 台灣的 country_id 是 206
      if (response.containsKey('zones') && response['zones'] is List) {
        zones = List<Map<String, dynamic>>.from(response['zones']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('獲取區域列表失敗: ${e.toString()}')),
      );
      return;
    }
    
    if (zones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法獲取區域列表，請稍後再試')),
      );
      return;
    }
    
    // 初始化控制器
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final cellphoneController = TextEditingController();
    final postcodeController = TextEditingController();
    final cityController = TextEditingController();
    final address1Controller = TextEditingController();
    final address2Controller = TextEditingController();
    
    // 默認選擇台北市
    String selectedZoneId = '3136';
    bool isDefault = false;
    
    // 顯示對話框
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新增地址'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 姓名
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: '姓氏*',
                              hintText: '例：王',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: '名字*',
                              hintText: '例：小明',
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // 手機號碼
                    TextField(
                      controller: cellphoneController,
                      decoration: const InputDecoration(
                        labelText: '手機號碼*',
                        hintText: '例：0912345678',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    // 縣市選擇
                    DropdownButtonFormField<String>(
                      value: selectedZoneId,
                      decoration: const InputDecoration(
                        labelText: '縣市*',
                      ),
                      items: zones.map((zone) {
                        return DropdownMenuItem<String>(
                          value: zone['zone_id'].toString(),
                          child: Text(zone['name']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedZoneId = newValue;
                          });
                        }
                      },
                    ),
                    
                    // 郵遞區號
                    TextField(
                      controller: postcodeController,
                      decoration: const InputDecoration(
                        labelText: '郵遞區號*',
                        hintText: '例：100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    // 鄉鎮市區
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: '鄉鎮市區*',
                        hintText: '例：中正區',
                      ),
                    ),
                    
                    // 地址
                    TextField(
                      controller: address1Controller,
                      decoration: const InputDecoration(
                        labelText: '詳細地址*',
                        hintText: '例：忠孝東路一段100號',
                      ),
                    ),
                    
                    // 地址2（選填）
                    TextField(
                      controller: address2Controller,
                      decoration: const InputDecoration(
                        labelText: '補充地址（選填）',
                        hintText: '例：5樓',
                      ),
                    ),
                    
                    // 設為默認地址
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (bool? value) {
                            setState(() {
                              isDefault = value ?? false;
                            });
                          },
                        ),
                        const Text('設為默認地址'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 驗證必填欄位
                    if (firstNameController.text.trim().isEmpty ||
                        lastNameController.text.trim().isEmpty ||
                        cellphoneController.text.trim().isEmpty ||
                        postcodeController.text.trim().isEmpty ||
                        cityController.text.trim().isEmpty ||
                        address1Controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請填寫所有必填欄位')),
                      );
                      return;
                    }
                    
                    // 關閉對話框
                    Navigator.of(context).pop();
                    
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
                      // 準備地址數據
                      final addressData = {
                        'customer_id': _customerData['customer_id'] != null ? _customerData['customer_id'].toString() : '',
                        'firstname': firstNameController.text.trim(),
                        'lastname': lastNameController.text.trim(),
                        'company': '',
                        'address_1': address1Controller.text.trim(),
                        'address_2': address2Controller.text.trim(),
                        'city': cityController.text.trim(),
                        'postcode': postcodeController.text.trim(),
                        'country_id': '206', // 台灣
                        'zone_id': selectedZoneId,
                        'default': isDefault ? '1' : '0',
                        'custom_field[1]': '711',
                        'cellphone': cellphoneController.text.trim(),
                      };
                      
                      // 調用 API 新增地址
                      final response = await _apiService.addCustomerAddress(addressData);
                      
                      // 關閉加載指示器
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      // 檢查是否成功
                      if (response.containsKey('success') && response['success'] == true) {
                        // 重新獲取地址列表
                        await _fetchData();
                        
                        // 顯示成功消息
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('地址新增成功')),
                        );
                      } else {
                        // 顯示錯誤消息
                        String errorMsg = '地址新增失敗';
                        if (response.containsKey('message') && 
                            response['message'] is List && 
                            response['message'].isNotEmpty) {
                          errorMsg = response['message'][0]['msg'] ?? errorMsg;
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg)),
                        );
                      }
                    } catch (e) {
                      // 關閉加載指示器
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      // 顯示錯誤消息
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('地址新增失敗: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 顯示編輯地址對話框
  Future<void> _showEditAddressDialog(Map<String, dynamic> address) async {
    // 獲取區域列表
    List<Map<String, dynamic>> zones = [];
    try {
      final response = await _apiService.getZones('206'); // 台灣的 country_id 是 206
      if (response.containsKey('zones') && response['zones'] is List) {
        zones = List<Map<String, dynamic>>.from(response['zones']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('獲取區域列表失敗: ${e.toString()}')),
      );
      return;
    }
    
    if (zones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法獲取區域列表，請稍後再試')),
      );
      return;
    }
    
    // 初始化控制器並填充現有數據
    final firstNameController = TextEditingController(text: address['firstname'] ?? '');
    final lastNameController = TextEditingController(text: address['lastname'] ?? '');
    final cellphoneController = TextEditingController(text: address['cellphone'] ?? '');
    final postcodeController = TextEditingController(text: address['postcode'] ?? '');
    final cityController = TextEditingController(text: address['city'] ?? '');
    final address1Controller = TextEditingController(text: address['address_1'] ?? '');
    final address2Controller = TextEditingController(text: address['address_2'] ?? '');
    
    // 獲取當前選擇的區域 ID
    String selectedZoneId = address['zone_id']?.toString() ?? '3136';
    bool isDefault = address['default'] == true;
    
    // 顯示對話框
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('編輯地址'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 姓名
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: '姓氏*',
                              hintText: '例：王',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: '名字*',
                              hintText: '例：小明',
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // 手機號碼
                    TextField(
                      controller: cellphoneController,
                      decoration: const InputDecoration(
                        labelText: '手機號碼*',
                        hintText: '例：0912345678',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    // 縣市選擇
                    DropdownButtonFormField<String>(
                      value: selectedZoneId,
                      decoration: const InputDecoration(
                        labelText: '縣市*',
                      ),
                      items: zones.map((zone) {
                        return DropdownMenuItem<String>(
                          value: zone['zone_id'].toString(),
                          child: Text(zone['name']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedZoneId = newValue;
                          });
                        }
                      },
                    ),
                    
                    // 郵遞區號
                    TextField(
                      controller: postcodeController,
                      decoration: const InputDecoration(
                        labelText: '郵遞區號*',
                        hintText: '例：100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    // 鄉鎮市區
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: '鄉鎮市區*',
                        hintText: '例：中正區',
                      ),
                    ),
                    
                    // 地址
                    TextField(
                      controller: address1Controller,
                      decoration: const InputDecoration(
                        labelText: '詳細地址*',
                        hintText: '例：忠孝東路一段100號',
                      ),
                    ),
                    
                    // 地址2（選填）
                    TextField(
                      controller: address2Controller,
                      decoration: const InputDecoration(
                        labelText: '補充地址（選填）',
                        hintText: '例：5樓',
                      ),
                    ),
                    
                    // 設為默認地址
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (bool? value) {
                            setState(() {
                              isDefault = value ?? false;
                            });
                          },
                        ),
                        const Text('設為默認地址'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 驗證必填欄位
                    if (firstNameController.text.trim().isEmpty ||
                        lastNameController.text.trim().isEmpty ||
                        cellphoneController.text.trim().isEmpty ||
                        postcodeController.text.trim().isEmpty ||
                        cityController.text.trim().isEmpty ||
                        address1Controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請填寫所有必填欄位')),
                      );
                      return;
                    }
                    
                    // 關閉對話框
                    Navigator.of(context).pop();
                    
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
                      // 準備地址數據
                      final addressData = {
                        'customer_id': _customerData['customer_id'] != null ? _customerData['customer_id'].toString() : '',
                        'firstname': firstNameController.text.trim(),
                        'lastname': lastNameController.text.trim(),
                        'company': '',
                        'address_1': address1Controller.text.trim(),
                        'address_2': address2Controller.text.trim(),
                        'city': cityController.text.trim(),
                        'postcode': postcodeController.text.trim(),
                        'country_id': '206', // 台灣
                        'zone_id': selectedZoneId,
                        'default': isDefault ? '1' : '0',
                        'custom_field[1]': '711',
                        'cellphone': cellphoneController.text.trim(),
                      };
                      
                      // 調用 API 修改地址
                      final response = await _apiService.editCustomerAddress(
                        address['address_id'] != null ? address['address_id'].toString() : '',
                        addressData,
                      );
                      
                      // 關閉加載指示器
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      // 檢查是否成功
                      if (response.containsKey('success') && response['success'] == true) {
                        // 重新獲取地址列表
                        await _fetchData();
                        
                        // 顯示成功消息
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('地址修改成功')),
                        );
                      } else {
                        // 顯示錯誤消息
                        String errorMsg = '地址修改失敗';
                        if (response.containsKey('message') && 
                            response['message'] is List && 
                            response['message'].isNotEmpty) {
                          errorMsg = response['message'][0]['msg'] ?? errorMsg;
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMsg)),
                        );
                      }
                    } catch (e) {
                      // 關閉加載指示器
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      // 顯示錯誤消息
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('地址修改失敗: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 顯示刪除地址確認對話框
  Future<void> _showDeleteAddressConfirmation(Map<String, dynamic> address) async {
    // 如果只有一個地址，不允許刪除
    if (_addressList.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要保留一個地址，無法刪除')),
      );
      return;
    }
    
    // 顯示確認對話框
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: const Text('確定要刪除此地址嗎？此操作無法撤銷。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('確定刪除'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (!confirmDelete) {
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
      // 調用 API 刪除地址
      final customerId = _customerData['customer_id'] != null ? _customerData['customer_id'].toString() : '';
      final addressId = address['address_id'] != null ? address['address_id'].toString() : '';
      
      // 顯示調試信息
      debugPrint('刪除地址: customer_id=$customerId, address_id=$addressId');
      
      final response = await _apiService.deleteCustomerAddress(
        customerId,
        addressId,
      );
      
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 檢查是否成功
      if (response.containsKey('success') && response['success'] == true) {
        // 重新獲取地址列表
        await _fetchData();
        
        // 顯示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地址刪除成功')),
        );
      } else {
        // 顯示錯誤消息
        String errorMsg = '地址刪除失敗';
        if (response.containsKey('message') && 
            response['message'] is List && 
            response['message'].isNotEmpty) {
          errorMsg = response['message'][0]['msg'] ?? errorMsg;
        } else if (response.containsKey('error') && response['error'] == true) {
          errorMsg = '刪除失敗，請稍後再試';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 顯示錯誤消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('地址刪除失敗: ${e.toString()}')),
      );
    }
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