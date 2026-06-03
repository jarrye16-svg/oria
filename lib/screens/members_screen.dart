import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../models/house.dart';
import '../models/house_member_info.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';

class MembersScreen extends StatefulWidget {
  final House house;

  const MembersScreen({super.key, required this.house});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _service = MemberService();
  final _emailController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _lastInviteLink;
  CreatedJoinCode? _joinCode;
  String? _lastJoinLink;
  List<HouseMemberInfo> _members = [];
  List<HouseInviteInfo> _invites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final members = await _service.getMembers(widget.house.id);
      final invites = await _service.getInvites(widget.house.id);

      if (!mounted) return;

      setState(() {
        _members = members;
        _invites = invites;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Nao consegui carregar membros agora. Tente novamente em instantes.';
      });
    }
  }

  Future<void> _createJoinCode() async {
    setState(() {
      _saving = true;
      _joinCode = null;
      _lastJoinLink = null;
    });

    try {
      final code = await _service.createJoinCode(widget.house.id);

      if (!mounted) return;

      setState(() {
        _joinCode = code;
        _lastJoinLink = _service.buildJoinLink(code.token);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codigo temporario gerado.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao consegui gerar codigo: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createInvite() async {
    final email = _emailController.text.trim().toLowerCase();

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um e-mail valido.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _lastInviteLink = null;
    });

    try {
      final invite = await _service.createInvite(
        houseId: widget.house.id,
        email: email,
      );
      final link = _service.buildInviteLink(invite.token);

      if (!mounted) return;

      setState(() {
        _lastInviteLink = link;
        _emailController.clear();
      });

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite criado. Copie o link exibido na tela.'),
          duration: Duration(seconds: 6),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar convite: $message'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copiado.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui copiar automaticamente. Selecione e copie manualmente.')),
      );
    }
  }

  Future<void> _cancelInvite(HouseInviteInfo invite) async {
    setState(() => _saving = true);

    try {
      await _service.cancelInvite(invite.id);
      await _load();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui cancelar o convite.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeRole(HouseMemberInfo member) async {
    final nextRole = member.role == 'admin' ? 'member' : 'admin';

    setState(() => _saving = true);

    try {
      await _service.updateMemberRole(
        houseId: widget.house.id,
        userId: member.userId,
        role: nextRole,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao consegui alterar a permissao: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeMember(HouseMemberInfo member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover membro?'),
        content: Text('Isso remove o acesso de ${member.email} a esta casa.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remover')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);

    try {
      await _service.removeMember(
        houseId: widget.house.id,
        userId: member.userId,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao consegui remover o membro: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _inviteLink(HouseInviteInfo invite) => _service.buildInviteLink(invite.token);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membros')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              if (_loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              if (_error != null) ...[
                _NoticeCard(
                  icon: Icons.warning_rounded,
                  title: 'Membros indisponiveis',
                  subtitle: _error!,
                ),
                const SizedBox(height: 12),
              ],
              _JoinCodeCard(
                houseName: widget.house.name,
                saving: _saving,
                code: _joinCode,
                onGenerate: _createJoinCode,
                joinLink: _lastJoinLink,
                onCopyCode: _lastJoinLink == null ? null : () => _copy(_lastJoinLink!),
              ),
              const SizedBox(height: 14),
              _InviteCard(
                controller: _emailController,
                saving: _saving,
                onCreate: _createInvite,
                lastInviteLink: _lastInviteLink,
                onCopyLast: _lastInviteLink == null ? null : () => _copy(_lastInviteLink!),
              ),
              const SizedBox(height: 14),
              _MembersCard(
                house: widget.house,
                currentUserId: AuthService().currentUser?.id,
                members: _members,
                onChangeRole: _changeRole,
                onRemove: _removeMember,
              ),
              const SizedBox(height: 14),
              _InvitesCard(
                invites: _invites,
                linkFor: _inviteLink,
                onCopy: _copy,
                onCancel: _cancelInvite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinCodeCard extends StatelessWidget {
  final String houseName;
  final bool saving;
  final CreatedJoinCode? code;
  final String? joinLink;
  final VoidCallback onGenerate;
  final VoidCallback? onCopyCode;

  const _JoinCodeCard({
    required this.houseName,
    required this.saving,
    required this.code,
    required this.joinLink,
    required this.onGenerate,
    required this.onCopyCode,
  });

  String _expiresLabel(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    final minutes = diff.inMinutes <= 0 ? 0 : diff.inMinutes;
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Entrada por codigo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Gere um link temporario para a pessoa entrar direto nesta familia. O link vale 15 minutos e so pode ser usado uma vez.',
            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OriaTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Familia: $houseName',
              style: const TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: saving ? null : onGenerate,
            icon: const Icon(Icons.password_rounded),
            label: Text(saving ? 'Gerando...' : 'Gerar link temporario'),
          ),
          if (code != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OriaTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                joinLink ?? '',
                style: const TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Valido por aproximadamente ${_expiresLabel(code!.expiresAt)} • uso unico',
                style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCopyCode,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar link'),
            ),
            const SizedBox(height: 8),
            const Text(
              'A pessoa abre o link, entra/cria acesso e confirma a entrada nesta familia.',
              style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onCreate;
  final String? lastInviteLink;
  final VoidCallback? onCopyLast;

  const _InviteCard({
    required this.controller,
    required this.saving,
    required this.onCreate,
    required this.lastInviteLink,
    required this.onCopyLast,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: const Text('Convite por link/e-mail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        subtitle: const Text(
          'Opcional. Use se quiser travar o convite para um e-mail especifico.',
          style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
        ),
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail do membro',
              prefixIcon: Icon(Icons.mail_rounded),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: saving ? null : onCreate,
            icon: const Icon(Icons.link_rounded),
            label: Text(saving ? 'Criando...' : 'Gerar link'),
          ),
          if (lastInviteLink != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Envie este link para a pessoa. Ela precisa entrar/criar acesso com o mesmo e-mail informado no convite.',
              style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SelectableText(
              lastInviteLink!,
              style: const TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCopyLast,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar link'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  final House house;
  final String? currentUserId;
  final List<HouseMemberInfo> members;
  final Future<void> Function(HouseMemberInfo member) onChangeRole;
  final Future<void> Function(HouseMemberInfo member) onRemove;

  const _MembersCard({
    required this.house,
    required this.currentUserId,
    required this.members,
    required this.onChangeRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Acessos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (members.isEmpty)
            const Text('Nenhum membro encontrado.', style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600))
          else
            ...members.map((member) {
              final isSelf = member.userId == currentUserId;
              final canManage = house.isAdmin && !isSelf;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(
                  member.fullName?.trim().isNotEmpty == true ? member.fullName! : member.email,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${member.email} • ${member.role == 'admin' ? 'Administrador' : 'Membro'}${isSelf ? ' • você' : ''}',
                ),
                trailing: canManage
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'role') onChangeRole(member);
                          if (value == 'remove') onRemove(member);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'role',
                            child: Text(member.role == 'admin' ? 'Tornar membro' : 'Tornar admin'),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remover acesso'),
                          ),
                        ],
                      )
                    : null,
              );
            }),
        ],
      ),
    );
  }
}

class _InvitesCard extends StatelessWidget {
  final List<HouseInviteInfo> invites;
  final String Function(HouseInviteInfo invite) linkFor;
  final Future<void> Function(String value) onCopy;
  final Future<void> Function(HouseInviteInfo invite) onCancel;

  const _InvitesCard({
    required this.invites,
    required this.linkFor,
    required this.onCopy,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final active = invites.where((i) => i.status == 'active').toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Convites por link pendentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (active.isEmpty)
            const Text('Nenhum convite por link pendente.', style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600))
          else
            ...active.map((invite) {
              final link = linkFor(invite);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.mark_email_unread_rounded)),
                title: Text(invite.email, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Link de convite ativo'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Copiar link',
                      onPressed: () => onCopy(link),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    IconButton(
                      tooltip: 'Cancelar',
                      onPressed: () => onCancel(invite),
                      icon: const Icon(Icons.close_rounded),
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
  final IconData icon;
  final String title;
  final String subtitle;

  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: OriaTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: child,
    );
  }
}
