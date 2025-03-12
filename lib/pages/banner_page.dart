import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../main.dart'; // 導入 TextSizeConfig

class BannerPage extends StatefulWidget {
  const BannerPage({super.key});

  @override
  State<BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  
  List<Map<String, dynamic>> _homeTopBanners = [];
  List<Map<String, dynamic>> _homeTopRightBanners = [];
  List<Map<String, dynamic>> _homeFullBanners = [];

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getHomeBanners();
      
      setState(() {
        _isLoading = false;
        
        // 解析不同類型的橫幅
        if (response.containsKey('home_top_banner') && response['home_top_banner'] is List) {
          _homeTopBanners = List<Map<String, dynamic>>.from(response['home_top_banner']);
        }
        
        if (response.containsKey('home_top_right_banner') && response['home_top_right_banner'] is List) {
          _homeTopRightBanners = List<Map<String, dynamic>>.from(response['home_top_right_banner']);
        }
        
        if (response.containsKey('home_full_banner') && response['home_full_banner'] is List) {
          _homeFullBanners = List<Map<String, dynamic>>.from(response['home_full_banner']);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取橫幅數據失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首頁橫幅'),
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
              onPressed: _fetchBanners,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBanners,
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 全幅橫幅輪播
              if (_homeFullBanners.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '全幅橫幅',
                    style: TextStyle(
                      fontSize: TextSizeConfig.calculateTextSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200.0,
                    aspectRatio: 16/9,
                    viewportFraction: 0.9,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    reverse: false,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enlargeCenterPage: true,
                    scrollDirection: Axis.horizontal,
                  ),
                  items: _homeFullBanners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                          onTap: () {
                            if (banner['link'] != null && banner['link'].toString().isNotEmpty) {
                              // 這裡可以添加打開鏈接的功能
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('打開鏈接: ${banner['link']}')),
                              );
                            }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Stack(
                                children: [
                                  Image.network(
                                    banner['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.image_not_supported, size: 50),
                                      );
                                    },
                                  ),
                                  if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          banner['title'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: TextSizeConfig.calculateTextSize(16),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // 頂部橫幅
              if (_homeTopBanners.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '頂部橫幅',
                    style: TextStyle(
                      fontSize: TextSizeConfig.calculateTextSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildBannerGrid(_homeTopBanners),
              ],
              
              const SizedBox(height: 20),
              
              // 頂部右側橫幅
              if (_homeTopRightBanners.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '頂部右側橫幅',
                    style: TextStyle(
                      fontSize: TextSizeConfig.calculateTextSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildBannerGrid(_homeTopRightBanners),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBannerGrid(List<Map<String, dynamic>> banners) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        final banner = banners[index];
        return GestureDetector(
          onTap: () {
            if (banner['link'] != null && banner['link'].toString().isNotEmpty) {
              // 這裡可以添加打開鏈接的功能
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('打開鏈接: ${banner['link']}')),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Stack(
                children: [
                  Image.network(
                    banner['image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 30),
                      );
                    },
                  ),
                  if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          banner['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: TextSizeConfig.calculateTextSize(12),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 