import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screen_overlay/flutter_screen_overlay.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

const String _kSpotFile = 'overlay_spot.txt';

Future<void> _saveSpotIndex(int index) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_kSpotFile');
    await file.writeAsString('$index');
    debugPrint('位置已写入文件: $index');
  } catch (e) {
    debugPrint('写位置文件失败: $e');
  }
}

Future<int> _readSpotIndex() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_kSpotFile');
    if (await file.exists()) {
      final s = await file.readAsString();
      return int.tryParse(s.trim()) ?? 0;
    }
  } catch (e) {
    debugPrint('读位置文件失败: $e');
  }
  return 0;
}

// ===== 1. 配置你的参数 =====
const String BASE = "https://fuyao.aicubes.cn";
const String API_KEY = "sk-fuyao-XTX_7yAlI-CNOt32mOgk_NumkycLjkkV"; // 替换这里
const double OVERLAY_FONT_SIZE = 13;

// 保存位置的 key
const String _kSpotIndexKey = 'overlay_spot_index';

List<String> _codes = [];
final Map<String, String> _nameCache = {};

Future<void> _getStocks() async {
  try {
    final resp = await http.get(
      Uri.parse('https://www.livehome.publicvm.com/stocks'),
    );
    debugPrint('自选股接口状态码: ${resp.statusCode}');
    debugPrint('自选股接口响应: ${resp.body}');
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

// 清除所有缓存数据
void _clearStockData() {
  _codes = [];
  _nameCache.clear();
}

// ===== 2. 悬浮窗位置循环 =====
class _OverlaySpot {
  final OverlayAlignment alignment;
  final OverlayPosition position;
  const _OverlaySpot(this.alignment, this.position);
}

const List<_OverlaySpot> _kSpots = [
  _OverlaySpot(OverlayAlignment.bottomLeft, OverlayPosition(2, 55)),
  _OverlaySpot(OverlayAlignment.topRight, OverlayPosition(2, 55)),
  _OverlaySpot(OverlayAlignment.topLeft, OverlayPosition(2, 55)),
  _OverlaySpot(OverlayAlignment.centerRight, OverlayPosition(2, 0)),
  _OverlaySpot(OverlayAlignment.centerLeft, OverlayPosition(2, 0)),
  _OverlaySpot(OverlayAlignment.bottomRight, OverlayPosition(2, 55)),
];

int _spotIndex = 0;

const int OVERLAY_W = 353;
const int OVERLAY_H = 385;

// ===== 3. 悬浮窗入口 =====
@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWatchWidget(),
    ),
  );
}

// ===== 4. 悬浮窗里的内容 =====
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
    await _getStocks();
    _startPolling();
    _tick();
  }

  void _startPolling() {
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer = Timer(const Duration(seconds: 2), () async {
      await _tick();
      if (mounted) _scheduleNext();
    });
  }

  Future<void> _tick() async {
    if (_codes.isEmpty) return;
    try {
      final url = Uri.parse(
        '$BASE/api/a-share/prices/snapshot?thscodes=${_codes.join(",")}',
      );
      final resp = await http.get(url, headers: {"X-api-key": API_KEY});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['code'] == 0 && data['data'] != null) {
          final items =
          (data['data']['item'] as List).cast<Map<String, dynamic>>();

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

  // ===== 双击切换位置 =====
  Future<void> _onDoubleTap() async {
    _spotIndex = (_spotIndex + 1) % _kSpots.length;

    // 保存当前位置到文件
    await _saveSpotIndex(_spotIndex);
    debugPrint('位置已保存: $_spotIndex');

    final spot = _kSpots[_spotIndex];

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_kSpotFile';
    debugPrint('悬浮窗Engine 写入路径: $path');

    // 关闭当前悬浮窗，在新位置重新打开
    await FlutterScreenOverlay.closeOverlay();
    await Future.delayed(const Duration(milliseconds: 200));

    await FlutterScreenOverlay.showOverlay(
      height: OVERLAY_H,
      width: OVERLAY_W,
      alignment: spot.alignment,
      startPosition: spot.position,
      enableDrag: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _onDoubleTap,
      child: Material(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
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
                    (s['price_change_ratio_pct'] as num?)?.toDouble() ??
                        0;
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
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ===== 5. 主界面 =====
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

                // 从文件读取上次保存的位置
                _spotIndex = await _readSpotIndex();
                debugPrint('主App实际读到位置: $_spotIndex');
                if (_spotIndex < 0 || _spotIndex >= _kSpots.length) {
                  _spotIndex = 0;
                }

                final dir = await getApplicationDocumentsDirectory();
                final path = '${dir.path}/$_kSpotFile';
                debugPrint('悬浮窗Engine 读取路径: $path');

                if (_spotIndex < 0 || _spotIndex >= _kSpots.length) {
                  _spotIndex = 0;
                }

                final spot = _kSpots[_spotIndex];
                await FlutterScreenOverlay.showOverlay(
                  height: OVERLAY_H,
                  width: OVERLAY_W,
                  alignment: spot.alignment,
                  startPosition: spot.position,
                  enableDrag: false,
                );
              },
              child: const Text('启动悬浮窗'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                // 先保存当前位置
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(_kSpotIndexKey, _spotIndex);

                await FlutterScreenOverlay.closeOverlay();
                // 清除数据
                _clearStockData();
              },
              child: const Text('关闭悬浮窗'),
            ),
          ],
        ),
      ),
    );
  }
}