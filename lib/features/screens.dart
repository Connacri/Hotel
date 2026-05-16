// ─────────────────────────────────────────────────────────────────────────────
// card_screen.dart  |  operator_screen.dart  |  record_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/models.dart';
import '../core/providers/providers.dart';
import '../core/theme/app_theme.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CardProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        final cards = provider.cards;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Cartes magnétiques',
                subtitle: '${stats['total'] ?? 0} cartes enregistrées — CardInfo',
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'TOTAL CARTES',
                      value: '${stats['total'] ?? 0}',
                      icon: Icons.credit_card,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'ACTIVES',
                      value: '${stats['active'] ?? 0}',
                      valueColor: AppTheme.colorCard,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'EFFACÉES',
                      value: '${stats['erased'] ?? 0}',
                      valueColor: AppTheme.colorErased,
                      icon: Icons.do_not_disturb_alt_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Table
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : cards.isEmpty
                        ? const EmptyState(
                            icon: Icons.credit_card_off,
                            message: 'Aucune carte')
                        : SectionCard(
                            padding: EdgeInsets.zero,
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('TITULAIRE')),
                                    DataColumn(label: Text('OPÉRATEUR')),
                                    DataColumn(label: Text('DONNÉES SERRURE')),
                                    DataColumn(label: Text('STATUT')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: cards.map((c) {
                                    return DataRow(cells: [
                                      DataCell(Text('#${c.id}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9CA3AF)))),
                                      DataCell(Text(
                                        c.holder?.isNotEmpty == true
                                            ? c.holder!
                                            : '—',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      )),
                                      DataCell(Text(c.gongHao ?? '—',
                                          style: const TextStyle(
                                              fontSize: 12))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            c.shortData,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Courier',
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(c.isErased
                                          ? StatusBadge.erased()
                                          : c.isCheckIn
                                              ? StatusBadge.card()
                                              : StatusBadge.vacant()),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!c.isErased)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.do_not_disturb_alt_outlined,
                                                  size: 16,
                                                  color: Color(0xFF6B7280)),
                                              onPressed: () =>
                                                  provider.eraseCard(c.id!),
                                              tooltip: 'Effacer la carte',
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                size: 16,
                                                color: Color(0xFFE24B4A)),
                                            onPressed: () =>
                                                provider.deleteCard(c.id!),
                                            tooltip: 'Supprimer',
                                          ),
                                        ],
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// operator_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperatorProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OperatorProvider>(
      builder: (context, provider, _) {
        final ops = provider.operators;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Opérateurs & permissions',
                subtitle: '${ops.length} comptes — OperatorInfo',
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddOperator(context),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ops.isEmpty
                        ? const EmptyState(
                            icon: Icons.manage_accounts_outlined,
                            message: 'Aucun opérateur')
                        : SectionCard(
                            child: ListView.separated(
                              itemCount: ops.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) =>
                                  _OperatorTile(op: ops[i]),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOperator(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddOperatorDialog(),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  final OperatorModel op;
  const _OperatorTile({required this.op});

  // Couleur avatar selon le rôle
  Color get _avatarBg {
    if (op.gongHao.contains('Super')) return AppTheme.colorOccupiedLight;
    if (op.gongHao.contains('Admin')) return AppTheme.colorCardLight;
    if (op.gongHao.contains('Manager')) return AppTheme.colorVacantLight;
    return AppTheme.colorErasedLight;
  }

  Color get _avatarFg {
    if (op.gongHao.contains('Super')) return AppTheme.colorOccupied;
    if (op.gongHao.contains('Admin')) return AppTheme.colorCard;
    if (op.gongHao.contains('Manager')) return AppTheme.colorVacant;
    return AppTheme.colorErased;
  }

  @override
  Widget build(BuildContext context) {
    final perm = op.permissionLevel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _avatarBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(op.initials,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _avatarFg)),
            ),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(op.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(op.roleLabel,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(op.gongHao,
                    style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                        color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                // Barre de permissions
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: perm,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: _avatarFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(perm * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 18, color: Color(0xFF6B7280)),
            onSelected: (action) =>
                _handleAction(context, action),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'password',
                  child: Text('Changer le mot de passe')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer',
                      style: TextStyle(color: AppTheme.colorOccupied))),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    final provider = context.read<OperatorProvider>();
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer cet opérateur ?'),
          content: Text('${op.name} (${op.gongHao})'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                provider.deleteOperator(op.gongHao);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorOccupied),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
    } else if (action == 'password') {
      final ctrl = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nouveau mot de passe'),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Mot de passe'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                provider.updatePassword(op.gongHao, ctrl.text);
                Navigator.pop(context);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
    }
  }
}

class _AddOperatorDialog extends StatefulWidget {
  const _AddOperatorDialog();

  @override
  State<_AddOperatorDialog> createState() => _AddOperatorDialogState();
}

class _AddOperatorDialogState extends State<_AddOperatorDialog> {
  final _idCtrl   = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un opérateur',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idCtrl,
              decoration:
                  const InputDecoration(labelText: 'Identifiant (GongHao)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Mot de passe'),
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
            final op = OperatorModel(
              gongHao: _idCtrl.text.trim(),
              name: _nameCtrl.text.trim(),
              miMa: _passCtrl.text,
            );
            context.read<OperatorProvider>().addOperator(op);
            Navigator.pop(context);
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// record_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordProvider>(
      builder: (context, provider, _) {
        final records = provider.records;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: "Journal d'ouvertures",
                subtitle: '${records.length} événements — RecordOpen',
                actions: [
                  Row(
                    children: [
                      const Text('Portes uniquement',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280))),
                      const SizedBox(width: 8),
                      Switch(
                        value: provider.doorOnly,
                        onChanged: (_) => provider.toggleDoorOnly(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : records.isEmpty
                        ? const EmptyState(
                            icon: Icons.history_toggle_off,
                            message: 'Aucun événement')
                        : SectionCard(
                            padding: EdgeInsets.zero,
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('#')),
                                    DataColumn(label: Text('FLAG')),
                                    DataColumn(label: Text('DONNÉES SERRURE (HEX)')),
                                    DataColumn(label: Text('HORODATAGE')),
                                    DataColumn(label: Text('TYPE')),
                                  ],
                                  rows: records.map((r) {
                                    Color badgeColor;
                                    Color badgeBg;
                                    if (r.isDoorOpen) {
                                      badgeColor = AppTheme.colorOccupied;
                                      badgeBg = AppTheme.colorOccupiedLight;
                                    } else if (r.isSystemConfig) {
                                      badgeColor = AppTheme.colorCard;
                                      badgeBg = AppTheme.colorCardLight;
                                    } else {
                                      badgeColor = AppTheme.colorErased;
                                      badgeBg = AppTheme.colorErasedLight;
                                    }

                                    return DataRow(cells: [
                                      DataCell(Text('${r.id}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9CA3AF)))),
                                      DataCell(Text('${r.orderFlag}',
                                          style: const TextStyle(
                                              fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            r.recData ?? '—',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'Courier'),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(r.openTime ?? '—',
                                          style: const TextStyle(
                                              fontSize: 12))),
                                      DataCell(StatusBadge(
                                        label: r.typeLabel,
                                        bg: badgeBg,
                                        fg: badgeColor,
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
