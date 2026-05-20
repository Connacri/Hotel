import 'package:flutter/material.dart';

class MdbCrudDialog extends StatefulWidget {
  final List<Map<String, String>> columns;
  final Map<String, String>?      existing;
  final String?                   pkColumn;
  final void Function(Map<String, String>) onSave;
  final VoidCallback?             onDelete;

  const MdbCrudDialog({
    super.key,
    required this.columns,
    required this.onSave,
    this.existing,
    this.pkColumn,
    this.onDelete,
  });

  @override
  State<MdbCrudDialog> createState() => _MdbCrudDialogState();
}

class _MdbCrudDialogState extends State<MdbCrudDialog> {
  late final Map<String, TextEditingController> _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = {
      for (final col in widget.columns)
        col['name']!: TextEditingController(
          text: widget.existing?[col['name']] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nouvelle ligne' : 'Modifier la ligne'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.columns.map((col) {
              final name = col['name']!;
              final isPk = name == widget.pkColumn;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: _ctrl[name],
                  readOnly: isPk && widget.existing != null,
                  decoration: InputDecoration(
                    labelText: name,
                    helperText: col['type'],
                    border: const OutlineInputBorder(),
                    suffixIcon: isPk ? const Icon(Icons.key, size: 16) : null,
                    filled: isPk && widget.existing != null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: widget.onDelete,
            child: const Text('Supprimer'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_ctrl.map((k, v) => MapEntry(k, v.text)));
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}