import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'information_page.dart';
import 'customer_profile_page.dart';
import 'address_list_page.dart';
import 'order_list_page.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  bool _isLoadingInfo = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _informationList = [];
  
  // 會員功能項目列表
  final List<Map<String, dynamic>> _memberFeatures = [
    {'title': '會員資料', 'icon': FontAwesomeIcons.userGear, 'color': Colors.blue},
    {'title': '我的訂單', 'icon': FontAwesomeIcons.fileInvoice, 'color': Colors.orange},
    {'title': '收貨地址', 'icon': FontAwesomeIcons.locationDot, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInformationList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次頁面顯示時重新讀取用戶資料
    final userService = Provider.of<UserService>(context, listen: false);
    if (userService.isLoggedIn) {
      userService.refreshUserData();
    }
  }

  Future<void> _fetchInformationList() async {
    setState(() {
      _isLoadingInfo = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getAllInformation();
      
      setState(() {
        _isLoadingInfo = false;
        
        if (response.containsKey('informations') && 
            response['informations'] is List) {
          _informationList = List<Map<String, dynamic>>.from(response['informations']);
          
          // 按照 sort_order 排序（如果有）
          _informationList.sort((a, b) {
            final aOrder = int.tryParse(a['sort_order']?.toString() ?? '') ?? 999;
            final bOrder = int.tryParse(b['sort_order']?.toString() ?? '') ?? 999;
            return aOrder.compareTo(bOrder);
          });
        } else {
          _errorMessage = '無法獲取資訊列表';
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingInfo = false;
        _errorMessage = '獲取資訊列表失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 來監聽 UserService 的變化
    return Consumer<UserService>(
      builder: (context, userService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('會員中心'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('設定功能待實現')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 登入區域
                if (!userService.isLoggedIn) 
                  _buildLoginSection()
                else
                  _buildUserInfoSection(userService),
                
                // 會員功能區
                _buildMemberFeatures(),
                
                // 分隔線
                const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                
                // 相關說明標題
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '相關說明',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // 相關說明項目列表
                _isLoadingInfo
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _fetchInformationList,
                              child: const Text('重試'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _informationList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final information = _informationList[index];
                          final title = information['title'] ?? '無標題';
                          
                          return ListTile(
                            title: Text(title),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // 導航到資訊頁面
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => InformationPage(
                                    informationId: information['information_id'],
                                    title: title,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                
                // 底部版本信息
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'App 版本 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  // 構建登入區域
  Widget _buildLoginSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            '請登入會員帳號',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 註冊按鈕
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // 導向註冊頁面
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    '註冊',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 登入按鈕
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // 導向登入頁面
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // 構建用戶信息區域
  Widget _buildUserInfoSection(UserService userService) {
    return FutureBuilder<Map<String, String>>(
      future: userService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final userData = snapshot.data ?? {
          'firstname': '用戶',
          'lastname': '',
        };
        
        final fullName = '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim();
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.purple,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? '用戶' : fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['email'] != null && userData['email']!.isNotEmpty
                          ? userData['email']!
                          : '會員等級: 普通會員',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // 登出功能
                  _logout(userService);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text('登出'),
              ),
            ],
          ),
        );
      }
    );
  }
  
  // 登出功能
  Future<void> _logout(UserService userService) async {
    try {
      // 使用 UserService 的登出方法
      final success = await userService.logout();
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登出失敗，請稍後再試')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('您已成功登出')),
        );
      }
    } catch (e) {
      debugPrint('登出錯誤: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登出失敗，請稍後再試')),
      );
    }
  }
  
  // 構建會員功能區
  Widget _buildMemberFeatures() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '會員功能',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _memberFeatures.map((feature) {
              return Expanded(
                child: InkWell(
                  onTap: () {
                    // 根據不同的功能項目執行不同的操作
                    switch (feature['title']) {
                      case '會員資料':
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomerProfilePage()),
                        );
                        break;
                      case '我的訂單':
                        // 檢查用戶是否已登入
                        final userService = Provider.of<UserService>(context, listen: false);
                        if (userService.isLoggedIn) {
                          // 導航到訂單列表頁面
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderListPage()),
                          );
                        } else {
                          // 提示用戶登入
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('請先登入會員')),
                          );
                          // 導航到登入頁面
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        }
                        break;
                      case '收貨地址':
                        // 檢查用戶是否已登入
                        final userService = Provider.of<UserService>(context, listen: false);
                        if (userService.isLoggedIn) {
                          // 導航到地址列表頁面
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddressListPage()),
                          );
                        } else {
                          // 提示用戶登入
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('請先登入會員')),
                          );
                          // 導航到登入頁面
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        }
                        break;
                      default:
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('您點擊了: ${feature['title']}')),
                        );
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: feature['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(
                            feature['icon'],
                            color: feature['color'],
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature['title'],
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 