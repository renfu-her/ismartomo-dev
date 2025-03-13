import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 登入 API 請求
  Future<bool> _login(String email, String password, UserService userService) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 使用 UserService 的登入方法
      final success = await userService.login(email, password);
      
      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = '登入失敗，請檢查您的帳號和密碼';
        });
      }
      
      setState(() {
        _isLoading = false;
      });
      
      return success;
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
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
      return false;
    } catch (e) {
      // 其他異常處理
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
        title: const Text('會員登入'),
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
                      Icons.account_circle,
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
                  '歡迎回來',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '請輸入您的帳號密碼登入',
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
              
              // 帳號輸入框
              TextFormField(
                controller: _usernameController,
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
                  return null;
                },
              ),
              const SizedBox(height: 8),
              
              // 忘記密碼
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('忘記密碼功能待實現')),
                    );
                  },
                  child: const Text('忘記密碼？'),
                ),
              ),
              const SizedBox(height: 24),
              
              // 登入按鈕
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // 調用登入 API
                        final success = await _login(
                          _usernameController.text.trim(),
                          _passwordController.text,
                          userService,
                        );
                        
                        if (success) {
                          // 登入成功
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('登入成功')),
                          );
                          
                          // 返回上一頁並傳遞登入成功的信息
                          Navigator.pop(context, true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '登入',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              
              // 註冊提示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '還沒有帳號？',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 導向註冊頁面
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    child: const Text(
                      '立即註冊',
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