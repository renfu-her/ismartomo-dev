import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _categories = [];
  // 用於追蹤每個分類是否展開
  Map<String, bool> _expandedCategories = {};
  
  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }
  
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.getAllCategories();
      
      setState(() {
        _isLoading = false;
        if (response.containsKey('categories')) {
          _categories = response['categories'];
          // 初始化所有分類為收起狀態
          for (var category in _categories) {
            _expandedCategories[category['category_id'].toString()] = false;
          }
        } else {
          _errorMessage = '無法獲取分類數據';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取分類失敗: ${e.toString()}';
      });
    }
  }

  // 切換分類的展開/收起狀態
  void _toggleCategory(String categoryId) {
    setState(() {
      _expandedCategories[categoryId] = !(_expandedCategories[categoryId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchCategories,
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
          : _categories.isEmpty
            ? const Center(child: Text('沒有找到分類'))
            : RefreshIndicator(
                onRefresh: _fetchCategories,
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final categoryId = category['category_id'].toString();
                    final hasChildren = category['children'] != null && 
                                      category['children'] is List && 
                                      (category['children'] as List).isNotEmpty;
                    
                    return Column(
                      children: [
                        // 主分類項目
                        InkWell(
                          onTap: () {
                            if (hasChildren) {
                              _toggleCategory(categoryId);
                            } else {
                              // 導航到產品列表頁面
                              Navigator.pushNamed(
                                context, 
                                '/product_list',
                                arguments: {
                                  'category_id': categoryId,
                                  'category_name': category['name'],
                                },
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                // 分類圖片
                                if (category['image'] != null)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.only(right: 16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30.0),
                                      child: Image.network(
                                        category['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                // 分類名稱
                                Expanded(
                                  child: Text(
                                    category['name'] ?? '未知分類',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // 展開/收起圖標
                                if (hasChildren)
                                  Icon(
                                    _expandedCategories[categoryId] ?? false
                                        ? Icons.keyboard_arrow_down
                                        : Icons.keyboard_arrow_right,
                                    size: 24.0,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 分隔線
                        const Divider(height: 1, thickness: 1),
                        // 子分類列表（如果當前分類已展開）
                        if (hasChildren && (_expandedCategories[categoryId] ?? false))
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: (category['children'] as List).length,
                            itemBuilder: (context, subIndex) {
                              final subCategory = (category['children'] as List)[subIndex];
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      // 導航到產品列表頁面
                                      Navigator.pushNamed(
                                        context, 
                                        '/product_list',
                                        arguments: {
                                          'category_id': subCategory['category_id'].toString(),
                                          'category_name': subCategory['name'],
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 76.0, right: 16.0, top: 12.0, bottom: 12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subCategory['name'] ?? '未知子分類',
                                              style: const TextStyle(fontSize: 14.0),
                                            ),
                                          ),
                                          const Icon(Icons.keyboard_arrow_right, size: 20.0, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1, thickness: 1, indent: 76.0),
                                ],
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
    );
  }
} 