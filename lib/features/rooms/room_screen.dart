import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/room_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'room_detail_sheet.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              PageHeader(
                title: 'Plan des chambres',
                subtitle: 'Bâtiment 1 — Holiday Inn',
                actions: [
                  // Filtre statut
                  _FilterChips(
                    current: provider.statusFilter,
                    onChanged: provider.setFilter,
                  ),
                  const SizedBox(width: 12),
                  // Bouton ajout chambre
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoom(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Stats ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'TOTAL CHAMBRES',
                      value: '${stats['total'] ?? 0}',
                      hint: '${provider.byFloor.length} étages',
                      icon: Icons.door_back_door_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'OCCUPÉES',
                      value: '${stats['occupied'] ?? 0}',
                      hint: 'Taux ${_rate(stats)}%',
                      valueColor: AppTheme.colorOccupied,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'LIBRES',
                      value: '${stats['vacant'] ?? 0}',
                      hint: 'Disponibles',
                      valueColor: AppTheme.colorVacant,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'PRIX STANDARD',
                      value: '123 DZD',
                      hint: 'Tarif / nuit',
                      icon: Icons.attach_money,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Barre de recherche ────────────────────────────────────────
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: provider.setSearch,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une chambre...',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Grille par étage ────────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.rooms.isEmpty
                        ? const EmptyState(
                            icon: Icons.door_back_door_outlined,
                            message: 'Aucune chambre trouvée',
                          )
                        : _RoomsByFloor(rooms: provider.byFloor),
              ),
            ],
          ),
        );
      },
    );
  }

  String _rate(Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    if (total == 0) return '0';
    return ((stats['occupied']! / total) * 100).round().toString();
  }

  void _showAddRoom(BuildContext context) {
    // Dialog ajout chambre — à implémenter selon besoins
    showDialog(
      context: context,
      builder: (_) => const _AddRoomDialog(),
    );
  }
}

// ─── Grille regroupée par étage ──────────────────────────────────────────────
class _RoomsByFloor extends StatelessWidget {
  final Map<int, List<RoomModel>> rooms;
  const _RoomsByFloor({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final floors = rooms.keys.toList()..sort();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: floors.map((flr) {
          final flrRooms = rooms[flr]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label étage
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.stairs_outlined,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      'Étage $flr',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Divider(height: 1),
                    ),
                  ],
                ),
              ),
              // Grille chambres
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: flrRooms.map((r) => _RoomCard(room: r)).toList(),
              ),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Carte chambre individuelle ───────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomModel room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final occ = room.isOccupied;
    final accentColor = occ ? AppTheme.colorOccupied : AppTheme.colorVacant;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openDetail(context),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
            top: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
            right: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
            bottom: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.roomNo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Icon(
                  occ ? Icons.person : Icons.hotel_outlined,
                  size: 18,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              room.sType ?? 'Standard',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            occ ? StatusBadge.occupied() : StatusBadge.vacant(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.credit_card, size: 12, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  '${room.cardCount}/${room.maxCards}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                const Spacer(),
                Text(
                  '${room.price.toInt()} DZD',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RoomDetailSheet(room: room),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;

  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Toutes'),
      ('Guest', 'Occupées'),
      ('Vacant', 'Libres'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
        final selected = current == f.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            label: Text(f.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF6B7280),
                )),
            selected: selected,
            onSelected: (_) => onChanged(f.$1),
            selectedColor:
                Theme.of(context).colorScheme.primaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.primary,
            backgroundColor: const Color(0xFFF3F4F6),
          ),
        );
      }).toList(),
      ),
    );
  }
}

// ─── Dialog ajout chambre ─────────────────────────────────────────────────────
class _AddRoomDialog extends StatefulWidget {
  const _AddRoomDialog();

  @override
  State<_AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<_AddRoomDialog> {
  final _roomNoCtrl = TextEditingController();
  final _typeCtrl   = TextEditingController(text: 'Standard');
  final _priceCtrl  = TextEditingController(text: '123');
  int _floor = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une chambre',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomNoCtrl,
              decoration: const InputDecoration(labelText: 'Numéro chambre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _typeCtrl,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix / nuit (DZD)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Étage:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _floor,
                  items: [1, 2, 3, 4, 5]
                      .map((f) => DropdownMenuItem(value: f, child: Text('$f')))
                      .toList(),
                  onChanged: (v) => setState(() => _floor = v!),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final room = RoomModel(
              bldNo: 1,
              flrNo: _floor,
              romId: _floor * 100 + (int.tryParse(_roomNoCtrl.text) ?? 0),
              roomNo: _roomNoCtrl.text.trim(),
              sType: _typeCtrl.text.trim(),
              price: double.tryParse(_priceCtrl.text) ?? 123,
            );
            context.read<RoomProvider>().addRoom(room);
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
