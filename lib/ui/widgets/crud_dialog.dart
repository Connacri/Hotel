import 'package:flutter/material.dart';

class CrudDialog extends StatefulWidget {
  final List<Map<String, String>> columns;
  final Map<String, String>? existing;
  final String? pkColumn;
  final void Function(Map<String, String> data) onSave;
  final VoidCallback? onDelete;

  const CrudDialog({
    super.key,
    required this.columns,
    required this.onSave,
    this.existing,
    this.pkColumn,
    this.onDelete,
  });

  @override
  State<CrudDialog> createState() => _CrudDialogState();
}

class _CrudDialogState extends State<CrudDialog> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final col in widget.columns)
        col['name']!: TextEditingController(
          text: widget.existing?[col['name']] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nouvelle ligne' : 'Modifier'),
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
                  controller: _controllers[name],
                  readOnly: isPk && widget.existing != null,
                  decoration: InputDecoration(
                    labelText: name,
                    helperText: col['type'],
                    suffixIcon: isPk ? const Icon(Icons.key, size: 16) : null,
                    border: const OutlineInputBorder(),
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
            onPressed: widget.onDelete,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        const Spacer(),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            widget.onSave(_controllers.map((k, v) => MapEntry(k, v.text)));
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}