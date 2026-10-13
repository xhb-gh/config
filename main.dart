import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screen_overlay/flutter_screen_overlay.dart';
import 'package:http/http.dart' as http;

// ===== 1. 配置你的参数 =====
const String BASE = "https://fuyao.aicubes.cn";
const String API_KEY = "sk-fuyao-XTX_7yAlI-CNOt32mOgk_NumkycLjkkV"; // 替换这里
const double OVERLAY_FONT_SIZE = 13; // ← 新增

List<String> _codes = [];
final Map<String, String> _nameCache = {}; //名称缓存

Future<void> _loadStocks() async {
  try {
    final resp = await http.get(
      Uri.parse('https://www.livehome.publicvm.com/stocks'),
    );
    debugPrint('自选股接口状态码: ${resp.statusCode}');
    debugPrint('自选股接口响应: ${resp.body}'); // ← 加这行
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['code'] == 0) {
        final map = (data['data'] as Map).cast<String, dynamic>();
        debugPrint('自选股接口 keys: ${map.keys.toList()}');
        _codes = map.keys.toList();
        _nameCache.clear();
        map.forEach((k, v) => _nameCache[k] = v.toString());
      }
    }
  } catch (e) {
    debugPrint('获取自选股失败: $e');
  }
}

// ===== 2. 悬浮窗入口（必须放在外面） =====
@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWatchWidget(),
    ),
  );
}

// ===== 3. 悬浮窗里的内容 =====
class OverlayWatchWidget extends StatefulWidget {
  const OverlayWatchWidget({super.key});
  @override
  State<OverlayWatchWidget> createState() => _OverlayWatchWidgetState();
}

class _OverlayWatchWidgetState extends State<OverlayWatchWidget> {
  List<Map<String, dynamic>> _stocks = [];
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadStocks();
    _startPolling();
    _tick(); // 立即拉一次，不用等 3 秒
  }

  void _startPolling() {
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer = Timer(const Duration(seconds: 2), () async {
      await _tick();
      if (mounted) _scheduleNext();   // 跑完再排下一次
    });
  }

  Future<void> _tick() async {
    if (_codes.isEmpty) return; // 没有自选股就不请求
    try {
      final url = Uri.parse(
        '$BASE/api/a-share/prices/snapshot?thscodes=${_codes.join(",")}',
      );
      final resp = await http.get(url, headers: {"X-api-key": API_KEY});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['code'] == 0 && data['data'] != null) {
          final items = (data['data']['item'] as List).cast<Map<String, dynamic>>();

          if (!mounted) return;
          setState(() {
            _stocks = items;
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('请求行情失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        // padding: const EdgeInsets.only(top: 4, right: 6, bottom: 4, left: 6),
        child: _loading
            ? const Text(
                '加载中...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _stocks.map((s) {
                    final pct =
                        (s['price_change_ratio_pct'] as num?)?.toDouble() ?? 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${_nameCache[s['thscode']] ?? s['ticker']}  ',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: OVERLAY_FONT_SIZE,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: pct >= 0 ? Colors.red : Colors.green,
                              fontSize: OVERLAY_FONT_SIZE,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ===== 4. 主界面（用于启动悬浮窗） =====
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('悬浮窗盯盘')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final hasPermission =
                    await FlutterScreenOverlay.isPermissionGranted();
                if (!hasPermission) {
                  await FlutterScreenOverlay.requestPermission();
                  return;
                }
                await FlutterScreenOverlay.showOverlay(
                  height: 385,
                  width: 345,
                  alignment: OverlayAlignment.bottomLeft,
                  startPosition: OverlayPosition(2, 55),
                  enableDrag: false,
                );
              },
              child: const Text('启动悬浮窗'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                await FlutterScreenOverlay.closeOverlay();
              },
              child: const Text('关闭悬浮窗'),
            ),
          ],
        ),
      ),
    );
  }
}
