import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

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
                  OutlinedButton.icon(
                    onPressed: () => _handleImport(context),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Importer MDB'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOperator(context),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Consumer<MigrationProvider>(
                builder: (context, mig, _) {
                  if (mig.isMigrating) {
                    return SectionCard(
                      child: Column(
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(mig.status ?? 'Migration en cours...',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ops.isEmpty
                        ? const EmptyState(
                            icon: Icons.manage_accounts_outlined,
                            message: 'Aucun opérateur')
                        : SectionCard(
                            flex: true,
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

  Future<void> _handleImport(BuildContext context) async {
    final migration = context.read<MigrationProvider>();
    final success = await migration.importMdb(context);

    if (success) {
      // Recharger toutes les données
      if (mounted) {
        context.read<RoomProvider>().load();
        context.read<GuestProvider>().load();
        context.read<CardProvider>().load();
        context.read<OperatorProvider>().load();
        context.read<RecordProvider>().load();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration terminée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (migration.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(migration.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
