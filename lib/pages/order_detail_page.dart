import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'dart:convert';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  
  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic> _orderDetail = {};
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _totals = [];
  List<Map<String, dynamic>> _histories = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
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
      
      final response = await _apiService.getOrderDetail(customerId, widget.orderId);
      
      setState(() {
        _isLoading = false;
        
        if (response.containsKey('order') && 
            response['order'] is List && 
            response['order'].isNotEmpty) {
          _orderDetail = response['order'][0];
          
          if (response.containsKey('products') && response['products'] is List) {
            _products = List<Map<String, dynamic>>.from(response['products']);
          }
          
          if (response.containsKey('totals') && response['totals'] is List) {
            _totals = List<Map<String, dynamic>>.from(response['totals']);
          }
          
          if (response.containsKey('histories') && response['histories'] is List) {
            _histories = List<Map<String, dynamic>>.from(response['histories']);
          }
        } else {
          _errorMessage = '無法獲取訂單詳情';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取訂單詳情失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('訂單 #${widget.orderId}'),
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
                    onPressed: _fetchOrderDetail,
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
          : _orderDetail.isEmpty
            ? const Center(
                child: Text('無法獲取訂單詳情'),
              )
            : RefreshIndicator(
                onRefresh: _fetchOrderDetail,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 訂單狀態
                      _buildStatusSection(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      
                      // 訂單資訊
                      _buildOrderInfoSection(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      
                      // 商品列表
                      _buildProductsSection(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      
                      // 金額明細
                      _buildTotalsSection(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      
                      // 收件資訊
                      _buildShippingSection(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      
                      // 付款資訊
                      _buildPaymentSection(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      
                      // 訂單歷程
                      _buildHistoriesSection(),
                    ],
                  ),
                ),
              ),
    );
  }
  
  Widget _buildStatusSection() {
    // 按時間排序 histories，取最新的狀態
    final List<Map<String, dynamic>> sortedHistories = List.from(_histories)
      ..sort((a, b) => (b['date_added'] ?? '').compareTo(a['date_added'] ?? ''));
    
    final String status = sortedHistories.isNotEmpty ? sortedHistories[0]['status'] ?? '' : '';
    final statusColor = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '訂單狀態',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderInfoSection() {
    final dateAdded = _orderDetail['date_added'] ?? '';
    final dateModified = _orderDetail['date_modified'] ?? '';
    final total = _orderDetail['total'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '訂單資訊',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('訂單編號', '#${widget.orderId}'),
        _buildInfoRow('訂購日期', dateAdded),
        _buildInfoRow('最後更新', dateModified),
        _buildInfoRow('訂單金額', total),
      ],
    );
  }
  
  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '商品明細',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final product = _products[index];
            final name = _formatSpecialCharacters(product['name'] ?? '');
            final quantity = product['quantity'] ?? '';
            final price = product['price'] ?? '';
            final total = product['total'] ?? '';
            final image = product['image'] ?? '';
            
            // 解析商品選項
            final List<Map<String, String>> options = _parseProductOptions(product);
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品圖片
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                ),
                const SizedBox(width: 16),
                // 商品資訊
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 顯示商品選項
                      if (options.isNotEmpty) ...[
                        ...options.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${option['name']}: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  option['value'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '數量: $quantity',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            total,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildTotalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金額明細',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _totals.length,
          itemBuilder: (context, index) {
            final total = _totals[index];
            final title = total['title'] ?? '';
            final text = total['text'] ?? '';
            final isTotal = total['code'] == 'total';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: isTotal ? 18 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.purple : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildShippingSection() {
    final name = '${_orderDetail['shipping_firstname'] ?? ''} ${_orderDetail['shipping_lastname'] ?? ''}'.trim();
    final cellphone = _orderDetail['shipping_cellphone'] ?? '';
    // final address = _orderDetail['shipping_address_format'] ?? '';
    final address = (_orderDetail['shipping_postcode'] ?? '') + (_orderDetail['shipping_zone'] ?? '') + (_orderDetail['shipping_city'] ?? '') + (_orderDetail['shipping_address_1'] ?? '');
    final method = _orderDetail['shipping_method'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '收件資訊',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('收件人', name),
        _buildInfoRow('聯絡電話', cellphone),
        _buildInfoRow('收件地址', address),
        _buildInfoRow('配送方式', method),
      ],
    );
  }
  
  Widget _buildPaymentSection() {
    final method = _orderDetail['payment_method'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '付款資訊',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('付款方式', method),
      ],
    );
  }
  
  Widget _buildHistoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '訂單歷程',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _histories.isEmpty
          ? const Text('無訂單歷程記錄')
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _histories.length,
              itemBuilder: (context, index) {
                final history = _histories[index];
                final dateAdded = history['date_added'] ?? '';
                final status = history['status'] ?? '';
                final comment = history['comment'] ?? '';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateAdded,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                comment,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
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
  
  IconData _getStatusIcon(String status) {
    if (status.contains('待付款')) {
      return Icons.payment;
    } else if (status.contains('完成')) {
      return Icons.check_circle;
    } else if (status.contains('取消')) {
      return Icons.cancel;
    } else if (status.contains('處理中')) {
      return Icons.hourglass_empty;
    } else if (status.contains('已出貨')) {
      return Icons.local_shipping;
    } else {
      return Icons.help;
    }
  }

  String _formatSpecialCharacters(String text) {
    if (text.isEmpty) {
      return '';
    }
    
    final Map<String, String> htmlEntities = {
      '&quot;': '"',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&apos;': "'",
      '&#39;': "'",
      '&lsquo;': "'",
      '&rsquo;': "'",
      '&ldquo;': '"',
      '&rdquo;': '"',
      '&ndash;': '–',
      '&mdash;': '—',
      '&nbsp;': ' ',
      '&iexcl;': '¡',
      '&cent;': '¢',
      '&pound;': '£',
      '&curren;': '¤',
      '&yen;': '¥',
      '&brvbar;': '¦',
      '&sect;': '§',
      '&uml;': '¨',
      '&copy;': '©',
      '&ordf;': 'ª',
      '&laquo;': '«',
      '&not;': '¬',
      '&reg;': '®',
      '&macr;': '¯',
      '&deg;': '°',
      '&plusmn;': '±',
      '&sup2;': '²',
      '&sup3;': '³',
      '&acute;': '´',
      '&micro;': 'µ',
      '&para;': '¶',
      '&middot;': '·',
      '&cedil;': '¸',
      '&sup1;': '¹',
      '&ordm;': 'º',
      '&raquo;': '»',
      '&frac14;': '¼',
      '&frac12;': '½',
      '&frac34;': '¾',
      '&iquest;': '¿',
    };
    
    String result = text;
    htmlEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });
    
    return result;
  }

  // 解析商品選項
  List<Map<String, String>> _parseProductOptions(Map<String, dynamic> product) {
    List<Map<String, String>> parsedOptions = [];
    
    // 優先使用 optiondata 欄位
    if (product.containsKey('optiondata') && product['optiondata'] is List) {
      final List<dynamic> optionDataList = product['optiondata'];
      
      for (var option in optionDataList) {
        if (option is Map && option.containsKey('name') && option.containsKey('value')) {
          parsedOptions.add({
            'name': _formatSpecialCharacters(option['name'] ?? ''),
            'value': _formatSpecialCharacters(option['value'] ?? ''),
          });
        }
      }
      
      if (parsedOptions.isNotEmpty) {
        return parsedOptions;
      }
    }
    
    // 如果 optiondata 為空或解析失敗，嘗試使用 option 欄位
    if (product.containsKey('option')) {
      try {
        if (product['option'] is String) {
          final String optionStr = product['option'];
          
          if (optionStr == "[]" || optionStr.isEmpty) {
            return parsedOptions;
          }
          
          final Map<String, dynamic> optionsMap = json.decode(optionStr);
          return _processOptionsMap(product['product_id']?.toString() ?? '', optionsMap);
        } 
        else if (product['option'] is List) {
          final List<dynamic> optionsList = product['option'];
          
          for (var option in optionsList) {
            if (option is Map && option.containsKey('name') && option.containsKey('value')) {
              parsedOptions.add({
                'name': _formatSpecialCharacters(option['name'] ?? ''),
                'value': _formatSpecialCharacters(option['value'] ?? ''),
              });
            }
          }
          
          return parsedOptions;
        }
        else if (product['option'] is Map) {
          final Map<String, dynamic> optionsMap = Map<String, dynamic>.from(product['option']);
          return _processOptionsMap(product['product_id']?.toString() ?? '', optionsMap);
        }
      } catch (e) {
        debugPrint('解析選項失敗: ${e.toString()}');
      }
    }
    
    return parsedOptions;
  }
  
  // 處理選項映射
  List<Map<String, String>> _processOptionsMap(String productId, Map<String, dynamic> optionsMap) {
    List<Map<String, String>> parsedOptions = [];
    
    optionsMap.forEach((optionId, valueId) {
      parsedOptions.add({
        'name': '選項 $optionId',
        'value': valueId.toString(),
      });
    });
    
    return parsedOptions;
  }
} 