import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/providers.dart';
import 'screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _extended = false;

  @override
  void initState() {
    super.initState();
    // Ecouteur d'erreurs global
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupErrorListeners();
    });
  }

  void _setupErrorListeners() {
    final providers = [
      context.read<RoomProvider>(),
      context.read<GuestProvider>(),
      context.read<CardProvider>(),
      context.read<OperatorProvider>(),
      context.read<RecordProvider>(),
    ];

    for (final p in providers) {
      p.addListener(() {
        final error = (p as dynamic).error as String?;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.door_back_door_outlined),
      selectedIcon: Icon(Icons.door_back_door),
      label: Text('Chambres'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Clients'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.credit_card_outlined),
      selectedIcon: Icon(Icons.credit_card),
      label: Text('Cartes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.shield_outlined),
      selectedIcon: Icon(Icons.shield),
      label: Text('Opérateurs'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: Text('Journal'),
    ),
  ];

  static const _pages = [
    RoomScreen(),
    GuestScreen(),
    CardScreen(),
    OperatorScreen(),
    RecordScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── NavigationRail ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationRail(
              extended: _extended,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              destinations: _destinations,
              leading: _NavHeader(
                extended: _extended,
                onToggle: () =>
                    setState(() => _extended = !_extended),
              ),
              trailing: _NavTrailing(extended: _extended),
              backgroundColor: Colors.transparent,
              minWidth: 72,
              minExtendedWidth: 200,
            ),
          ),

          // ── Contenu principal ────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6F8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavHeader extends StatelessWidget {
  final bool extended;
  final VoidCallback onToggle;
  const _NavHeader({required this.extended, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Column(
        children: [
          // Logo + toggle
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock,
                        size: 18, color: Colors.white),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('CardLock',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text('Holiday Inn',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _NavTrailing extends StatelessWidget {
  final bool extended;
  const _NavTrailing({required this.extended});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (extended)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Enregistrement',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.3)),
                  SizedBox(height: 2),
                  Text('11/11/08',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                  Text('8D820242',
                      style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Courier',
                          color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          else
            const Icon(Icons.info_outline,
                size: 16, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}
