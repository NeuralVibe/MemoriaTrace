import 'package:flutter/material.dart';
import 'screens/simple_voice_converter_screen.dart';
import 'screens/markdown_list_screen_simple.dart';
import 'screens/obsidian_settings_screen_simple.dart';

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
    const SimpleVoiceConverterScreen(),
    const MarkdownListScreen(),
    const ObsidianSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.transform), label: '파일 변환'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '변환 목록'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
