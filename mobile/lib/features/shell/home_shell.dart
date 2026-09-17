import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../alarm/alarm_controller.dart';
import '../alarm/alarm_overlay.dart';
import '../ask/ask_screen.dart';
import '../chat/chat_screen.dart';
import '../map/map_screen.dart';
import '../safety/safety_screen.dart';

/// Four destinations, always visible, always labelled.
///
/// No drawer, no nested tabs, no hidden gestures. Every screen is one tap from
/// every other — and the boundary alarm sits above all of them.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // The alarm outranks navigation. When it takes over there is exactly one
    // thing on screen and one thing to do.
    final takeOver = ref.watch(
      alarmProvider.select((alarm) => alarm.shouldTakeOverScreen),
    );

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              SafetyScreen(onAsk: () => _go(2), onOpenMap: () => _go(1)),
              const MapScreen(),
              const AskScreen(),
              const ChatScreen(),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AlarmBanner(),
              NavigationBar(
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
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Chat',
                    tooltip: 'Chat · உரையாடு',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (takeOver) const AlarmOverlay(),
      ],
    );
  }
}
