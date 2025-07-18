import 'package:flutter/material.dart';
import 'screens/simple_text_converter_screen.dart';
import 'screens/markdown_list_screen.dart';
import 'screens/obsidian_settings_screen.dart';
import 'screens/debug_log_screen.dart';

void main() {
  runApp(const MemoriaTraceApp());
}

class MemoriaTraceApp extends StatelessWidget {
  const MemoriaTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoriaTrace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SimpleTextConverterScreen(),
    const MarkdownListScreen(),
    const ObsidianSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('MemoriaTrace'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugLogScreen(),
                      ),
                    );
                  },
                  tooltip: '디버그 로그',
                ),
              ],
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.transform), label: '텍스트 변환'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '변환 목록'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
