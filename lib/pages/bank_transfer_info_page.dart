import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BankTransferInfoPage extends StatefulWidget {
  const BankTransferInfoPage({super.key});

  @override
  State<BankTransferInfoPage> createState() => _BankTransferInfoPageState();
}

class _BankTransferInfoPageState extends State<BankTransferInfoPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  // 銀行轉帳資訊
  String _bankTransferInfo = '';
  
  @override
  void initState() {
    super.initState();
    _fetchBankTransferInfo();
  }
  
  Future<void> _fetchBankTransferInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 獲取商店設置，其中包含銀行轉帳信息
      final response = await _apiService.getStoreSettings();
      
      // 提取銀行轉帳資訊
      // 檢查是否有settings字段，並從中獲取payment_bank_transfer_bank1
      if (response.containsKey('settings') && response['settings'] is Map<String, dynamic>) {
        final settings = response['settings'] as Map<String, dynamic>;
        if (settings.containsKey('payment_bank_transfer_bank1')) {
          _bankTransferInfo = settings['payment_bank_transfer_bank1'] ?? '';
        }
      } 
      // 如果沒有settings字段，則直接從response中獲取
      else if (response.containsKey('payment_bank_transfer_bank1')) {
        _bankTransferInfo = response['payment_bank_transfer_bank1'] ?? '';
      }
      
      // 如果沒有獲取到資訊，設置默認值
      if (_bankTransferInfo.isEmpty) {
        _bankTransferInfo = '⭕華南商業銀行 分行名稱 \r\n\r\n⭕銀行代碼:001  帳號 : 2472\r\n\r\n⭕匯款完成，請LINE:  通知客服\r\nTEST20241206';
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // 設置默認值
        _bankTransferInfo = '⭕華南商業銀行 分行名稱 \r\n\r\n⭕銀行代碼:001  帳號 : 2472\r\n\r\n⭕匯款完成，請LINE:  通知客服\r\nTEST20241206';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('銀行轉帳資訊'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBankInfoContent(),
    );
  }
  
  Widget _buildBankInfoContent() {
    // 處理顯示格式
    String displayText = _bankTransferInfo
        .replaceAll('⭕', '')  // 移除⭕符號
        .replaceAll('\r\n\r\n', '\n')  // 替換多餘的換行
        .trim();
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '銀行轉帳付款方式',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // 銀行資訊卡片 - 顯示完整資訊
            Card(
              elevation: 2,
              color: const Color(0xFFF8F0F8), // 淡紫色背景
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 銀行圖標
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 32,
                          color: Colors.blue[400],
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            '銀行資訊',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // 完整銀行轉帳資訊
                    Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 注意事項 - 類似截圖
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFFFFF8E1), // 淡黃色背景
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[800],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '付款注意事項',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. 請在轉帳後保留交易明細或收據，以便核對。\n'
                      '2. 轉帳時請在備註欄填寫您的訂單編號。\n'
                      '3. 完成轉帳後，請聯繫客服確認付款狀態。\n'
                      '4. 我們將在確認款項後安排出貨。',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 返回按鈕 - 類似截圖
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0), // 方形按鈕
                  ),
                  elevation: 0, // 無陰影
                ),
                child: const Text(
                  '返回首頁',
                  style: TextStyle(
                    fontSize: 16,
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
} 