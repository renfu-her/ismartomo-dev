import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';

class InformationPage extends StatefulWidget {
  final String informationId;
  final String title;

  const InformationPage({
    super.key,
    required this.informationId,
    required this.title,
  });

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _informationData = {};

  @override
  void initState() {
    super.initState();
    _fetchInformationData();
  }

  Future<void> _fetchInformationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getInformationById(widget.informationId);
      
      setState(() {
        _isLoading = false;
        
        if (response.containsKey('informations') && 
            response['informations'] is List && 
            response['informations'].isNotEmpty) {
          _informationData = response['informations'][0];
        } else {
          _errorMessage = '無法獲取資訊內容';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取資訊失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
              onPressed: _fetchInformationData,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_informationData.isEmpty) {
      return const Center(
        child: Text('沒有找到資訊內容'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Text(
              _informationData['title'] ?? '無標題',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 內容 (HTML 格式)
            if (_informationData['description'] != null)
              Html(
                data: _informationData['description'],
                style: {
                  "body": Style(
                    fontSize: FontSize(16),
                    lineHeight: LineHeight(1.5),
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 16),
                  ),
                  "a": Style(
                    color: Colors.blue,
                    textDecoration: TextDecoration.underline,
                  ),
                  "img": Style(
                    width: Width(MediaQuery.of(context).size.width - 48, Unit.px),
                    margin: Margins.only(left: 0, right: 16),
                    alignment: Alignment.centerLeft,
                  ),
                },
              ),
          ],
        ),
      ),
    );
  }
}

class InformationListPage extends StatefulWidget {
  const InformationListPage({super.key});

  @override
  State<InformationListPage> createState() => _InformationListPageState();
}

class _InformationListPageState extends State<InformationListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _informationList = [];

  @override
  void initState() {
    super.initState();
    _fetchInformationList();
  }

  Future<void> _fetchInformationList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getAllInformation();
      
      setState(() {
        _isLoading = false;
        
        if (response.containsKey('informations') && 
            response['informations'] is List) {
          _informationList = List<Map<String, dynamic>>.from(response['informations']);
        } else {
          _errorMessage = '無法獲取資訊列表';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '獲取資訊列表失敗: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('資訊中心'),
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
              onPressed: _fetchInformationList,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_informationList.isEmpty) {
      return const Center(
        child: Text('沒有找到資訊內容'),
      );
    }

    return ListView.separated(
      itemCount: _informationList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final information = _informationList[index];
        return ListTile(
          title: Text(information['title'] ?? '無標題'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => InformationPage(
                  informationId: information['information_id'],
                  title: information['title'] ?? '資訊詳情',
                ),
              ),
            );
          },
        );
      },
    );
  }
} 