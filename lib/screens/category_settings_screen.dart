import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/status.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../services/entry_service.dart';

class CategorySettingsScreen extends StatefulWidget {
  final House house;
  final List<EntryGroup> groups;
  final Future<void> Function() onChanged;

  const CategorySettingsScreen({
    super.key,
    required this.house,
    required this.groups,
    required this.onChanged,
  });

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  final _service = EntryService();
  late List<EntryGroup> _groups;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _groups = [...widget.groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> _reloadLocal() async {
    final groups = await _service.getGroups(widget.house.id);
    if (!mounted) return;
    setState(() => _groups = groups);
    await widget.onChanged();
  }

  Future<void> _openEditor({EntryGroup? group, required String kind}) async {
    final controller = TextEditingController(text: group?.name ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? 'Nova categoria' : 'Editar categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.trim().length < 2) return;

    setState(() => _saving = true);

    try {
      if (group == null) {
        await _service.createGroup(houseId: widget.house.id, name: result, kind: kind);
      } else {
        await _service.updateGroup(id: group.id, name: result);
      }

      await _reloadLocal();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui salvar a categoria. Confira se voce e admin da casa.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(EntryGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover categoria?'),
        content: Text('A categoria "${group.name}" sera removida. Lancamentos antigos ficam sem categoria.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remover')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);

    try {
      await _service.deleteGroup(group.id);
      await _reloadLocal();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui remover. Confira se voce e admin da casa.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomes = _groups.where((g) => g.kind == EntryType.income).toList();
    final expenses = _groups.where((g) => g.kind == EntryType.expense).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            if (_saving) const LinearProgressIndicator(),
            _Section(
              title: 'Entradas',
              buttonLabel: 'Nova entrada',
              onAdd: () => _openEditor(kind: EntryType.income),
              children: incomes.map((g) => _GroupTile(group: g, onEdit: () => _openEditor(group: g, kind: g.kind), onDelete: () => _delete(g))).toList(),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Contas e gastos',
              buttonLabel: 'Nova categoria',
              onAdd: () => _openEditor(kind: EntryType.expense),
              children: expenses.map((g) => _GroupTile(group: g, onEdit: () => _openEditor(group: g, kind: g.kind), onDelete: () => _delete(g))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onAdd;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.buttonLabel,
    required this.onAdd,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(buttonLabel)),
            ],
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            const Text('Nenhuma categoria criada.', style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600))
          else
            ...children,
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final EntryGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupTile({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(group.kind == EntryType.income ? 'Entrada' : 'Conta/Gasto'),
      trailing: Wrap(
        children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
    );
  }
}
