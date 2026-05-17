import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

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
                            flex: true,
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
