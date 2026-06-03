import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/house.dart';
import '../models/oria_card.dart';
import '../services/card_service.dart';
import 'card_invoice_detail_screen.dart';

class CardsScreen extends StatefulWidget {
  final House house;
  final List<Entry> entries;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Entry entry) onEditEntry;

  const CardsScreen({
    super.key,
    required this.house,
    required this.entries,
    required this.onRefresh,
    required this.onEditEntry,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _service = CardService();

  bool _loading = true;
  String? _error;
  List<OriaCardModel> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final cards = await _service.getCards(widget.house.id);
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Nao consegui abrir seus cartoes agora.';
      });
    }
  }

  Future<void> _reload() async {
    await _load();
    await widget.onRefresh();
  }

  Future<void> _openForm([OriaCardModel? card]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CardForm(
        house: widget.house,
        card: card,
        onDelete: card == null ? null : () => _deleteCard(card),
      ),
    );

    if (saved == true) {
      await _reload();
    }
  }

  double _cardTotal(String cardId) {
    return widget.entries
        .where((e) => e.cardId == cardId && e.countsInPlanned)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  List<Entry> _cardEntries(String cardId) {
    return widget.entries
        .where((e) => e.cardId == cardId && e.countsInPlanned)
        .toList()
      ..sort((a, b) {
        final da = a.dueDate ?? a.competenceMonth;
        final db = b.dueDate ?? b.competenceMonth;
        return da.compareTo(db);
      });
  }

  int _paidCount(String cardId) {
    return widget.entries.where((e) => e.cardId == cardId && e.isPaid).length;
  }

  Future<void> _editEntry(Entry entry) async {
    await widget.onEditEntry(entry);
    await _reload();
  }

  Future<void> _openInvoiceDetails(OriaCardModel card) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardInvoiceDetailScreen(
          card: card,
          entries: _cardEntries(card.id),
          onChanged: _reload,
          onEditEntry: _editEntry,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _deleteCard(OriaCardModel card) async {
    final totalEntries = widget.entries.where((e) => e.cardId == card.id).length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar cartão?'),
        content: Text(
          totalEntries == 0
              ? 'O cartão "${cardDisplayName(card)}" sera removido.'
              : 'O cartão "${cardDisplayName(card)}" sera removido. Os lancamentos existentes continuam salvos, mas ficam sem cartão vinculado.',
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

    try {
      await _service.deleteCard(card.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cartão apagado.')),
      );
      await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui apagar este cartão agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 104),
          children: [
            if (_loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            if (_error != null)
              _ErrorCard(
                title: 'Cartoes indisponiveis',
                message: _error!,
                onRetry: _reload,
              )
            else if (!_loading && _cards.isEmpty)
              _EmptyCards(onPressed: () => _openForm())
            else ...[
              _CardsHeader(onNew: () => _openForm()),
              const SizedBox(height: 10),
              ..._cards.map((card) {
                final total = _cardTotal(card.id);
                final paid = _paidCount(card.id);
                final cardEntries = _cardEntries(card.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CreditCardBlock(
                    card: card,
                    total: total,
                    paid: paid,
                    entries: cardEntries,
                    onEditCard: () => _openForm(card),
                    onDeleteCard: () => _deleteCard(card),
                    onEditEntry: _editEntry,
                    onOpenInvoiceDetails: () => _openInvoiceDetails(card),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardsHeader extends StatelessWidget {
  final VoidCallback onNew;

  const _CardsHeader({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cartões',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: OriaTheme.text,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Acompanhe faturas e lançamentos por cartão.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: OriaTheme.muted,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Novo cartão'),
            ),
          ),
        ],
      ),
    );
  }
}

String cardDisplayName(OriaCardModel card) {
  final name = _cleanCardName(card.name, card.ownerName);
  if (card.ownerName.trim().isEmpty) return name;
  return '$name - ${card.ownerName.trim()}';
}

String _cleanCardName(String name, String ownerName) {
  var cleaned = name.trim();
  final owner = ownerName.trim();

  if (owner.isEmpty) return cleaned;

  final normalizedCleaned = cleaned.toLowerCase();
  final normalizedOwner = owner.toLowerCase();

  if (normalizedCleaned.endsWith(' $normalizedOwner')) {
    cleaned = cleaned.substring(0, cleaned.length - owner.length).trim();
  }

  if (normalizedCleaned.endsWith('- $normalizedOwner')) {
    cleaned = cleaned.substring(0, cleaned.length - owner.length - 1).trim();
  }

  return cleaned.isEmpty ? name.trim() : cleaned;
}

class _CreditCardBlock extends StatelessWidget {
  final OriaCardModel card;
  final double total;
  final int paid;
  final List<Entry> entries;
  final VoidCallback onEditCard;
  final VoidCallback onDeleteCard;
  final Future<void> Function(Entry entry) onEditEntry;
  final VoidCallback onOpenInvoiceDetails;

  const _CreditCardBlock({
    required this.card,
    required this.total,
    required this.paid,
    required this.entries,
    required this.onEditCard,
    required this.onDeleteCard,
    required this.onEditEntry,
    required this.onOpenInvoiceDetails,
  });

  @override
  Widget build(BuildContext context) {
    final limit = card.limitAmount == null ? '-' : money(card.limitAmount!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OriaTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: OriaTheme.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2453D4), Color(0xFF102B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanCardName(card.name, card.ownerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.ownerName.trim().isEmpty ? 'Casa' : card.ownerName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OriaTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEditCard();
                  if (value == 'delete') onDeleteCard();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Apagar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _CardStat(label: 'Fatura', value: money(total))),
              const SizedBox(width: 8),
              Expanded(child: _CardStat(label: 'Limite', value: limit)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (card.closingDay != null) _LightPill(label: 'Fecha ${card.closingDay}'),
              if (card.dueDay != null) _LightPill(label: 'Vence ${card.dueDay}'),
              _LightPill(label: '$paid pago(s)'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenInvoiceDetails,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Ver fatura'),
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            const Text(
              'Ultimos lancamentos',
              style: TextStyle(
                color: OriaTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            ...entries.take(2).map((entry) => _CardEntryMiniTile(
                  entry: entry,
                  onTap: () => onEditEntry(entry),
                )),
          ],
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;

  const _CardStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: OriaTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: OriaTheme.muted, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: OriaTheme.blueDark, fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _LightPill extends StatelessWidget {
  final String label;

  const _LightPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: OriaTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }
}

class _CardEntryMiniTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;

  const _CardEntryMiniTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final notes = entry.notes?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: OriaTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                entry.isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                color: entry.isPaid ? OriaTheme.success : OriaTheme.blue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (notes != null && notes.isNotEmpty) ? notes.split('\n').take(2).join(' • ') : dateLabel(entry.dueDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OriaTheme.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(entry.amount),
                style: const TextStyle(
                  color: OriaTheme.blueDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  final VoidCallback onPressed;

  const _EmptyCards({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card_rounded, color: OriaTheme.blue, size: 30),
          const SizedBox(height: 14),
          const Text(
            'Nenhum cartão cadastrado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre o primeiro cartão para lançar faturas e acompanhar os valores do mês.',
            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cadastrar primeiro cartão'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _CardForm extends StatefulWidget {
  final House house;
  final OriaCardModel? card;
  final Future<void> Function()? onDelete;

  const _CardForm({required this.house, this.card, this.onDelete});

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  final _service = CardService();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _closing = TextEditingController();
  final _due = TextEditingController();
  final _limit = TextEditingController();
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _name.text = c?.name ?? '';
    _owner.text = c?.ownerName ?? '';
    _closing.text = c?.closingDay?.toString() ?? '';
    _due.text = c?.dueDay?.toString() ?? '';
    _limit.text = c?.limitAmount == null ? '' : formatMoneyInputValue(c!.limitAmount!);
  }

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _closing.dispose();
    _due.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a bandeira/cartão.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.upsertCard(
        id: widget.card?.id,
        houseId: widget.house.id,
        name: _name.text,
        ownerName: _owner.text,
        bankName: '',
        closingDay: int.tryParse(_closing.text),
        dueDay: int.tryParse(_due.text),
        limitAmount: _limit.text.trim().isEmpty ? null : parseMoney(_limit.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.onDelete == null) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.card == null ? 'Novo cartão' : 'Editar cartão',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Bandeira do cartão',
                  hintText: 'Ex.: Inter, Nubank, Neon, Visa',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _owner,
                decoration: const InputDecoration(
                  labelText: 'Dono do cartão',
                  hintText: 'Ex.: Jarrye, Thaissa, Casa',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _closing,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fecha dia'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _due,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Vence dia'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _limit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Limite opcional',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_saving || _deleting) ? null : _save,
                child: Text(_saving ? 'Salvando...' : 'Salvar cartão'),
              ),
              if (widget.card != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (_saving || _deleting) ? null : _delete,
                  style: OutlinedButton.styleFrom(foregroundColor: OriaTheme.danger),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(_deleting ? 'Apagando...' : 'Apagar cartão'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
