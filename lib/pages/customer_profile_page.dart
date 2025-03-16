import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _customerData = {};
  bool _newsletterSubscribed = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 使用 UserService 獲取用戶 ID
      _userData = await _userService.getUserData();
      final customerId = _userData?['customer_id'];

      if (customerId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '無法獲取用戶 ID';
        });
        return;
      }

      // 獲取會員資料
      final response = await _apiService.getCustomerProfile();
      
      setState(() {
        _isLoading = false;
        
        if (response.containsKey('customer') && 
            response['customer'] is List && 
            response['customer'].isNotEmpty) {
          _customerData = response['customer'][0];
          _newsletterSubscribed = _customerData['newsletter'] == '1';
        } else {
          _errorMessage = '無法獲取會員資料';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取會員資料失敗: ${e.toString()}';
      });
    }
  }

  Future<void> _updateNewsletter(bool value) async {
    try {
      // 這裡應該調用 API 更新 newsletter 訂閱狀態
      // 暫時只更新本地狀態
      setState(() {
        _newsletterSubscribed = value;
        _customerData['newsletter'] = value ? '1' : '0';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('電子報訂閱狀態已${value ? '開啟' : '關閉'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失敗: ${e.toString()}')),
      );
    }
  }

  // 顯示編輯姓名的對話框
  void _showEditNameDialog() {
    final TextEditingController firstnameController = TextEditingController(text: _customerData['firstname'] ?? '');
    final TextEditingController lastnameController = TextEditingController(text: _customerData['lastname'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('編輯姓名'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstnameController,
                decoration: const InputDecoration(
                  labelText: '名字',
                  hintText: '請輸入您的名字',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastnameController,
                decoration: const InputDecoration(
                  labelText: '姓氏',
                  hintText: '請輸入您的姓氏',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _updateName(
                  firstnameController.text.trim(),
                  lastnameController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
  
  // 顯示編輯電話的對話框
  void _showEditPhoneDialog() {
    final TextEditingController telephoneController = TextEditingController(text: _customerData['telephone'] ?? '');
    final TextEditingController faxController = TextEditingController(text: _customerData['fax'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('編輯聯絡資訊'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: '電話',
                  hintText: '請輸入您的電話號碼',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: faxController,
                decoration: const InputDecoration(
                  labelText: '傳真',
                  hintText: '請輸入您的傳真號碼（選填）',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _updatePhone(
                  telephoneController.text.trim(),
                  faxController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
  
  // 更新姓名
  Future<void> _updateName(String firstName, String lastName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 獲取用戶 ID
      final userId = await _userService.getUserId();
      if (userId == null) {
        throw Exception('無法獲取用戶 ID');
      }

      // 準備更新數據 - 確保包含所有必要的表單欄位
      final updateData = {
        'firstname': firstName,
        'lastname': lastName,
        // 保留其他用戶數據
        'email': _customerData['email'] ?? '',
        'telephone': _customerData['telephone'] ?? '',
        'fax': _customerData['fax'] ?? '',
        'newsletter': _customerData['newsletter'] ?? '0',
      };

      // 調用 API 更新用戶資料
      final result = await _apiService.updateCustomerProfile(userId, updateData);

      if (result['success'] == true || !result.containsKey('error')) {
        // 更新本地狀態
        setState(() {
          _customerData['firstname'] = firstName;
          _customerData['lastname'] = lastName;
          if (_userData != null) {
            _userData!['firstname'] = firstName;
            _userData!['lastname'] = lastName;
          }
          _isLoading = false;
        });
        
        // 更新 SharedPreferences
        await _updateSharedPreferences(firstName: firstName, lastName: lastName);

        // 顯示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('姓名更新成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 處理錯誤
        String errorMessage = '更新失敗';
        if (result.containsKey('message') && result['message'] is List && result['message'].isNotEmpty) {
          errorMessage = result['message'][0]['msg'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // 顯示錯誤消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 更新電話和傳真
  Future<void> _updatePhone(String telephone, String fax) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 獲取用戶 ID
      final userId = await _userService.getUserId();
      if (userId == null) {
        throw Exception('無法獲取用戶 ID');
      }

      // 準備更新數據 - 確保包含所有必要的表單欄位
      final updateData = {
        'firstname': _customerData['firstname'] ?? '',
        'lastname': _customerData['lastname'] ?? '',
        'email': _customerData['email'] ?? '',
        'telephone': telephone,
        'fax': fax,
        'newsletter': _customerData['newsletter'] ?? '0',
      };

      // 調用 API 更新用戶資料
      final result = await _apiService.updateCustomerProfile(userId, updateData);

      if (result['success'] == true || !result.containsKey('error')) {
        // 更新本地狀態
        setState(() {
          _customerData['telephone'] = telephone;
          _customerData['fax'] = fax;
          if (_userData != null) {
            _userData!['telephone'] = telephone;
            _userData!['fax'] = fax;
          }
          _isLoading = false;
        });
        
        // 更新 SharedPreferences
        await _updateSharedPreferences(telephone: telephone, fax: fax);

        // 顯示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('聯絡資訊更新成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 處理錯誤
        String errorMessage = '更新失敗';
        if (result.containsKey('message') && result['message'] is List && result['message'].isNotEmpty) {
          errorMessage = result['message'][0]['msg'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // 顯示錯誤消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // 更新 SharedPreferences 中的用戶數據
  Future<void> _updateSharedPreferences({
    String? firstName,
    String? lastName,
    String? telephone,
    String? fax,
  }) async {
    try {
      // 獲取 SharedPreferences 實例
      final prefs = await SharedPreferences.getInstance();
      
      // 更新名字
      if (firstName != null) {
        await prefs.setString('user_firstname', firstName);
      }
      
      // 更新姓氏
      if (lastName != null) {
        await prefs.setString('user_lastname', lastName);
      }
      
      // 更新電話
      if (telephone != null) {
        await prefs.setString('user_telephone', telephone);
      }
      
      // 更新傳真
      if (fax != null) {
        await prefs.setString('user_fax', fax);
      }
      
      // 通知 UserService 數據已更新
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.refreshUserData();
    } catch (e) {
      debugPrint('更新 SharedPreferences 失敗: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('會員資料'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCustomerData,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_customerData.isEmpty) {
      return const Center(
        child: Text('沒有找到會員資料'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頭像和姓名
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.purple,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_customerData['firstname'] ?? ''} ${_customerData['lastname'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: _showEditNameDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '會員 ID: ${_customerData['customer_id'] ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '加入日期: ${_formatDate(_customerData['date_added'] ?? '')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 會員資料列表
          const Text(
            '基本資料',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 電子郵件
          _buildInfoItem(
            icon: Icons.email,
            title: '電子郵件',
            value: _customerData['email'] ?? '',
          ),
          
          // 電話
          _buildInfoItem(
            icon: Icons.phone,
            title: '電話',
            value: _customerData['telephone'] ?? '',
            onTap: _showEditPhoneDialog,
          ),
          
          // 傳真
          if (_customerData['fax'] != null && _customerData['fax'].toString().isNotEmpty)
            _buildInfoItem(
              icon: Icons.fax,
              title: '傳真',
              value: _customerData['fax'],
              onTap: _showEditPhoneDialog,
            ),
          
          // 電子報訂閱
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '訂閱電子報',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(
                  value: _newsletterSubscribed,
                  onChanged: _updateNewsletter,
                  activeColor: Colors.purple,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 編輯按鈕
          Center(
            child: ElevatedButton(
              onPressed: _showEditNameDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                '編輯資料',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.purple,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.edit,
                size: 18,
                color: Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }
}
