import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'order_detail_page.dart';
import 'profile_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _orderList = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderList();
  }

  Future<void> _fetchOrderList() async {
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (!userService.isLoggedIn) {
      setState(() {
        _errorMessage = '請先登入會員';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final customerId = await userService.getCustomerId();
      
      if (customerId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '無法獲取會員ID';
        });
        return;
      }
      
      final response = await _apiService.getCustomerOrders(customerId);
      
      setState(() {
        _isLoading = false;
        
        if (response.containsKey('orders') && 
            response['orders'] is List) {
          _orderList = List<Map<String, dynamic>>.from(response['orders']);
        } else {
          _errorMessage = '無法獲取訂單列表';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取訂單列表失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的訂單'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 返回首頁
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
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
                    onPressed: _fetchOrderList,
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
          : _orderList.isEmpty
            ? const Center(
                child: Text('您目前沒有任何訂單'),
              )
            : RefreshIndicator(
                onRefresh: _fetchOrderList,
                child: ListView.separated(
                  itemCount: _orderList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = _orderList[index];
                    final orderId = order['order_id'] ?? '';
                    final name = order['name'] ?? '';
                    final status = order['status'] ?? '';
                    final dateAdded = order['date_added'] ?? '';
                    final products = order['products'] ?? 0;
                    final total = order['total'] ?? '';
                    
                    return ListTile(
                      title: Row(
                        children: [
                          Text(
                            '訂單 #$orderId',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
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
                          Text('訂購日期: $dateAdded'),
                          Text('商品數量: $products'),
                          Text('訂單金額: $total'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailPage(
                              orderId: orderId,
                            ),
                          ),
                        ).then((_) {
                          // 返回時重新載入訂單列表
                          _fetchOrderList();
                        });
                      },
                    );
                  },
                ),
              ),
    );
  }
  
  Color _getStatusColor(String status) {
    if (status.contains('待付款')) {
      return Colors.orange;
    } else if (status.contains('完成')) {
      return Colors.green;
    } else if (status.contains('取消')) {
      return Colors.red;
    } else if (status.contains('處理中')) {
      return Colors.blue;
    } else if (status.contains('已出貨')) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }
} 