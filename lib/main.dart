import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API 數據展示',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ProductListPage(title: '熱門產品列表'),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.title});

  final String title;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final Dio _dio = Dio();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = '';
    });

    try {
      final response = await _dio.get(
        'https://ismartdemo.com.tw/index.php?route=extension/module/api/gws_appproducts_popular&api_key=CNQ4eX5WcbgFQVkBXFKmP9AE2AYUpU2HySz2wFhwCZ3qExG6Tep7ZCSZygwzYfsF',
      );

      print(response.data);

      setState(() {
        _isLoading = false;
        
        // 檢查 message 欄位
        if (response.data is Map && response.data.containsKey('message') && response.data['message'] is List && response.data['message'].isNotEmpty) {
          _statusMessage = response.data['message'][0]['msg'] ?? '';
        }
        
        // 檢查 popular_products 欄位
        if (response.data is Map && response.data.containsKey('popular_products')) {
          _products = response.data['popular_products'];
        } 
        // 如果沒有 popular_products，嘗試檢查 latest_products 欄位
        else if (response.data is Map && response.data.containsKey('latest_products')) {
          _products = response.data['latest_products'];
        }
        // 如果沒有 latest_products，嘗試檢查 products 欄位
        else if (response.data is Map && response.data.containsKey('products')) {
          _products = response.data['products'];
        } 
        else {
          _products = [];
          _errorMessage = '無法解析產品數據';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取數據失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
              onPressed: _fetchProducts,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('沒有找到產品'),
      );
    }

    return Column(
      children: [
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchProducts,
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 12.0,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ProductCard(product: product);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product['thumb'] != null)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: Image.network(
                  product['thumb'].startsWith('http') 
                      ? product['thumb'] 
                      : 'https://ismartdemo.com.tw/image/${product['thumb']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product['name'] ?? '未知產品',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product['price'] != null)
                    Text(
                      '價格: ${product['price']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (product['model'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '型號: ${product['model']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (product['quantity'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '庫存: ${product['quantity']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: int.parse(product['quantity']) > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 24,
                    child: ElevatedButton(
                      onPressed: () {
                        // 這裡可以添加查看詳情或添加到購物車的功能
                        if (product['href'] != null) {
                          // 打開產品詳情頁面的功能可以在這裡實現
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                      child: const Text('查看詳情'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 移除 HTML 標籤的輔助函數
  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }
}
