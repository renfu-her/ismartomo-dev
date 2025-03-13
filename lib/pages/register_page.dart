import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _faxController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // 區域列表
  List<Map<String, dynamic>> _zones = [];
  String? _selectedZoneId;
  
  // API 服務
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchZones();
    print('註冊頁面初始化');
  }

  // 獲取區域列表
  Future<void> _fetchZones() async {
    try {
      print('開始獲取區域列表');
      final response = await _apiService.getZones('206'); // 台灣的 country_id 是 206
      print('區域列表響應: $response');
      
      setState(() {
        if (response.containsKey('zones') && response['zones'] is List) {
          _zones = List<Map<String, dynamic>>.from(response['zones']);
          print('獲取到 ${_zones.length} 個區域');
          if (_zones.isNotEmpty) {
            _selectedZoneId = _zones[0]['zone_id'];
            print('選擇的區域 ID: $_selectedZoneId, 名稱: ${_zones[0]['name']}');
          }
        } else {
          print('無法獲取區域列表: ${response.toString()}');
        }
      });
    } catch (e) {
      print('獲取區域列表錯誤: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telephoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _faxController.dispose();
    super.dispose();
  }
  
  // 註冊 API 請求
  Future<bool> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 準備註冊數據
      final userData = {
        'firstname': _firstNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'confirm': _confirmPasswordController.text,
        'telephone': _telephoneController.text.trim(),
        'address_1': _address1Controller.text.trim(),
        'address_2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'country_id': '206', // 台灣
        'zone_id': _selectedZoneId,
        'fax': _faxController.text.trim(),
        'custom_field[account][1]': '711',
        'newsletter': '0',
      };
      
      print('註冊數據: $userData');
      
      // 調用註冊 API
      final response = await _apiService.register(userData);
      
      print('註冊響應: $response');
      
      setState(() {
        _isLoading = false;
      });
      
      // 檢查註冊是否成功
      if (response.containsKey('message') && 
          response['message'] is List && 
          response['message'].isNotEmpty) {
        
        final message = response['message'][0];
        print('註冊消息: $message');
        
        if (message.containsKey('msg_status') && message['msg_status'] == false) {
          // 註冊失敗
          setState(() {
            _errorMessage = message['msg'] ?? '註冊失敗，請稍後再試';
          });
          return false;
        } else {
          // 註冊成功
          return true;
        }
      } else if (response.containsKey('success')) {
        // 另一種成功響應格式
        return true;
      } else {
        // 無法解析響應
        setState(() {
          _errorMessage = '無法解析響應數據';
        });
        return false;
      }
    } on DioException catch (e) {
      // Dio 異常處理
      String errorMsg = '網絡請求錯誤';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = '連接超時，請檢查您的網絡';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '接收數據超時，請稍後再試';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMsg = '發送數據超時，請稍後再試';
      } else if (e.response != null) {
        errorMsg = '服務器錯誤: ${e.response?.statusCode}';
        
        // 嘗試從響應中獲取更詳細的錯誤信息
        if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data as Map;
          if (data.containsKey('message') && data['message'] is List && data['message'].isNotEmpty) {
            final message = data['message'][0];
            if (message.containsKey('msg')) {
              errorMsg = message['msg'];
            }
          }
        }
      }
      
      print('註冊 Dio 異常: $errorMsg');
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
      return false;
    } catch (e) {
      // 其他異常處理
      print('註冊其他異常: ${e.toString()}');
      
      setState(() {
        _isLoading = false;
        _errorMessage = '發生錯誤: ${e.toString()}';
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 獲取 UserService 實例
    final userService = Provider.of<UserService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('會員註冊'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部圖標
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.app_registration,
                      size: 80,
                      color: Colors.purple,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              
              // 歡迎文字
              const Center(
                child: Text(
                  '創建新帳號',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '請填寫以下資料完成註冊',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // 錯誤訊息
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // 名字輸入框
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: '名字',
                  hintText: '請輸入您的名字',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入名字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 姓氏輸入框
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: '姓氏',
                  hintText: '請輸入您的姓氏',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入姓氏';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 電子郵件輸入框
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '電子郵件',
                  hintText: '請輸入您的電子郵件',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入電子郵件';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '請輸入有效的電子郵件地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 密碼輸入框
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '密碼',
                  hintText: '請輸入您的密碼',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  if (value.length < 6) {
                    return '密碼長度至少為6個字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 確認密碼輸入框
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: '確認密碼',
                  hintText: '請再次輸入您的密碼',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請確認密碼';
                  }
                  if (value != _passwordController.text) {
                    return '兩次輸入的密碼不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 電話輸入框
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '電話',
                  hintText: '請輸入您的電話號碼',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入電話號碼';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 傳真輸入框
              TextFormField(
                controller: _faxController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '傳真 (選填)',
                  hintText: '請輸入您的傳真號碼',
                  prefixIcon: const Icon(Icons.fax),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 地址1輸入框
              TextFormField(
                controller: _address1Controller,
                decoration: InputDecoration(
                  labelText: '地址',
                  hintText: '請輸入您的地址',
                  prefixIcon: const Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 地址2輸入框
              TextFormField(
                controller: _address2Controller,
                decoration: InputDecoration(
                  labelText: '地址 (選填)',
                  hintText: '請輸入您的補充地址',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 城市輸入框
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: '城市',
                  hintText: '請輸入您所在的城市',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入城市';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 郵遞區號輸入框
              TextFormField(
                controller: _postcodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '郵遞區號',
                  hintText: '請輸入您的郵遞區號',
                  prefixIcon: const Icon(Icons.markunread_mailbox),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入郵遞區號';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 區域選擇
              DropdownButtonFormField<String>(
                value: _selectedZoneId,
                decoration: InputDecoration(
                  labelText: '區域',
                  prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _zones.map((zone) {
                  return DropdownMenuItem<String>(
                    value: zone['zone_id'],
                    child: Text(zone['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedZoneId = value;
                    print('選擇的區域已更改為: $value');
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請選擇區域';
                  }
                  return null;
                },
                hint: const Text('請選擇區域'),
              ),
              const SizedBox(height: 16),
              
              // 同意條款
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: Colors.purple,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        children: [
                          const TextSpan(text: '我已閱讀並同意 '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('服務條款功能待實現')),
                                );
                              },
                              child: const Text(
                                '服務條款',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' 和 '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('隱私政策功能待實現')),
                                );
                              },
                              child: const Text(
                                '隱私政策',
                                style: TextStyle(
                                  color: Colors.purple,
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
              const SizedBox(height: 24),
              
              // 註冊按鈕
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _agreeToTerms
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await _register();
                              
                              if (success) {
                                // 註冊成功
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('註冊成功，請登入')),
                                );
                                
                                // 導向登入頁面
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '註冊',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              
              // 登入提示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '已有帳號？',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 導向登入頁面
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      '立即登入',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 