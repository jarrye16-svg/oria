import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../core/status.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../services/entry_service.dart';

class ReportsScreen extends StatefulWidget {
  final House house;
  final DateTime month;
  final List<Entry> entries;
  final List<EntryGroup> groups;

  const ReportsScreen({
    super.key,
    required this.house,
    required this.month,
    required this.entries,
    required this.groups,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _entryService = EntryService();

  late DateTime _selectedMonth;
  List<Entry> _allEntries = [];
  bool _loadingHistory = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _selectedMonth = monthStart(widget.month);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final entries = await _entryService.getAllEntries(houseId: widget.house.id);
      if (!mounted) return;

      setState(() {
        _allEntries = entries;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allEntries = widget.entries;
        _loadingHistory = false;
        _historyError = 'Nao consegui carregar o historico completo. Mostrando apenas o mes atual.';
      });
    }
  }

  List<Entry> get _sourceEntries => _allEntries.isEmpty ? widget.entries : _allEntries;

  List<Entry> get _monthEntries {
    return _sourceEntries.where((entry) {
      final month = monthStart(entry.competenceMonth);
      return month.year == _selectedMonth.year && month.month == _selectedMonth.month;
    }).toList();
  }

  double _sum(Iterable<Entry> entries, bool Function(Entry entry) test) {
    return entries.where(test).fold<double>(0, (s, e) => s + e.amount);
  }

  double _monthExpenses(DateTime month) {
    return _sum(_sourceEntries.where((e) {
      final entryMonth = monthStart(e.competenceMonth);
      return entryMonth.year == month.year && entryMonth.month == month.month;
    }), (e) => e.isExpense && e.countsInPlanned);
  }

  double _monthIncome(DateTime month) {
    return _sum(_sourceEntries.where((e) {
      final entryMonth = monthStart(e.competenceMonth);
      return entryMonth.year == month.year && entryMonth.month == month.month;
    }), (e) => e.isIncome && e.countsInPlanned);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
  }

  String _groupName(String? id) {
    if (id == null) return 'Sem categoria';
    for (final g in widget.groups) {
      if (g.id == id) return g.name;
    }
    return 'Sem categoria';
  }

  List<_ReportRow> _byCategory(List<Entry> entries) {
    final map = <String, double>{};
    for (final entry in entries.where((e) => e.isExpense && e.countsInPlanned)) {
      final key = _groupName(entry.groupId);
      map[key] = (map[key] ?? 0) + entry.amount;
    }
    return _rowsFromMap(map);
  }

  List<_ReportRow> _byCard(List<Entry> entries) {
    final map = <String, double>{};
    for (final entry in entries.where((e) => e.mode == EntryMode.cardInvoice && e.countsInPlanned)) {
      map[entry.title] = (map[entry.title] ?? 0) + entry.amount;
    }
    return _rowsFromMap(map);
  }

  List<_ReportRow> _topExpenses(List<Entry> entries) {
    final rows = entries
        .where((e) => e.isExpense && e.countsInPlanned)
        .map((e) => _ReportRow(e.title, e.amount))
        .toList();

    rows.sort((a, b) => b.value.compareTo(a.value));
    return rows.take(5).toList();
  }

  List<_ReportRow> _rowsFromMap(Map<String, double> map) {
    final rows = map.entries.map((e) => _ReportRow(e.key, e.value)).toList();
    rows.sort((a, b) => b.value.compareTo(a.value));
    return rows;
  }

