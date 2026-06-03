import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../services/auth_service.dart';
import '../services/entry_service.dart';
import '../widgets/page_intro.dart';
import 'category_settings_screen.dart';
import 'members_screen.dart';
import 'reports_screen.dart';
import 'public_share_screen.dart';

class SettingsScreen extends StatefulWidget {
  final House house;
  final DateTime month;
  final List<EntryGroup> groups;
  final List<Entry> entries;
  final Future<void> Function() onRefresh;

  const SettingsScreen({
    super.key,
    required this.house,
    required this.month,
    required this.groups,
    required this.entries,
    required this.onRefresh,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _entryService = EntryService();
  bool _generating = false;

  Future<void> _generateNextMonth() async {
    setState(() => _generating = true);

    try {
      final count = await _entryService.generateNextMonth(
        houseId: widget.house.id,
        currentMonth: widget.month,
      );

      await widget.onRefresh();

      if (!mounted) return;

      final next = monthLabel(nextMonth(widget.month));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count == 0
              ? 'Nada novo para gerar em $next.'
              : '$count lancamento(s) gerado(s) em $next.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui gerar o proximo mes.')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategorySettingsScreen(
          house: widget.house,
          groups: widget.groups,
          onChanged: widget.onRefresh,
        ),
      ),
    );

    await widget.onRefresh();
  }

  void _openReports() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(
          house: widget.house,
          month: widget.month,
          entries: widget.entries,
          groups: widget.groups,
        ),
      ),
    );
  }


  void _openPublicShare() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PublicShareScreen(),
      ),
    );
  }

  void _openMembers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MembersScreen(house: widget.house),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
        children: [
          PageIntro(
            eyebrow: 'AJUSTES',
            title: widget.house.name,
            subtitle: widget.house.role == 'admin'
                ? 'Grupo familiar compartilhado.'
                : 'Grupo familiar compartilhado.',
          ),
          const SizedBox(height: 18),
          _SettingsActionCard(
            icon: Icons.sell_rounded,
            title: 'Categorias editaveis',
            subtitle: 'Crie, edite ou remova categorias de entradas e contas.',
            onTap: _openCategories,
          ),
          const SizedBox(height: 12),
          _SettingsActionCard(
            icon: Icons.event_repeat_rounded,
            title: _generating ? 'Gerando...' : 'Gerar proximo mes',
            subtitle: 'Copia lancamentos marcados como recorrentes para o mes seguinte.',
            onTap: _generating ? null : _generateNextMonth,
          ),
          const SizedBox(height: 12),
          _SettingsActionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Controle mensal',
            subtitle: 'Veja historico real, previsao, pagos e pendentes do mes.',
            onTap: _openReports,
          ),
          const SizedBox(height: 12),
          _SettingsActionCard(
            icon: Icons.ios_share_rounded,
            title: 'Compartilhar Oria',
            subtitle: 'Envie um link para alguem criar a propria conta, sem acesso a sua familia.',
            onTap: _openPublicShare,
          ),
          const SizedBox(height: 12),
          _SettingsActionCard(
            icon: Icons.group_add_rounded,
            title: 'Membros e convites',
            subtitle: 'Convide pessoas para acessar tudo que voce ve nessa casa.',
            onTap: _openMembers,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: OriaTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: OriaTheme.blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: OriaTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

