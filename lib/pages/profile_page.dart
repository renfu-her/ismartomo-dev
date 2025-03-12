import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 是否已登入
  bool _isLoggedIn = false;
  
  // 會員功能項目列表
  final List<Map<String, dynamic>> _memberFeatures = [
    {'title': '我的訂單', 'icon': FontAwesomeIcons.fileInvoice, 'color': Colors.orange},
    {'title': '我的優惠券', 'icon': FontAwesomeIcons.ticket, 'color': Colors.red},
    {'title': '收貨地址', 'icon': FontAwesomeIcons.locationDot, 'color': Colors.green},
    {'title': '我的收藏', 'icon': FontAwesomeIcons.heart, 'color': Colors.pink},
  ];
  
  // 相關說明項目列表
  final List<Map<String, dynamic>> _infoItems = [
    {'title': '最新消息', 'icon': FontAwesomeIcons.newspaper},
    {'title': '推薦獎金計劃', 'icon': FontAwesomeIcons.gift},
    {'title': '關於我們', 'icon': FontAwesomeIcons.circleInfo},
    {'title': '技術支援', 'icon': FontAwesomeIcons.screwdriverWrench},
    {'title': '服務流程', 'icon': FontAwesomeIcons.gears},
    {'title': '線上客服', 'icon': FontAwesomeIcons.commentDots},
    {'title': '如何使用折價代碼', 'icon': FontAwesomeIcons.tag},
    {'title': '合作品牌', 'icon': FontAwesomeIcons.handshake},
    {'title': '經銷優勢', 'icon': FontAwesomeIcons.chartLine},
    {'title': '隱私與條款', 'icon': FontAwesomeIcons.shieldHalved},
  ];

  @override
  Widget build(BuildContext context) {
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
            if (!_isLoggedIn) 
              _buildLoginSection()
            else
              _buildUserInfoSection(),
            
            // 會員功能區
            if (_isLoggedIn) _buildMemberFeatures(),
            
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
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _infoItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: FaIcon(_infoItems[index]['icon'], size: 20, color: Colors.grey[600]),
                  title: Text(_infoItems[index]['title']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // 點擊項目的處理邏輯
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('您點擊了: ${_infoItems[index]['title']}')),
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
                    // 註冊功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('註冊功能待實現')),
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
                  onPressed: () {
                    // 模擬登入成功
                    setState(() {
                      _isLoggedIn = true;
                    });
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
  Widget _buildUserInfoSection() {
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
                const Text(
                  '測試用戶',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '會員等級: 普通會員',
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
              setState(() {
                _isLoggedIn = false;
              });
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('您點擊了: ${feature['title']}')),
                    );
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