import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addToCart(Map<String, dynamic> product) {
    if (product['dis_price'] == 1) {
      return;
    }
    _items.add(product);
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> product) {
    _items.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get total {
    return _items.fold(0, (sum, item) {
      if (item['dis_price'] == 1) {
        return sum;
      }
      final price = item['special'] != null && item['special'] != false
          ? double.parse(item['special'].toString())
          : double.parse(item['price'].toString());
      return sum + price;
    });
  }
} 