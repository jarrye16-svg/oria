import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../widgets/entry_tile.dart';
import '../widgets/month_header.dart';
import '../widgets/page_intro.dart';

class MonthScreen extends StatelessWidget {
  final House house;
  final DateTime month;
  final List<EntryGroup> groups;
  final List<Entry> entries;
  final bool loading;
  final String? error;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function() onRefresh;
  final void Function(Entry entry) onEdit;

  const MonthScreen({
    super.key,
    required this.house,
    required this.month,
    required this.groups,
    required this.entries,
    required this.loading,
    required this.error,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onRefresh,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            PageIntro(
              eyebrow: 'VISAO DO MES',
              title: 'Fechamento mensal',
              subtitle: 'Confira grupos, totais e lancamentos da ${house.name}.',
              trailing: IconButton.filledTonal(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 12),
            MonthHeader(month: month, onPrevious: onPreviousMonth, onNext: onNextMonth),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            if (error != null) _ErrorCard(message: error!),
            ...groups.map((group) {
              final groupEntries = entries.where((entry) => entry.groupId == group.id).toList();
              final total = groupEntries.where((e) => e.countsInPlanned).fold<double>(0, (sum, e) => sum + e.amount);
              return _GroupSection(
                title: group.name,
                total: total,
                entries: groupEntries,
                onRefresh: onRefresh,
                onEdit: onEdit,
              );
            }),
            finalEntriesWithoutGroup(context),
            if (!loading && entries.isEmpty) const _EmptyMonth(),
          ],
        ),
      ),
    );
  }

  Widget finalEntriesWithoutGroup(BuildContext context) {
    final groupIds = groups.map((g) => g.id).toSet();
    final loose = entries.where((entry) => entry.groupId == null || !groupIds.contains(entry.groupId)).toList();
    if (loose.isEmpty) return const SizedBox.shrink();
    final total = loose.where((e) => e.countsInPlanned).fold<double>(0, (sum, e) => sum + e.amount);
    return _GroupSection(
      title: 'Sem grupo',
      total: total,
      entries: loose,
      onRefresh: onRefresh,
      onEdit: onEdit,
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String title;
  final double total;
  final List<Entry> entries;
  final Future<void> Function() onRefresh;
  final void Function(Entry entry) onEdit;

  const _GroupSection({
    required this.title,
    required this.total,
    required this.entries,
    required this.onRefresh,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  money(total),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: OriaTheme.blueDark),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entries.length} lancamento(s) no grupo',
              style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (entry) => EntryTile(
                entry: entry,
                onChanged: onRefresh,
                onTap: () => onEdit(entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: const Text(
        'Esse mes ainda esta vazio. Adicione lancamentos pelo botao + e acompanhe tudo por aqui.',
        textAlign: TextAlign.center,
        style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4),
      ),
    );
  }
}
