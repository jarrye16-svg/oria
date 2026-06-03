import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../services/entry_service.dart';
import '../widgets/entry_tile.dart';
import '../widgets/month_header.dart';

class PaidEntriesScreen extends StatefulWidget {
  final House house;
  final DateTime month;
  final List<Entry> entries;
  final List<EntryGroup> groups;
  final Future<void> Function() onRefresh;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function(Entry entry) onEdit;

  const PaidEntriesScreen({
    super.key,
    required this.house,
    required this.month,
    required this.entries,
    required this.groups,
    required this.onRefresh,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onEdit,
  });

  @override
  State<PaidEntriesScreen> createState() => _PaidEntriesScreenState();
}

class _PaidEntriesScreenState extends State<PaidEntriesScreen> {
  final _entryService = EntryService();

  late List<Entry> _entries;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _entries = List<Entry>.from(widget.entries);
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

  Future<void> _edit(Entry entry) async {
    await widget.onEdit(entry);
    await _reloadLocal();
  }

  @override
  Widget build(BuildContext context) {
    final paidEntries = _entries
        .where((entry) => entry.countsInPlanned && entry.isExpense && entry.isPaid)
        .toList();

    final total = paidEntries.fold<double>(0, (sum, entry) => sum + entry.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago no mes'),
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
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFE9FFF1),
                          child: Icon(
                            Icons.verified_rounded,
                            color: OriaTheme.success,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pago no mes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${paidEntries.length} itens pagos',
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
                        color: OriaTheme.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Soma de contas, cartoes e porquinhos marcados como pagos',
                      style: TextStyle(
                        color: OriaTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (paidEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: OriaTheme.cardBorder),
                  ),
                  child: const Text(
                    'Nenhum item pago neste mes ainda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: OriaTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...paidEntries.map(
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
}
