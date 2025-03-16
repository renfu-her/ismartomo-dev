import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _cartItems = [];
  List<dynamic> _totals = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  Future<void> _fetchCartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getCart();
      
      if (response.containsKey('customer_cart')) {
        setState(() {
          _cartItems = response['customer_cart'] ?? [];
          _totals = response['totals'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _cartItems = [];
          _totals = [];
          _isLoading = false;
          _errorMessage = '購物車為空';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // 檢查錯誤信息是否包含「用戶未登入」
        if (e.toString().contains('用戶未登入')) {
          _cartItems = [];
          _totals = [];
          _errorMessage = '購物車為空';
        } else {
          _errorMessage = '獲取購物車數據失敗: ${e.toString()}';
        }
      });
    }
  }

  Future<void> _updateCartItemQuantity(String cartId, int quantity) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _apiService.updateCartQuantity(cartId, quantity);
      await _fetchCartData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新數量失敗: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _removeCartItem(String cartId) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 顯示確認對話框
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('確認移除'),
            content: const Text('確定要從購物車中移除此商品嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('確定'),
              ),
            ],
          );
        },
      ) ?? false;
      
      if (!confirmDelete) {
        setState(() {
          _isUpdating = false;
        });
        return;
      }
      
      // 顯示加載指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // 調用 API 移除購物車項目
      await _apiService.removeFromCart(cartId);
      
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 重新獲取購物車數據
      await _fetchCartData();
      
      // 顯示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品已從購物車中移除')),
      );
    } catch (e) {
      // 關閉加載指示器
      Navigator.of(context, rootNavigator: true).pop();
      
      // 顯示錯誤消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('移除商品失敗: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('購物車'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCartData,
              tooltip: '刷新購物車',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _cartItems.isEmpty
              ? _buildEmptyCart()
              : _cartItems.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return SafeArea(
      child: Column(
        children: [
          // 主要內容區域 - 佔據大部分空間
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 購物車圖標
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 120,
                    color: Colors.grey[350],
                  ),
                  const SizedBox(height: 20),
                  // 空購物車提示文字
                  Text(
                    '您的購物車是空的！',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_errorMessage.isNotEmpty && _errorMessage != '購物車為空')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 200), // 增加底部空間，使按鈕位置更接近圖片
                ],
              ),
            ),
          ),
          
          // 底部按鈕區域
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // 切換到首頁
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  '逛逛賣場',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // 購物車商品列表
        Expanded(
          child: ListView.builder(
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item);
            },
          ),
        ),
        
        // 購物車總計
        _buildCartTotals(),
        
        // 結帳按鈕
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // 導航到結帳頁面
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CheckoutPage(),
                  ),
                ).then((_) {
                  // 從結帳頁面返回後刷新購物車數據
                  _fetchCartData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                '前往結帳',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(dynamic item) {
    final int quantity = int.tryParse(item['quantity'].toString()) ?? 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品圖片
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Image.network(
                  item['thumb'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品名稱
                  Text(
                    item['name'] ?? '未知商品',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 產品ID (設置為白色，實際上是隱藏)
                  Text(
                    'ID: ${item['product_id']}',
                    style: const TextStyle(
                      fontSize: 1,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 價格和數量
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 價格
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '單價: ${item['price'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '小計: ${item['total'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      
                      // 數量調整
                      Row(
                        children: [
                          // 減號按鈕
                          InkWell(
                            onTap: () {
                              if (quantity > 1) {
                                _updateCartItemQuantity(item['cart_id'], quantity - 1);
                              }
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          
                          // 數量顯示
                          Container(
                            width: 40,
                            height: 28,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          
                          // 加號按鈕
                          InkWell(
                            onTap: () {
                              _updateCartItemQuantity(item['cart_id'], quantity + 1);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 刪除按鈕
            InkWell(
              onTap: () {
                _removeCartItem(item['cart_id']);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.delete_outline, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartTotals() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          ..._totals.map((total) {
            final bool isTotal = total['code'] == 'total';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    total['title'] ?? '',
                    style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    total['text'] ?? '',
                    style: TextStyle(
                      fontSize: isTotal ? 18 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 