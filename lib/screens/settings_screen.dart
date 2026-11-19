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
import 'entry_backup_screen.dart';
import 'members_screen.dart';
import 'public_share_screen.dart';
import 'reports_screen.dart';

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
    final next = nextMonth(widget.month);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.event_repeat_rounded, color: OriaTheme.blue),
        title: Text('Preparar ${monthLabel(next)}?'),
        content: const Text(
          'O Oria vai copiar para o próximo mês os lançamentos recorrentes que ainda não estiverem lá. Eles serão criados como pendentes; nenhum pagamento será alterado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Preparar mês'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _generating = true);

    try {
      final count = await _entryService.generateNextMonth(
        houseId: widget.house.id,
        currentMonth: widget.month,
      );

      await widget.onRefresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Nada novo para gerar em ${monthLabel(next)}.'
                : '$count lançamento(s) criado(s) como pendentes em ${monthLabel(next)}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui preparar o próximo mês.')),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PublicShareScreen()));
  }

  void _openMembers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MembersScreen(house: widget.house)),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: OriaTheme.blue),
        title: const Text('Sair do Oria?'),
        content: const Text(
          'Você poderá entrar novamente com seu e-mail e senha. Os dados da casa continuarão salvos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar no Oria'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair da conta'),
          ),
        ],
      ),
    );

    if (confirmed == true) await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService().currentUser?.email ?? 'Conta conectada';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
        children: [
          const PageIntro(
            eyebrow: 'CONFIGURAÇÕES',
            title: 'Ajustes',
            subtitle: 'Organize sua casa, seus lançamentos e sua conta.',
          ),
          const SizedBox(height: 18),
          _HouseSummaryCard(house: widget.house, email: email),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Casa e pessoas',
            subtitle: 'Acesso compartilhado e categorias da casa.',
            children: [
              _SettingsTile(
                icon: Icons.group_add_rounded,
                title: 'Membros e convites',
                subtitle: widget.house.isAdmin
                    ? 'Convide pessoas e gerencie quem acessa esta casa.'
                    : 'Somente administradores podem gerenciar convites.',
                onTap: widget.house.isAdmin ? _openMembers : null,
                locked: !widget.house.isAdmin,
              ),
              _SettingsTile(
                icon: Icons.sell_rounded,
                title: 'Categorias',
                subtitle: widget.house.isAdmin
                    ? 'Crie, edite ou remova categorias de entradas e contas.'
                    : 'Somente administradores podem editar categorias.',
                onTap: widget.house.isAdmin ? _openCategories : null,
                locked: !widget.house.isAdmin,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'Organização financeira',
            subtitle: 'Acompanhe o mês e prepare os próximos lançamentos.',
            children: [
              _SettingsTile(
                icon: Icons.bar_chart_rounded,
                title: 'Controle mensal',
                subtitle: 'Compare previsão, valores pagos e pendências.',
                onTap: _openReports,
              ),
              _SettingsTile(
                icon: Icons.event_repeat_rounded,
                title: _generating ? 'Preparando mês...' : 'Preparar próximo mês',
                subtitle:
                    'Copia as contas recorrentes que ainda não foram lançadas.',
                onTap: _generating ? null : _generateNextMonth,
                loading: _generating,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'Seus dados',
            subtitle: 'Faça uma cópia ou restaure lançamentos desta casa.',
            children: [
              _SettingsTile(
                icon: Icons.save_alt_rounded,
                title: 'Exportar ou restaurar',
                subtitle: 'Baixe uma cópia em CSV ou restaure um arquivo salvo.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EntryBackupScreen(
                      house: widget.house,
                      onChanged: widget.onRefresh,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'Indique o Oria',
            subtitle: 'Compartilhe o app sem compartilhar os dados da sua casa.',
            children: [
              _SettingsTile(
                icon: Icons.ios_share_rounded,
                title: 'Compartilhar o Oria',
                subtitle: 'A outra pessoa cria a própria conta e a própria casa.',
                onTap: _openPublicShare,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AccountCard(email: email, onSignOut: _signOut),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Oria · Sua casa, seu mês, seu controle.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OriaTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseSummaryCard extends StatelessWidget {
  final House house;
  final String email;

  const _HouseSummaryCard({required this.house, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OriaTheme.blue, OriaTheme.blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: OriaTheme.shadow, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  house.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    house.isAdmin ? 'Administrador da casa' : 'Membro da casa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: OriaTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: OriaTheme.cardBorder),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 72),
                    child: Divider(height: 1, color: OriaTheme.cardBorder),
                  ),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool locked;
  final bool loading;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = locked ? OriaTheme.muted : OriaTheme.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: locked ? OriaTheme.background : OriaTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: locked ? OriaTheme.muted : OriaTheme.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: OriaTheme.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                  color: OriaTheme.muted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String email;
  final VoidCallback onSignOut;

  const _AccountCard({required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OriaTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.person_outline_rounded, color: OriaTheme.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua conta',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OriaTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            color: OriaTheme.muted,
          ),
        ],
      ),
    );
  }
}
