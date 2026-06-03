import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/oria_card.dart';
import '../services/entry_service.dart';

class CardInvoiceDetailScreen extends StatefulWidget {
  final OriaCardModel card;
  final List<Entry> entries;
  final Future<void> Function() onChanged;
  final Future<void> Function(Entry entry) onEditEntry;

  const CardInvoiceDetailScreen({
    super.key,
    required this.card,
    required this.entries,
    required this.onChanged,
    required this.onEditEntry,
  });

  @override
  State<CardInvoiceDetailScreen> createState() => _CardInvoiceDetailScreenState();
}

class _CardInvoiceDetailScreenState extends State<CardInvoiceDetailScreen> {
  final _service = EntryService();
  late List<Entry> _entries;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = [...widget.entries]..sort(_sortEntries);
  }

  int _sortEntries(Entry a, Entry b) {
    final da = a.dueDate ?? a.competenceMonth;
    final db = b.dueDate ?? b.competenceMonth;
    final byDate = da.compareTo(db);
    if (byDate != 0) return byDate;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  double get _total => _entries.where((e) => e.countsInPlanned).fold<double>(0, (s, e) => s + e.amount);
  double get _paid => _entries.where((e) => e.countsInPlanned && e.isPaid).fold<double>(0, (s, e) => s + e.amount);
  double get _pending => _total - _paid;
  int get _paidCount => _entries.where((e) => e.isPaid).length;
  bool get _allPaid => _entries.isNotEmpty && _entries.every((e) => e.isPaid);

  String get _cardName {
    final name = widget.card.name.trim();
    final owner = widget.card.ownerName.trim();

    if (owner.isEmpty || owner.toLowerCase() == 'casa') return name;
    return '$name - $owner';
  }

  String get _statusLabel {
    if (_entries.isEmpty) return 'Sem lancamentos';
    if (_allPaid) return 'Paga';
    if (_paidCount > 0) return 'Parcial';
    return 'Aberta';
  }

  Color get _statusColor {
    if (_allPaid) return OriaTheme.success;
    if (_paidCount > 0) return OriaTheme.blue;
    return OriaTheme.danger;
  }

  String get _dueLabel {
    final due = widget.card.dueDay;
    if (due == null) return 'Sem vencimento';
    return 'Vence dia $due';
  }

  Future<void> _toggleEntry(Entry entry) async {
    setState(() => _saving = true);

    try {
      await _service.setEntryPaid(entry, !entry.isPaid);
      await widget.onChanged();

      if (!mounted) return;

      setState(() {
        final index = _entries.indexWhere((e) => e.id == entry.id);
        if (index >= 0) {
          _entries[index] = Entry(
            id: entry.id,
            houseId: entry.houseId,
            groupId: entry.groupId,
            title: entry.title,
            amount: entry.amount,
            type: entry.type,
            status: entry.isPaid ? 'pending' : 'paid',
            competenceMonth: entry.competenceMonth,
            dueDate: entry.dueDate,
            responsible: entry.responsible,
            notes: entry.notes,
            isRecurring: entry.isRecurring,
            paidAt: entry.isPaid ? null : DateTime.now(),
            mode: entry.mode,
            cardId: entry.cardId,
            goalId: entry.goalId,
          );
        }
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui atualizar este item.')),
      );
    }
  }

  Future<void> _setAllPaid(bool paid) async {
    if (_entries.isEmpty) return;

    setState(() => _saving = true);

    try {
      for (final entry in _entries) {
        if (entry.isPaid != paid) {
          await _service.setEntryPaid(entry, paid);
        }
      }

      await widget.onChanged();

      if (!mounted) return;

      setState(() {
        _entries = _entries
            .map(
              (entry) => Entry(
                id: entry.id,
                houseId: entry.houseId,
                groupId: entry.groupId,
                title: entry.title,
                amount: entry.amount,
                type: entry.type,
                status: paid ? 'paid' : 'pending',
                competenceMonth: entry.competenceMonth,
                dueDate: entry.dueDate,
                responsible: entry.responsible,
                notes: entry.notes,
                isRecurring: entry.isRecurring,
                paidAt: paid ? DateTime.now() : null,
                mode: entry.mode,
                cardId: entry.cardId,
                goalId: entry.goalId,
              ),
            )
            .toList();
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paid ? 'Fatura marcada como paga.' : 'Fatura reaberta.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui atualizar a fatura.')),
      );
    }
  }

  Future<void> _editEntry(Entry entry) async {
    await widget.onEditEntry(entry);
    await widget.onChanged();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OriaTheme.background,
      appBar: AppBar(
        title: const Text('Fatura do cartao'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            _InvoiceHero(
              cardName: _cardName,
              status: _statusLabel,
              statusColor: _statusColor,
              dueLabel: _dueLabel,
              total: _total,
            ),
            const SizedBox(height: 12),
            _InvoiceSummary(
              total: _total,
              paid: _paid,
              pending: _pending,
              paidCount: _paidCount,
              totalCount: _entries.length,
            ),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              const _EmptyInvoice()
            else
              _InvoiceItemsCard(
                entries: _entries,
                saving: _saving,
                onToggle: _toggleEntry,
                onEdit: _editEntry,
              ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _saving || _entries.isEmpty ? null : () => _setAllPaid(!_allPaid),
              icon: Icon(_allPaid ? Icons.lock_open_rounded : Icons.check_circle_rounded),
              label: Text(_saving ? 'Atualizando...' : (_allPaid ? 'Reabrir fatura' : 'Marcar fatura como paga')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar para cartoes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceHero extends StatelessWidget {
  final String cardName;
  final String status;
  final Color statusColor;
  final String dueLabel;
  final double total;

  const _InvoiceHero({
    required this.cardName,
    required this.status,
    required this.statusColor,
    required this.dueLabel,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2453D4), Color(0xFF102B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: OriaTheme.shadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card_rounded, color: Colors.white, size: 30),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            cardName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, height: 1.05),
          ),
          const SizedBox(height: 8),
          Text(
            dueLabel,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          const Text('Total da fatura', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              money(total),
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummary extends StatelessWidget {
  final double total;
  final double paid;
  final double pending;
  final int paidCount;
  final int totalCount;

  const _InvoiceSummary({
    required this.total,
    required this.paid,
    required this.pending,
    required this.paidCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryMini(label: 'Pago', value: money(paid), color: OriaTheme.success)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryMini(label: 'Pendente', value: money(pending), color: OriaTheme.danger)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: OriaTheme.surfaceAlt,
              color: OriaTheme.success,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$paidCount de $totalCount lancamento(s) pago(s)',
                  style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: OriaTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemsCard extends StatelessWidget {
  final List<Entry> entries;
  final bool saving;
  final Future<void> Function(Entry entry) onToggle;
  final Future<void> Function(Entry entry) onEdit;

  const _InvoiceItemsCard({
    required this.entries,
    required this.saving,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lancamentos da fatura', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...entries.map(
            (entry) => _InvoiceEntryTile(
              entry: entry,
              saving: saving,
              onToggle: () => onToggle(entry),
              onEdit: () => onEdit(entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceEntryTile extends StatelessWidget {
  final Entry entry;
  final bool saving;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _InvoiceEntryTile({
    required this.entry,
    required this.saving,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final paid = entry.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFFE9FFF1) : OriaTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: paid ? const Color(0xFFBBF7D0) : OriaTheme.cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: saving ? null : onToggle,
            icon: Icon(paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
            color: paid ? OriaTheme.success : OriaTheme.muted,
          ),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel(entry.dueDate),
                    style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            money(entry.amount),
            style: const TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvoice extends StatelessWidget {
  const _EmptyInvoice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: OriaTheme.blue, size: 34),
          SizedBox(height: 10),
          Text('Nenhum lancamento neste cartao', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          SizedBox(height: 6),
          Text(
            'Quando voce lancar uma compra nesse cartao, ela aparece aqui como parte da fatura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
