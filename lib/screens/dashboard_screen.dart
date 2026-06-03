import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../core/status.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../widgets/app_logo.dart';
import '../widgets/month_header.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  final House house;
  final DateTime month;
  final List<EntryGroup> groups;
  final List<Entry> entries;
  final bool loading;
  final String? error;
  final double goalContributions;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final void Function(String mode) onOpenMode;
  final void Function(String mode) onAddForMode;

  const DashboardScreen({
    super.key,
    required this.house,
    required this.month,
    required this.groups,
    required this.entries,
    required this.loading,
    required this.error,
    required this.goalContributions,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onRefresh,
    required this.onAdd,
    required this.onOpenMode,
    required this.onAddForMode,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;
    final cardExtent = isWide ? 178.0 : 206.0;

    final monthEntries = entries.where((entry) => entry.countsInPlanned).toList();

    final entradas = monthEntries
        .where((entry) => entry.isIncome)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final entradasConfirmadas = monthEntries
        .where((entry) => entry.isIncome && entry.isPaid)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final contasFixas = monthEntries
        .where((entry) {
          final mode = _entryMode(entry);
          return entry.isExpense && (mode == EntryMode.fixedExpense || mode == EntryMode.financing);
        })
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final cartoes = monthEntries
        .where((entry) => entry.isExpense && _entryMode(entry) == EntryMode.cardInvoice)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final despesasPrevistas = monthEntries
        .where((entry) => entry.isExpense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final previsaoMes = entradas - despesasPrevistas;

    final pagoConfirmado = monthEntries
        .where((entry) => entry.isExpense && entry.isPaid)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    final saldoAtual = entradasConfirmadas - pagoConfirmado;

    final sortedEntries = [...entries]
      ..sort((a, b) {
        final da = a.dueDate ?? a.competenceMonth;
        final db = b.dueDate ?? b.competenceMonth;
        return db.compareTo(da);
      });

    final latestEntries = sortedEntries.take(4).toList();

    final cards = [
      SummaryCard(
        title: 'Saldo atual',
        value: money(saldoAtual),
        subtitle: 'Disponivel no momento',
        icon: Icons.account_balance_wallet_rounded,
        success: saldoAtual >= 0,
        danger: saldoAtual < 0,
      ),
      SummaryCard(
        title: 'Previsao',
        value: money(previsaoMes),
        subtitle: 'Se tudo do mes acontecer',
        icon: Icons.query_stats_rounded,
        success: previsaoMes >= 0,
        danger: previsaoMes < 0,
      ),
      SummaryCard(
        title: 'Entradas',
        value: money(entradas),
        subtitle: 'Recebimentos do mes',
        icon: Icons.trending_up_rounded,
        success: entradas > 0,
        onTap: () => onOpenMode(EntryMode.income),
      ),
      SummaryCard(
        title: 'Contas',
        value: money(contasFixas),
        subtitle: 'Despesas cadastradas',
        icon: Icons.receipt_long_rounded,
        onTap: () => onOpenMode(EntryMode.fixedExpense),
      ),
      SummaryCard(
        title: 'Cartoes',
        value: money(cartoes),
        subtitle: 'Faturas e compras do mes',
        icon: Icons.credit_card_rounded,
        onTap: () => onOpenMode(EntryMode.cardInvoice),
      ),
      SummaryCard(
        title: 'Pago no mes',
        value: money(pagoConfirmado),
        subtitle: 'Total pago no periodo',
        icon: Icons.verified_rounded,
        success: pagoConfirmado > 0,
        onTap: () => onOpenMode('__paid__'),
      ),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
          children: [
            _HeroHeader(
              houseName: house.name,
              monthLabel: monthYearLabel(month),
              saldoAtual: saldoAtual,
              previsaoMes: previsaoMes,
              onRefresh: onRefresh,
            ),
            const SizedBox(height: 18),
            MonthHeader(
              month: month,
              onPrevious: onPreviousMonth,
              onNext: onNextMonth,
            ),
            const SizedBox(height: 18),
            if (loading) const LinearProgressIndicator(),
            if (error != null) _ErrorBox(message: error!),
            GridView.builder(
              itemCount: cards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 6 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: cardExtent,
              ),
              itemBuilder: (_, index) => cards[index],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Areas do mes',
              subtitle: 'Veja os lancamentos por Entradas, Contas, Cartoes e Porquinho.',
            ),
            const SizedBox(height: 12),
            ..._homeModes.map((mode) {
              final modeEntries = monthEntries.where((entry) => _entryMode(entry) == mode).toList();

              if (modeEntries.isEmpty && mode == EntryMode.goalContribution && goalContributions <= 0) {
                return const SizedBox.shrink();
              }

              final total = mode == EntryMode.goalContribution
                  ? goalContributions
                  : modeEntries.fold<double>(0, (sum, entry) => sum + entry.amount);
              final paid = modeEntries.where((entry) => entry.isPaid).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModeShortcutCard(
                  mode: mode,
                  total: total,
                  count: modeEntries.length,
                  paid: paid,
                  onTap: () => onOpenMode(mode),
                  onAdd: () => onAddForMode(mode),
                ),
              );
            }),
            const SizedBox(height: 12),
            _SectionTitle(
              title: 'Ultimos lancamentos',
              subtitle: latestEntries.isEmpty ? 'Ainda nao ha lancamentos nesse mes.' : 'Acompanhe os ultimos itens cadastrados.',
            ),
            const SizedBox(height: 12),
            if (latestEntries.isEmpty)
              const _EmptyDashboard()
            else
              ...latestEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentEntryTile(entry: entry),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _homeModes = [
    EntryMode.income,
    EntryMode.fixedExpense,
    EntryMode.cardInvoice,
    EntryMode.goalContribution,
  ];

  String _entryMode(Entry entry) {
    if ((entry.mode ?? '').isNotEmpty) return entry.mode!;

    EntryGroup? group;
    for (final item in groups) {
      if (item.id == entry.groupId) {
        group = item;
        break;
      }
    }

    final name = group?.name.toLowerCase() ?? '';

    if (name.contains('entrada') || name.contains('receita')) return EntryMode.income;
    if (name.contains('cart')) return EntryMode.cardInvoice;
    if (name.contains('moto') || name.contains('carro') || name.contains('financi')) return EntryMode.financing;
    if (name.contains('porquinho') || name.contains('meta')) return EntryMode.goalContribution;
    if (name.contains('terce') || name.contains('outro')) return EntryMode.thirdParty;
    return EntryMode.fixedExpense;
  }
}

class _HeroHeader extends StatelessWidget {
  final String houseName;
  final String monthLabel;
  final double saldoAtual;
  final double previsaoMes;
  final Future<void> Function() onRefresh;

  const _HeroHeader({
    required this.houseName,
    required this.monthLabel,
    required this.saldoAtual,
    required this.previsaoMes,
    required this.onRefresh,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OriaTheme.blue, OriaTheme.blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x262453D4),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 54, showText: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()},',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      houseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sua casa, seu mes, seu controle.',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeShortcutCard extends StatelessWidget {
  final String mode;
  final double total;
  final int count;
  final int paid;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ModeShortcutCard({
    required this.mode,
    required this.total,
    required this.count,
    required this.paid,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: OriaTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: OriaTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(EntryMode.icon(mode), color: OriaTheme.blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _simpleModeLabel(mode),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count itens • $paid pagos',
                      style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(total),
                      style: const TextStyle(
                        color: OriaTheme.blueDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: OriaTheme.surfaceAlt,
                      foregroundColor: OriaTheme.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right_rounded, color: OriaTheme.muted),
                ],
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
}

class _RecentEntryTile extends StatelessWidget {
  final Entry entry;

  const _RecentEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final statusColor = EntryStatus.color(entry.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: entry.isIncome ? const Color(0xFFE9FFF1) : const Color(0xFFFFF3F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              entry.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: entry.isIncome ? OriaTheme.success : OriaTheme.danger,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  dateLabel(entry.dueDate),
                  style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(entry.amount),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  EntryStatus.label(entry.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDA4AF)),
        ),
        child: Text(
          message,
          style: const TextStyle(color: OriaTheme.danger, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: const Text(
        'Esse mes ainda esta vazio. Use o botao + para lancar entradas, contas, cartoes e porquinhos.',
        style: TextStyle(color: OriaTheme.muted, height: 1.4, fontWeight: FontWeight.w600),
      ),
    );
  }
}
