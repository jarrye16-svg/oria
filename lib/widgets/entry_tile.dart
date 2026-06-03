import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../core/status.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';

class EntryTile extends StatefulWidget {
  final Entry entry;
  final Future<void> Function() onChanged;
  final VoidCallback onTap;

  const EntryTile({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onTap,
  });

  @override
  State<EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<EntryTile> {
  final _service = EntryService();

  late bool _paid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paid = widget.entry.isPaid;
  }

  @override
  void didUpdateWidget(covariant EntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.entry.id != widget.entry.id || oldWidget.entry.status != widget.entry.status) {
      _paid = widget.entry.isPaid;
    }
  }

  Future<void> _toggle(bool? value) async {
    final next = value ?? false;
    final previous = _paid;

    setState(() {
      _paid = next;
      _saving = true;
    });

    try {
      await _service.setEntryPaid(widget.entry, next);
      await widget.onChanged();
    } catch (_) {
      if (!mounted) return;
      setState(() => _paid = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui atualizar agora.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _duplicateNextMonth() async {
    setState(() => _saving = true);

    try {
      await _service.duplicateEntryToNextMonth(widget.entry);
      await widget.onChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lancamento copiado para o proximo mes.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui copiar para o proximo mes.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar lancamento?'),
        content: Text(
          'O lancamento "${widget.entry.title}" sera apagado. Essa acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: OriaTheme.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);

    try {
      await _service.deleteEntry(widget.entry.id);
      await widget.onChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lancamento apagado.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui apagar este lancamento.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAction(String value) async {
    if (_saving) return;

    switch (value) {
      case 'edit':
        widget.onTap();
        break;
      case 'paid':
        await _toggle(true);
        break;
      case 'pending':
        await _toggle(false);
        break;
      case 'duplicate':
        await _duplicateNextMonth();
        break;
      case 'delete':
        await _deleteEntry();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _paid ? EntryStatus.paid : widget.entry.status;
    final color = EntryStatus.color(status);
    final notes = widget.entry.notes?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _paid ? const Color(0xFFF0FDF4) : OriaTheme.soft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _paid ? const Color(0xFFBBF7D0) : OriaTheme.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Checkbox.adaptive(
                value: _paid,
                onChanged: _saving ? null : _toggle,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        decoration: _paid ? TextDecoration.lineThrough : TextDecoration.none,
                        color: _paid ? OriaTheme.muted : OriaTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel(widget.entry.dueDate),
                      style: const TextStyle(color: OriaTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes.split('\n').take(2).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OriaTheme.muted,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(widget.entry.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _paid ? OriaTheme.success : OriaTheme.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      EntryStatus.label(status),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                enabled: !_saving,
                tooltip: 'Acoes',
                icon: const Icon(Icons.more_vert_rounded, color: OriaTheme.muted),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                onSelected: _openAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: _ActionMenuItem(
                      icon: Icons.edit_rounded,
                      label: 'Editar',
                    ),
                  ),
                  PopupMenuItem(
                    value: _paid ? 'pending' : 'paid',
                    child: _ActionMenuItem(
                      icon: _paid ? Icons.undo_rounded : Icons.check_circle_rounded,
                      label: _paid ? 'Marcar pendente' : 'Marcar pago',
                      color: _paid ? OriaTheme.blue : OriaTheme.success,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: _ActionMenuItem(
                      icon: Icons.copy_rounded,
                      label: 'Copiar para proximo mes',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: _ActionMenuItem(
                      icon: Icons.delete_outline_rounded,
                      label: 'Apagar',
                      color: OriaTheme.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? OriaTheme.text;

    return Row(
      children: [
        Icon(icon, size: 20, color: itemColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: itemColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
