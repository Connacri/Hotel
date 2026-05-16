import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/room_model.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class RoomDetailSheet extends StatelessWidget {
  final RoomModel room;
  const RoomDetailSheet({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final occ = room.isOccupied;
    final guests = context.read<GuestProvider>().getByRoom('1-${room.roomNo}');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ListView(
          controller: scrollCtrl,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Titre + badge statut
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: occ
                        ? AppTheme.colorOccupiedLight
                        : AppTheme.colorVacantLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    occ ? Icons.person : Icons.hotel_outlined,
                    color: occ ? AppTheme.colorOccupied : AppTheme.colorVacant,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chambre ${room.roomNo}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      room.sType ?? 'Standard',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const Spacer(),
                occ ? StatusBadge.occupied() : StatusBadge.vacant(),
              ],
            ),
            const SizedBox(height: 24),

            // Infos chambre
            _InfoGrid(room: room),
            const SizedBox(height: 20),

            // Section client actif
            if (occ && guests.isNotEmpty) ...[
              const Text(
                'Client actif',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ...guests.map((g) => _GuestTile(guest: g)),
              const SizedBox(height: 20),
            ],

            // Actions
            _ActionButtons(room: room),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final RoomModel room;
  const _InfoGrid({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          _InfoRow('Étage', 'Étage ${room.flrNo}'),
          _InfoRow('Bâtiment', '${room.bldNo}'),
          _InfoRow('ROM ID', '${room.romId}'),
          _InfoRow('Prix / nuit', '${room.price.toInt()} DZD'),
          _InfoRow(
            'Cartes actives',
            '${room.cardCount} / ${room.maxCards}',
          ),
          if (room.firstCkOut != null && room.firstCkOut!.isNotEmpty)
            _InfoRow('Check-out prévu', room.firstCkOut!),
          if (room.beiZhu != null && room.beiZhu!.isNotEmpty)
            _InfoRow('Note', room.beiZhu!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  final GuestModel guest;
  const _GuestTile({required this.guest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.colorCardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppTheme.colorCard),
              const SizedBox(width: 6),
              Text(guest.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          if (guest.cardId != null)
            Row(
              children: [
                const Icon(Icons.credit_card,
                    size: 13, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(guest.cardId!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                        color: Color(0xFF374151))),
              ],
            ),
          if (guest.comeTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.login, size: 13, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(guest.comeTime!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(width: 12),
                const Icon(Icons.logout,
                    size: 13, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(guest.goTime ?? '—',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${guest.price.toStringAsFixed(0)} DZD',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.colorCard),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final RoomModel room;
  const _ActionButtons({required this.room});

  @override
  Widget build(BuildContext context) {
    final occ = room.isOccupied;
    final roomProvider = context.read<RoomProvider>();

    return Row(
      children: [
        if (!occ)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                roomProvider.checkIn(room.id!);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Check-In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorVacant,
              ),
            ),
          ),
        if (occ)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                roomProvider.checkOut(room.id!);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Check-Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorOccupied,
              ),
            ),
          ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, roomProvider),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Supprimer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, RoomProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Supprimer la chambre ${room.roomNo} ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              provider.deleteRoom(room.id!);
              Navigator.pop(context);
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
