import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'address_edit_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _addressList = [];
  
  @override
  void initState() {
    super.initState();
    _fetchAddressList();
  }
  
  // 獲取地址列表
  Future<void> _fetchAddressList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // 獲取用戶ID
      final userService = Provider.of<UserService>(context, listen: false);
      final userData = await userService.getUserData();
      final customerId = userData['customer_id'];
      
      if (customerId == null || customerId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '用戶未登入';
        });
        return;
      }
      
      // 獲取地址列表
      final response = await _apiService.getCustomerAddressList(customerId);
      
      setState(() {
        _isLoading = false;
        
        if (response.containsKey('customer_address') && 
            response['customer_address'] is List) {
          _addressList = List<Map<String, dynamic>>.from(response['customer_address']);
        } else {
          _errorMessage = '無法獲取地址列表';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取地址列表失敗: ${e.toString()}';
      });
    }
  }
  
  // 設置默認地址
  Future<void> _setDefaultAddress(String addressId) async {
    try {
      // 獲取用戶ID
      final userService = Provider.of<UserService>(context, listen: false);
      final userData = await userService.getUserData();
      final customerId = userData['customer_id'];
      
      if (customerId == null || customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用戶未登入')),
        );
        return;
      }
      
      // 更新地址數據
      final addressData = {
        'customer_id': customerId,
        'default': '1',
      };
      
      // 調用 API 更新地址
      await _apiService.editCustomerAddress(addressId, addressData);
      
      // 重新獲取地址列表
      await _fetchAddressList();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已設為默認地址')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設置默認地址失敗: ${e.toString()}')),
      );
    }
  }
  
  // 刪除地址
  Future<void> _deleteAddress(String addressId) async {
    try {
      // 獲取用戶ID
      final userService = Provider.of<UserService>(context, listen: false);
      final userData = await userService.getUserData();
      final customerId = userData['customer_id'];
      
      if (customerId == null || customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用戶未登入')),
        );
        return;
      }
      
      // 調用 API 刪除地址
      await _apiService.deleteCustomerAddress(customerId, addressId);
      
      // 重新獲取地址列表
      await _fetchAddressList();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('地址已刪除')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除地址失敗: ${e.toString()}')),
      );
    }
  }
  
  // 新增地址
  Future<void> _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressEditPage(),
      ),
    );
    
    if (result == true) {
      _fetchAddressList();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收貨地址'),
        actions: [
          // 新增地址按鈕放在右上角，改為文字按鈕
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                '新增',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _addNewAddress,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAddressList,
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                )
              : _addressList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('您還沒有添加收貨地址'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addNewAddress,
                            child: const Text('添加地址'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAddressList,
                      child: ListView.separated(
                        itemCount: _addressList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final address = _addressList[index];
                          final isDefault = address['default'] == true || address['default'] == '1';
                          
                          // 構建完整地址
                          final fullName = '${address['firstname']} ${address['lastname']}'.trim();
                          final fullAddress = '${address['zone_id'] != null ? _getZoneName(address['zone_id']) : ''} ${address['address_1']} ${address['address_2'] ?? ''}'.trim();
                          
                          return Dismissible(
                            key: Key(address['address_id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16.0),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('確認刪除'),
                                    content: const Text('確定要刪除這個地址嗎？'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('刪除'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              _deleteAddress(address['address_id'].toString());
                            },
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.purple,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '默認',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(fullAddress),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddressEditPage(
                                            addressId: address['address_id'].toString(),
                                          ),
                                        ),
                                      );
                                      
                                      if (result == true) {
                                        _fetchAddressList();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
  
  // 根據區域ID獲取區域名稱
  String _getZoneName(String zoneId) {
    // 台灣區域對照表
    const Map<String, String> zoneMap = {
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
} 