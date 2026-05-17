import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

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
                            flex: true,
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
