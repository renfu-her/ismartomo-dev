import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
      ),
    );
  }
} 