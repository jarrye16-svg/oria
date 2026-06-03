import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../core/status.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../services/entry_service.dart';
import '../widgets/entry_tile.dart';
import '../widgets/month_header.dart';

class ModeEntriesScreen extends StatefulWidget {
  final House house;
  final DateTime month;
  final String mode;
  final List<Entry> entries;
  final List<EntryGroup> groups;
  final Future<void> Function() onRefresh;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function(Entry entry) onEdit;
  final Future<void> Function() onAdd;

  const ModeEntriesScreen({
    super.key,
    required this.house,
    required this.month,
    required this.mode,
    required this.entries,
    required this.groups,
    required this.onRefresh,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  State<ModeEntriesScreen> createState() => _ModeEntriesScreenState();
}

class _ModeEntriesScreenState extends State<ModeEntriesScreen> {
  final _entryService = EntryService();

  late List<Entry> _entries;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _entries = List<Entry>.from(widget.entries);
  }

  @override
  void didUpdateWidget(covariant ModeEntriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.entries != widget.entries) {
      _entries = List<Entry>.from(widget.entries);
    }
  }

  Future<void> _reloadLocal() async {
    setState(() => _loading = true);

    try {
      final latest = await _entryService.getEntries(
        houseId: widget.house.id,
        month: widget.month,
      );

      if (!mounted) return;

      setState(() {
        _entries = latest;
        _loading = false;
      });

      await widget.onRefresh();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    await widget.onAdd();
    await _reloadLocal();
  }

  Future<void> _edit(Entry entry) async {
    await widget.onEdit(entry);
    await _reloadLocal();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _entries.where((entry) {
      final entryMode = _entryMode(entry);
      if (widget.mode == EntryMode.fixedExpense) {
        return entryMode == EntryMode.fixedExpense || entryMode == EntryMode.financing;
      }
      return entryMode == widget.mode;
    }).toList();
    final total = filtered
        .where((entry) => entry.countsInPlanned)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final paidCount = filtered.where((entry) => entry.isPaid).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_simpleModeLabel(widget.mode)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _add,
        icon: const Icon(Icons.add),
        label: Text('Nova ${_newLabel(widget.mode)}'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadLocal,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              Text(
                widget.house.name,
                style: const TextStyle(
                  color: OriaTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              MonthHeader(
                month: widget.month,
                onPrevious: widget.onPreviousMonth,
                onNext: widget.onNextMonth,
              ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: OriaTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Icon(
                            EntryMode.icon(widget.mode),
                            color: OriaTheme.blue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _simpleModeLabel(widget.mode),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${filtered.length} itens • $paidCount pagos',
                                style: const TextStyle(
                                  color: OriaTheme.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      money(total),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: OriaTheme.blueDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Total do mes nesta area',
                      style: TextStyle(
                        color: OriaTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: OriaTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(
                          EntryMode.icon(widget.mode),
                          color: OriaTheme.blue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Nenhum lancamento em ${_simpleModeLabel(widget.mode).toLowerCase()} neste mes.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: OriaTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _add,
                        icon: const Icon(Icons.add),
                        label: Text('Criar ${_newLabel(widget.mode)}'),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EntryTile(
                      entry: entry,
                      onChanged: _reloadLocal,
                      onTap: () => _edit(entry),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _simpleModeLabel(String mode) {
    switch (mode) {
      case EntryMode.fixedExpense:
        return 'Contas';
      default:
        return EntryMode.label(mode);
    }
  }

  String _newLabel(String mode) {
    switch (mode) {
      case EntryMode.income:
        return 'entrada';
      case EntryMode.cardInvoice:
        return 'compra/fatura';
      case EntryMode.financing:
        return 'parcela';
      case EntryMode.goalContribution:
        return 'aporte';
      default:
        return 'conta';
    }
  }

  String _entryMode(Entry entry) {
    if ((entry.mode ?? '').isNotEmpty) return entry.mode!;

    EntryGroup? group;
    for (final item in widget.groups) {
      if (item.id == entry.groupId) {
        group = item;
        break;
      }
    }

    final name = (group?.name ?? '').toLowerCase();

    if (name.contains('entrada') || name.contains('receita')) return EntryMode.income;
    if (name.contains('cart')) return EntryMode.cardInvoice;
    if (name.contains('moto') || name.contains('carro') || name.contains('financi')) return EntryMode.financing;
    if (name.contains('porquinho') || name.contains('meta')) return EntryMode.goalContribution;
    return EntryMode.fixedExpense;
  }
}
