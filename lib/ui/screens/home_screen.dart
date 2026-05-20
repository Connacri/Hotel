import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mdb_provider.dart';
import '../widgets/crud_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MdbProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CardLock MDB — CRUD'),
        actions: [
          if (prov.selectedTable != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nouveau',
              onPressed: () => _openDialog(context, prov, null),
            ),
        ],
      ),
      body: Row(
        children: [
          // ── Sidebar tables ──────────────────────────
          SizedBox(
            width: 200,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: prov.loading && prov.tables.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: prov.tables.length,
                itemBuilder: (ctx, i) {
                  final t = prov.tables[i];
                  return ListTile(
                    title: Text(t, style: const TextStyle(fontSize: 13)),
                    selected: prov.selectedTable == t,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                    onTap: () => prov.selectTable(t),
                  );
                },
              ),
            ),
          ),

          // ── Data grid ──────────────────────────────
          Expanded(
            child: Column(
              children: [
                if (prov.error != null)
                  MaterialBanner(
                    content: Text(prov.error!),
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    actions: [
                      TextButton(onPressed: () {}, child: const Text('OK'))
                    ],
                  ),
                if (prov.loading)
                  const LinearProgressIndicator(),
                if (prov.selectedTable != null && prov.columns.isNotEmpty)
                  Expanded(child: _DataGrid(prov: prov)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDialog(BuildContext context, MdbProvider prov, Map<String, String>? existing) {
    showDialog(
      context: context,
      builder: (_) => CrudDialog(
        columns: prov.columns,
        existing: existing,
        pkColumn: prov.pkColumn,
        onSave: (data) {
          if (existing == null) {
            prov.insert(data);
          } else {
            prov.update(existing[prov.pkColumn] ?? '', data);
          }
        },
        onDelete: existing == null ? null : () {
          prov.delete(existing[prov.pkColumn] ?? '');
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── DataGrid interne ─────────────────────────────────────────
class _DataGrid extends StatelessWidget {
  final MdbProvider prov;
  const _DataGrid({required this.prov});

  @override
  Widget build(BuildContext context) {
    final cols = prov.columns.map((c) => c['name']!).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          columns: [
            ...cols.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))),
            const DataColumn(label: Text('Actions')),
          ],
          rows: prov.rows.map((row) {
            return DataRow(cells: [
              ...cols.map((c) => DataCell(Text(row[c] ?? ''))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _edit(context, row),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _confirmDelete(context, row),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _edit(BuildContext context, Map<String, String> row) {
    final screen = context.findAncestorWidgetOfExactType<HomeScreen>();
    // ignore: use_build_context_synchronously
    (context as Element).visitAncestorElements((el) {
      if (el.widget is HomeScreen) return false;
      return true;
    });
    showDialog(
      context: context,
      builder: (_) => CrudDialog(
        columns: prov.columns,
        existing: row,
        pkColumn: prov.pkColumn,
        onSave: (data) => prov.update(row[prov.pkColumn] ?? '', data),
        onDelete: () { prov.delete(row[prov.pkColumn] ?? ''); Navigator.pop(context); },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, String> row) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer la ligne ${row[prov.pkColumn]} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () { prov.delete(row[prov.pkColumn] ?? ''); Navigator.pop(context); },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}