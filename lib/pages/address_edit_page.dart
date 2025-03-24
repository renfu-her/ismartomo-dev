import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';

class AddressEditPage extends StatefulWidget {
  final String? addressId;
  
  const AddressEditPage({super.key, this.addressId});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isLoadingAddress = false;
  bool _isDefault = false;
  
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cellphoneController = TextEditingController();
  final TextEditingController _pickupstoreController = TextEditingController();
  
  String _selectedZoneId = '3136'; // 默認為臺北市
  
  // 台灣區域列表
  final List<Map<String, String>> _zones = [
    {'id': '3135', 'name': '基隆市'},
    {'id': '3136', 'name': '臺北市'},
    {'id': '3137', 'name': '新北市'},
    {'id': '3138', 'name': '桃園市'},
    {'id': '3139', 'name': '新竹市'},
    {'id': '3140', 'name': '新竹縣'},
    {'id': '3141', 'name': '苗栗縣'},
    {'id': '3142', 'name': '臺中市'},
    {'id': '3143', 'name': '彰化縣'},
    {'id': '3144', 'name': '南投縣'},
    {'id': '3145', 'name': '雲林縣'},
    {'id': '3146', 'name': '嘉義市'},
    {'id': '3147', 'name': '嘉義縣'},
    {'id': '3148', 'name': '臺南市'},
    {'id': '3149', 'name': '高雄市'},
    {'id': '3150', 'name': '屏東縣'},
    {'id': '3151', 'name': '臺東縣'},
    {'id': '3152', 'name': '花蓮縣'},
    {'id': '3153', 'name': '宜蘭縣'},
    {'id': '3154', 'name': '澎湖縣'},
    {'id': '3155', 'name': '金門縣'},
    {'id': '3156', 'name': '連江縣'},
  ];
  
  @override
  void initState() {
    super.initState();
    
    // 如果是編輯模式，則獲取地址詳情
    if (widget.addressId != null) {
      _fetchAddressDetails();
    }
  }
  
  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cellphoneController.dispose();
    _pickupstoreController.dispose();
    super.dispose();
  }
  
  // 獲取地址詳情
  Future<void> _fetchAddressDetails() async {
    setState(() {
      _isLoadingAddress = true;
    });
    
    try {
      // 獲取用戶ID
      final userService = Provider.of<UserService>(context, listen: false);
      final userData = await userService.getUserData();
      final customerId = userData['customer_id'];
      
      if (customerId == null || customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用戶未登入')),
        );
        Navigator.pop(context);
        return;
      }
      
      // 獲取地址詳情
      final response = await _apiService.getCustomerAddress(widget.addressId!);
      
      if (response.containsKey('customer_address') && 
          response['customer_address'] is List &&
          response['customer_address'].isNotEmpty) {
        
        final address = response['customer_address'][0];
        
        // 填充表單
        _firstnameController.text = address['firstname'] ?? '';
        _lastnameController.text = address['lastname'] ?? '';
        _address1Controller.text = address['address_1'] ?? '';
        _address2Controller.text = address['address_2'] ?? '';
        _cellphoneController.text = address['cellphone'] ?? '';
        _pickupstoreController.text = address['pickupstore'] ?? '';
        
        // 設置區域
        if (address['zone_id'] != null && address['zone_id'].toString().isNotEmpty) {
          _selectedZoneId = address['zone_id'].toString();
        }
        
        // 設置是否為默認地址
        _isDefault = address['default'] == true || address['default'] == '1';
        
        setState(() {
          _isLoadingAddress = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('獲取地址詳情失敗')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('獲取地址詳情失敗: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }
  
  // 保存地址
  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 獲取用戶ID
      final userService = Provider.of<UserService>(context, listen: false);
      final userData = await userService.getUserData();
      final customerId = userData['customer_id'];
      
      if (customerId == null || customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用戶未登入')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 構建地址數據
      final addressData = {
        'customer_id': customerId,
        'firstname': _firstnameController.text,
        'lastname': _lastnameController.text,
        'cellphone': _cellphoneController.text.trim(),
        'company': '',
        'address_1': _address1Controller.text,
        'address_2': _address2Controller.text,
        'city': '',
        'postcode': '',
        'country_id': '206', // 台灣
        'zone_id': _selectedZoneId,
        'default': _isDefault ? '1' : '0',
        'custom_field[1]': _pickupstoreController.text.trim(), // 根據需求設置
        'pickupstore': _pickupstoreController.text.trim(),
      };

      print(addressData);
      
      // 調用 API 保存地址
      if (widget.addressId == null) {
        // 添加新地址
        await _apiService.addCustomerAddress(addressData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地址添加成功')),
        );
      } else {
        // 更新地址
        await _apiService.editCustomerAddress(widget.addressId!, addressData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地址更新成功')),
        );
      }
      
      // 返回上一頁
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存地址失敗: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.addressId == null ? '添加地址' : '編輯地址'),
      ),
      body: _isLoadingAddress
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 姓名區域
                    Row(
                      children: [
                        // 姓氏
                        Expanded(
                          child: TextFormField(
                            controller: _firstnameController,
                            decoration: const InputDecoration(
                              labelText: '姓氏',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '請輸入姓氏';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 名字
                        Expanded(
                          child: TextFormField(
                            controller: _lastnameController,
                            decoration: const InputDecoration(
                              labelText: '名字',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '請輸入名字';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 手機號碼
                    TextFormField(
                      controller: _cellphoneController,
                      decoration: const InputDecoration(
                        labelText: '手機號碼',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入手機號碼';
                        }
                        // 驗證手機號碼格式（台灣手機號碼）
                        if (!RegExp(r'^09\d{8}$').hasMatch(value)) {
                          return '請輸入正確的手機號碼格式';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 超商店到店（選填）
                    TextFormField(
                      controller: _pickupstoreController,
                      decoration: const InputDecoration(
                        labelText: '超商店到店（選填，例:7-ELEVEN 鑫台北門市）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 區域選擇
                    DropdownButtonFormField<String>(
                      value: _selectedZoneId,
                      decoration: const InputDecoration(
                        labelText: '縣市',
                        border: OutlineInputBorder(),
                      ),
                      items: _zones.map((zone) {
                        return DropdownMenuItem<String>(
                          value: zone['id'],
                          child: Text(zone['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedZoneId = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請選擇縣市';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 詳細地址
                    TextFormField(
                      controller: _address1Controller,
                      decoration: const InputDecoration(
                        labelText: '詳細地址',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入詳細地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 補充地址（選填）
                    TextFormField(
                      controller: _address2Controller,
                      decoration: const InputDecoration(
                        labelText: '補充地址（選填）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 設為默認地址
                    SwitchListTile(
                      title: const Text('設為默認地址'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    
                    // 保存按鈕
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 