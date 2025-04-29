import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:flutter_html/flutter_html.dart';

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
  }

  // 獲取區域列表
  Future<void> _fetchZones() async {
    try {
      final response = await _apiService.getZones('206'); // 台灣的 country_id 是 206
      
      setState(() {
        if (response.containsKey('zones') && response['zones'] is List) {
          _zones = List<Map<String, dynamic>>.from(response['zones']);
          if (_zones.isNotEmpty) {
            _selectedZoneId = _zones[0]['zone_id'];
          }
        }
      });
    } catch (e) {
      // 錯誤處理
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
      // 確保所有必要的字段都有值
      // if (_selectedZoneId == null || _selectedZoneId!.isEmpty) {
      //   setState(() {
      //     _errorMessage = '請選擇區域';
      //     _isLoading = false;
      //   });
      //   return false;
      // }

      // 準備註冊數據
      final userData = {
        'lastname': _lastNameController.text.trim(),
        'firstname': _firstNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'confirm': _confirmPasswordController.text,
        'telephone': _telephoneController.text.trim(),
        // 'address_1': _address1Controller.text.trim(),
        // 'address_2': _address2Controller.text.trim().isNotEmpty ? _address2Controller.text.trim() : '',
        // 'city': _cityController.text.trim(),
        // 'postcode': _postcodeController.text.trim(),
        // 'country_id': '206', // 台灣
        // 'address_1': '',
        // 'address_2': '',
        // 'city': '',
        // 'postcode': '',
        // 'country_id': '206',
        // 'zone_id': _selectedZoneId!,
        'fax': _faxController.text.trim().isNotEmpty ? _faxController.text.trim() : '',
        // 'custom_field[account][1]': '711',
        // 'newsletter': '0',
        // 'company': '', // 公司欄位，必須傳遞空白
      };
      
      // 調用註冊 API
      final response = await _apiService.register(userData);

      print(response);
      
      setState(() {
        _isLoading = false;
      });
      
      // 檢查是否有錯誤
      if (response.containsKey('error') && response['error'] == true) {
        // API 服務返回的錯誤
        if (response.containsKey('message') && 
            response['message'] is List && 
            response['message'].isNotEmpty) {
          final message = response['message'][0];
          setState(() {
            _errorMessage = message['msg'] ?? '註冊失敗，請稍後再試';
          });
        } else {
          setState(() {
            _errorMessage = '註冊失敗，請稍後再試';
          });
        }
        return false;
      }
      
      // 檢查註冊是否成功
      if (response.containsKey('success') && response['success'] == true) {
        // 直接成功標誌
        return true;
      } else if (response.containsKey('raw_response')) {
        // 原始響應，檢查是否包含成功信息
        final rawResponse = response['raw_response'].toString().toLowerCase();
        if (rawResponse.contains('success') || 
            rawResponse.contains('成功') || 
            !rawResponse.contains('error') && 
            !rawResponse.contains('失敗')) {
          return true;
        } else {
          setState(() {
            _errorMessage = '註冊失敗: $rawResponse';
          });
          return false;
        }
      } else if (response.containsKey('message') && 
                response['message'] is List && 
                response['message'].isNotEmpty) {
        
        final message = response['message'][0];
        
        if (message.containsKey('msg_status') && message['msg_status'] == false) {
          // 註冊失敗
          setState(() {
            _errorMessage = message['msg'] ?? '註冊失敗，請稍後再試';
          });
          return false;
        } else if (message.containsKey('msg_status') && message['msg_status'] == true) {
          // 註冊成功 - 明確的成功狀態
          return true;
        } else if (message.containsKey('msg') && 
                  (message['msg'].toString().contains('success') || 
                   message['msg'].toString().contains('成功') || 
                   message['msg'].toString().contains('Customer data updated successfully'))) {
          // 註冊成功 - 根據訊息內容判斷
          return true;
        } else {
          // 其他情況，嘗試判斷是否成功
          return message.containsKey('msg') && !message['msg'].toString().contains('error');
        }
      } else {
        // 無法解析響應，但沒有明確的錯誤，視為成功
        return true;
      }
    } catch (e) {
      // 其他異常處理
      setState(() {
        _isLoading = false;
        _errorMessage = '發生錯誤: ${e.toString()}';
      });
      return false;
    }
  }

  void _showPrivacyTermsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return FutureBuilder<String>(
          future: _apiService.getPrivacyTerms(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('服務與隱私'),
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (snapshot.hasError) {
              return const AlertDialog(
                title: Text('服務與隱私'),
                content: Text('無法載入條款內容，請稍後再試。'),
              );
            }
            return AlertDialog(
              title: const Text('服務與隱私'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  child: Html(
                    data: snapshot.data ?? '',
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('關閉'),
                ),
              ],
            );
          },
        );
      },
    );
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
              // 頂部圖標與文字排列在一起
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.purple.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.app_registration,
                            size: 48,
                            color: Colors.purple,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '創建新帳號',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '請填寫以下資料完成註冊',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
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
              
              // 分組標題 - 基本資料
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '基本資料',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
              
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
              
              // 分組標題 - 聯絡資料
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: Text(
                  '聯絡資料',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
              
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
              
              // 分組標題 - 地址資料
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              //   child: Text(
              //     '地址資料',
              //     style: TextStyle(
              //       fontSize: 18,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.purple.shade800,
              //     ),
              //   ),
              // ),
              
              // // 地址1輸入框
              // TextFormField(
              //   controller: _address1Controller,
              //   decoration: InputDecoration(
              //     labelText: '地址',
              //     hintText: '請輸入您的地址',
              //     prefixIcon: const Icon(Icons.home),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return '請輸入地址';
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(height: 16),
              
              // // 地址2輸入框
              // TextFormField(
              //   controller: _address2Controller,
              //   decoration: InputDecoration(
              //     labelText: '地址 (選填)',
              //     hintText: '請輸入您的補充地址',
              //     prefixIcon: const Icon(Icons.home_outlined),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              
              // // 城市輸入框
              // TextFormField(
              //   controller: _cityController,
              //   decoration: InputDecoration(
              //     labelText: '城市',
              //     hintText: '請輸入您所在的城市',
              //     prefixIcon: const Icon(Icons.location_city),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return '請輸入城市';
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(height: 16),
              
              // // 郵遞區號輸入框
              // TextFormField(
              //   controller: _postcodeController,
              //   keyboardType: TextInputType.number,
              //   decoration: InputDecoration(
              //     labelText: '郵遞區號',
              //     hintText: '請輸入您的郵遞區號',
              //     prefixIcon: const Icon(Icons.markunread_mailbox),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return '請輸入郵遞區號';
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(height: 16),
              
              // // 區域選擇
              // DropdownButtonFormField<String>(
              //   value: _selectedZoneId,
              //   decoration: InputDecoration(
              //     labelText: '區域',
              //     prefixIcon: const Icon(Icons.map),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              //   items: _zones.map((zone) {
              //     return DropdownMenuItem<String>(
              //       value: zone['zone_id'],
              //       child: Text(zone['name']),
              //     );
              //   }).toList(),
              //   onChanged: (value) {
              //     setState(() {
              //       _selectedZoneId = value;
              //     });
              //   },
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return '請選擇區域';
              //     }
              //     return null;
              //   },
              //   hint: const Text('請選擇區域'),
              // ),
              // const SizedBox(height: 16),
              
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
                              onTap: _showPrivacyTermsDialog,
                              child: const Text(
                                '服務與隱私',
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
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: _agreeToTerms 
                        ? const LinearGradient(
                            colors: [Colors.purple, Colors.deepPurple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                      color: _agreeToTerms ? null : Colors.grey.shade300,
                    ),
                    child: ElevatedButton(
                      onPressed: _agreeToTerms
                          ? () async {
                              if (_formKey.currentState!.validate()) {
                                final success = await _register();
                                
                                if (success) {
                                  // 註冊成功
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('註冊成功，即將跳轉到登入頁面'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // 顯示成功對話框
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('註冊成功'),
                                        content: const Text('您的帳號已成功註冊，請使用您的電子郵件和密碼登入。'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('立即登入'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              // 導向登入頁面
                                              Navigator.pushReplacementNamed(context, '/login');
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
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
                  ),
              const SizedBox(height: 24),
              
              // 登入提示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
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
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 