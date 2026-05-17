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
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Erreur: ${provider.error}'),
                ElevatedButton(
                  onPressed: () => provider.load(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

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

// ─── Grille regroupée par étage (Lazy) ───────────────────────────────────────
class _RoomsByFloor extends StatelessWidget {
  final Map<int, List<RoomModel>> rooms;
  const _RoomsByFloor({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final floors = rooms.keys.toList()..sort();
    
    return ListView.builder(
      itemCount: floors.length,
      padding: const EdgeInsets.only(bottom: 40),
      itemBuilder: (context, index) {
        final flr = floors[index];
        final flrRooms = rooms[flr]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label étage
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 20),
              child: Row(
                children: [
                  const Icon(Icons.stairs_outlined,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Text(
                    'Étage $flr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Divider(height: 1)),
                  const SizedBox(width: 12),
                  Text(
                    '${flrRooms.length} chambres',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            // Grille chambres optimisée (Lazy & Fixe)
            LayoutBuilder(
              builder: (context, constraints) {
                // Largeur idéale d'une carte : 190px
                const idealWidth = 190.0;
                final spacing = 12.0;
                
                // Calculer le nombre de colonnes pour remplir l'espace
                int crossAxisCount = (constraints.maxWidth / (idealWidth + spacing)).floor();
                crossAxisCount = crossAxisCount.clamp(1, 10);
                
                return GridView.builder(
                  key: PageStorageKey('floor-$flr'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: 155, // Hauteur strictement identique pour toutes les cartes
                  ),
                  itemCount: flrRooms.length,
                  itemBuilder: (context, rIndex) {
                    final room = flrRooms[rIndex];
                    return _RoomCard(
                      key: ValueKey('room-${room.romId}-${room.roomNo}'),
                      room: room,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ─── Carte chambre individuelle ───────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomModel room;
  const _RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final occ = room.isOccupied;
    final accentColor = occ ? AppTheme.colorOccupied : AppTheme.colorVacant;
    final roomKey = '${room.bldNo}-${room.roomNo}';
    final guests = context.watch<GuestProvider>().getGuestsForRoom(roomKey);
    final guest = guests.isNotEmpty ? guests.first : null;
    final roomLabel = room.roomNo.isEmpty ? 'ID ${room.romId}' : room.roomNo;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDetail(context),
        child: Container(
          // On retire la largeur fixe car le GridView la gère
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      roomLabel,
                      style: const TextStyle(
                        fontSize: 16, // Légèrement réduit pour éviter l'overflow
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    occ ? Icons.person : Icons.hotel_outlined,
                    size: 14,
                    color: accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                (room.sType?.isEmpty ?? true) ? 'Standard' : room.sType!,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              occ ? StatusBadge.occupied() : StatusBadge.vacant(),
              
              const Spacer(),

              // Zone d'information (hauteur fixe pour l'alignement)
              SizedBox(
                height: 32,
                child: occ 
                  ? (guest != null 
                      ? Row(
                          children: [
                            const Icon(Icons.account_circle_outlined, size: 12, color: Color(0xFF4B5563)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                guest.name.isEmpty ? 'Client inconnu' : guest.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Non lié',
                              style: TextStyle(fontSize: 10, color: Colors.orange, fontStyle: FontStyle.italic),
                            ),
                          ],
                        )
                    )
                  : const SizedBox.shrink(),
              ),

              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.credit_card, size: 11, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    '${room.cardCount}/${room.maxCards}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  ),
                  const Spacer(),
                  Text(
                    '${room.price.toInt()} DZD',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