  List<_MonthPoint> _historyPoints() {
    final points = <_MonthPoint>[];

    for (var index = 5; index >= 0; index--) {
      final month = DateTime(_selectedMonth.year, _selectedMonth.month - index, 1);
      final income = _monthIncome(month);
      final expense = _monthExpenses(month);

      points.add(
        _MonthPoint(
          month: month,
          income: income,
          expense: expense,
          current: month.year == _selectedMonth.year && month.month == _selectedMonth.month,
        ),
      );
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    final monthEntries = _monthEntries;
    final plannedIncome = _sum(monthEntries, (e) => e.isIncome && e.countsInPlanned);
    final plannedExpense = _sum(monthEntries, (e) => e.isExpense && e.countsInPlanned);
    final paidExpense = _sum(monthEntries, (e) => e.isExpense && e.isPaid);
    final pendingExpense = _sum(monthEntries, (e) => e.isExpense && e.countsInPlanned && !e.isPaid);
    final forecast = plannedIncome - plannedExpense;
    final realBalance = plannedIncome - paidExpense;

    return Scaffold(
      appBar: AppBar(title: const Text('Controle mensal')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _Header(
                month: _selectedMonth,
                forecast: forecast,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
              if (_loadingHistory) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_historyError != null) ...[
                const SizedBox(height: 12),
                _NoticeCard(text: _historyError!),
              ],
              const SizedBox(height: 14),
              _MonthHistoryChart(
                points: _historyPoints(),
                onSelect: (month) => setState(() => _selectedMonth = monthStart(month)),
              ),
              const SizedBox(height: 14),
              _MonthInvoiceCard(
                month: _selectedMonth,
                plannedIncome: plannedIncome,
                plannedExpense: plannedExpense,
                paidExpense: paidExpense,
                pendingExpense: pendingExpense,
                forecast: forecast,
                realBalance: realBalance,
              ),
              const SizedBox(height: 14),
              _SummaryGrid(
                cards: [
                  _ReportCard(title: 'Entradas', value: money(plannedIncome), icon: Icons.trending_up_rounded, good: true),
                  _ReportCard(title: 'Despesas', value: money(plannedExpense), icon: Icons.receipt_long_rounded, danger: plannedExpense > plannedIncome),
                  _ReportCard(title: 'Pago', value: money(paidExpense), icon: Icons.verified_rounded, good: true),
                  _ReportCard(title: 'Pendente', value: money(pendingExpense), icon: Icons.schedule_rounded, danger: pendingExpense > 0),
                ],
              ),
              const SizedBox(height: 16),
              _Breakdown(title: 'Maiores gastos', rows: _topExpenses(monthEntries)),
              const SizedBox(height: 16),
              _Breakdown(title: 'Por categoria', rows: _byCategory(monthEntries)),
              const SizedBox(height: 16),
              _Breakdown(title: 'Por cartao', rows: _byCard(monthEntries)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime month;
  final double forecast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _Header({
    required this.month,
    required this.forecast,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final positive = forecast >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2453D4), Color(0xFF102B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONTROLE MENSAL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
              ),
              Expanded(
                child: Text(
                  monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            positive ? 'Mes previsto no positivo.' : 'Atencao: mes previsto no negativo.',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Previsao do mes', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  money(forecast),
                  style: TextStyle(
                    color: positive ? Colors.white : const Color(0xFFFFD1D1),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHistoryChart extends StatelessWidget {
  final List<_MonthPoint> points;
  final void Function(DateTime month) onSelect;

  const _MonthHistoryChart({
    required this.points,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, point) {
      final pointMax = point.expense > point.income ? point.expense : point.income;
      return pointMax > max ? pointMax : max;
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historico real', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Ultimos meses com entradas e despesas registradas.',
            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                final incomePct = maxValue <= 0 ? 0.0 : (point.income / maxValue).clamp(0.0, 1.0);
                final expensePct = maxValue <= 0 ? 0.0 : (point.expense / maxValue).clamp(0.0, 1.0);

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onSelect(point.month),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _HistoryBar(point: point, incomePct: incomePct, expensePct: expensePct),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _Legend(color: OriaTheme.success, label: 'Entradas'),
              SizedBox(width: 12),
              _Legend(color: OriaTheme.blue, label: 'Despesas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryBar extends StatelessWidget {
  final _MonthPoint point;
  final double incomePct;
  final double expensePct;

  const _HistoryBar({
    required this.point,
    required this.incomePct,
    required this.expensePct,
  });

  @override
  Widget build(BuildContext context) {
    final incomeHeight = 26 + (95 * incomePct);
    final expenseHeight = 26 + (95 * expensePct);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            money(point.expense),
            style: const TextStyle(color: OriaTheme.muted, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 130,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 12,
                height: incomeHeight,
                decoration: BoxDecoration(
                  color: OriaTheme.success,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 12,
                height: expenseHeight,
                decoration: BoxDecoration(
                  color: point.current ? OriaTheme.blue : const Color(0xFFB8BCC5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (point.current)
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(color: OriaTheme.text, shape: BoxShape.circle),
          )
        else
          const SizedBox(height: 9),
        const SizedBox(height: 4),
        Text(
          _shortMonthYearLabel(point.month),
          style: TextStyle(
            color: point.current ? OriaTheme.text : OriaTheme.muted,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MonthInvoiceCard extends StatelessWidget {
  final DateTime month;
  final double plannedIncome;
  final double plannedExpense;
  final double paidExpense;
  final double pendingExpense;
  final double forecast;
  final double realBalance;

  const _MonthInvoiceCard({
    required this.month,
    required this.plannedIncome,
    required this.plannedExpense,
    required this.paidExpense,
    required this.pendingExpense,
    required this.forecast,
    required this.realBalance,
  });

  @override
  Widget build(BuildContext context) {
    final positive = forecast >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    monthLabel(month),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: positive ? OriaTheme.success : OriaTheme.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    positive ? 'Positivo' : 'Negativo',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          _InvoiceLine(label: 'Entradas previstas', value: money(plannedIncome)),
          _InvoiceLine(label: 'Despesas previstas', value: money(plannedExpense)),
          _InvoiceLine(label: 'Ja pago', value: money(paidExpense)),
          _InvoiceLine(label: 'Falta pagar', value: money(pendingExpense)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resumo do mes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  money(forecast),
                  style: TextStyle(
                    color: positive ? OriaTheme.success : OriaTheme.danger,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OriaTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Saldo real considerando apenas o que ja foi pago: ${money(realBalance)}',
              style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  final String label;
  final String value;

  const _InvoiceLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<_ReportCard> cards;

  const _SummaryGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final wide = constraints.maxWidth > 720;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: cards,
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool good;
  final bool danger;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    this.good = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? OriaTheme.danger : (good ? OriaTheme.success : OriaTheme.blueDark);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(title, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  final String title;
  final List<_ReportRow> rows;

  const _Breakdown({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<double>(0, (s, r) => s + r.value);

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
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text('Nada para mostrar neste mes.', style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600))
          else
            ...rows.map((row) {
              final pct = total <= 0 ? 0.0 : row.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(row.label, style: const TextStyle(fontWeight: FontWeight.w800))),
                        Text(money(row.value), style: const TextStyle(fontWeight: FontWeight.w900, color: OriaTheme.blueDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: OriaTheme.surfaceAlt,
                        color: OriaTheme.blue,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String text;

  const _NoticeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MonthPoint {
  final DateTime month;
  final double income;
  final double expense;
  final bool current;

  const _MonthPoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.current,
  });
}

class _ReportRow {
  final String label;
  final double value;

  const _ReportRow(this.label, this.value);
}

String _shortMonthYearLabel(DateTime month) {
  const names = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  final name = names[month.month - 1];
  final year = (month.year % 100).toString().padLeft(2, '0');
  return '$name/$year';
}
