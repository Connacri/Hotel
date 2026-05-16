import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuestProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuestProvider>(
      builder: (context, provider, _) {
        final guests = provider.guests;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              PageHeader(
                title: 'Séjours clients',
                subtitle: '${guests.length} enregistrements — GuestInfo',
                actions: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: provider.setSearch,
                      decoration: const InputDecoration(
                        hintText: 'Nom, chambre, carte...',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGuest(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nouveau séjour'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Table ─────────────────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : guests.isEmpty
                        ? const EmptyState(
                            icon: Icons.person_search,
                            message: 'Aucun séjour trouvé',
                          )
                        : SectionCard(
                            padding: EdgeInsets.zero,
                            child: _GuestTable(guests: guests),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddGuest(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddGuestDialog(),
    );
  }
}

// ─── Table principale ─────────────────────────────────────────────────────────
class _GuestTable extends StatelessWidget {
  final List<GuestModel> guests;
  const _GuestTable({required this.guests});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('CHAMBRE')),
            DataColumn(label: Text('CLIENT')),
            DataColumn(label: Text('CARTE ID')),
            DataColumn(label: Text('CHECK-IN')),
            DataColumn(label: Text('CHECK-OUT')),
            DataColumn(label: Text('PRIX'), numeric: true),
            DataColumn(label: Text('STATUT')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: guests.map((g) => _buildRow(context, g)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, GuestModel g) {
    final isHighPrice = g.price > 10000;
    return DataRow(
      cells: [
        DataCell(Text('#${g.id}',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(g.bldRoomNo,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        DataCell(Text(g.name,
            style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(
          g.cardId ?? '—',
          style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              color: Color(0xFF374151)),
        )),
        DataCell(Text(g.comeTime ?? '—',
            style: const TextStyle(fontSize: 12))),
        DataCell(Text(g.goTime ?? '—',
            style: const TextStyle(fontSize: 12))),
        DataCell(Text(
          '${g.price.toStringAsFixed(0)} DZD',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isHighPrice
                ? AppTheme.colorOccupied
                : const Color(0xFF111827),
          ),
        )),
        DataCell(StatusBadge.occupied()),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.logout_outlined,
                    size: 16, color: Color(0xFF6B7280)),
                onPressed: () => _checkOut(context, g),
                tooltip: 'Check-out',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: Color(0xFFE24B4A)),
                onPressed: () => _delete(context, g),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _checkOut(BuildContext context, GuestModel g) {
    final now = DateTime.now();
    final formatted =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year.toString().substring(2)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    context.read<GuestProvider>().checkOut(g.id!, formatted);
  }

  void _delete(BuildContext context, GuestModel g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce séjour ?'),
        content: Text('Client : ${g.name}\nChambre : ${g.bldRoomNo}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              context.read<GuestProvider>().deleteGuest(g.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorOccupied),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog ajout séjour ──────────────────────────────────────────────────────
class _AddGuestDialog extends StatefulWidget {
  const _AddGuestDialog();

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  final _nameCtrl   = TextEditingController();
  final _roomCtrl   = TextEditingController();
  final _cardCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController(text: '123');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau séjour',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du client'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomCtrl,
              decoration:
                  const InputDecoration(labelText: 'Chambre (ex: 1-101)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cardCtrl,
              decoration: const InputDecoration(labelText: 'ID Carte'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix (DZD)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            final now = DateTime.now();
            final formatted =
                '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year.toString().substring(2)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
            final guest = GuestModel(
              bldRoomNo: _roomCtrl.text.trim(),
              name: _nameCtrl.text.trim(),
              cardId: _cardCtrl.text.trim(),
              comeTime: formatted,
              flag: 'WalkIn',
              price: double.tryParse(_priceCtrl.text) ?? 123,
            );
            context.read<GuestProvider>().addGuest(guest);
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
