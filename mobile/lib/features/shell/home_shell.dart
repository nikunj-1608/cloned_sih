import 'package:flutter/material.dart';

import '../ask/ask_screen.dart';
import '../map/map_screen.dart';
import '../safety/safety_screen.dart';

/// Three destinations, always visible, always labelled.
///
/// No drawer, no nested tabs, no hidden gestures. Every screen in the app is
/// reachable in one tap from every other screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          SafetyScreen(onAsk: () => _go(2), onOpenMap: () => _go(1)),
          const MapScreen(),
          const AskScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
            tooltip: 'Home · வீடு',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
            tooltip: 'Map · வரைபடம்',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Ask',
            tooltip: 'Ask · கேளுங்கள்',
          ),
        ],
      ),
    );
  }
}
