import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/house_member_info.dart';
import '../services/auth_service.dart';
import '../services/member_service.dart';

class InviteJoinScreen extends StatefulWidget {
  final String token;
  final Future<void> Function() onJoined;

  const InviteJoinScreen({
    super.key,
    required this.token,
    required this.onJoined,
  });

  @override
  State<InviteJoinScreen> createState() => _InviteJoinScreenState();
}

class _InviteJoinScreenState extends State<InviteJoinScreen> {
  final _service = MemberService();
  InvitePreview? _preview;
  bool _loading = true;
  bool _joining = false;
  String? _error;

  String get _currentEmail => AuthService().currentUser?.email?.toLowerCase().trim() ?? '';

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final preview = await _service.getInvitePreview(widget.token);

      if (!mounted) return;

      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await _service.acceptInvite(widget.token);
      await widget.onJoined();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _joining = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final emailMatches = preview == null || preview.email.toLowerCase().trim() == _currentEmail;

    return Scaffold(
      backgroundColor: OriaTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: OriaTheme.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: OriaTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(Icons.family_restroom_rounded, color: OriaTheme.blue, size: 36),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Convite recebido',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: CircularProgressIndicator(),
                      )
                    else if (preview != null) ...[
                      Text(
                        'Voce foi convidado para ingressar no grupo:',
                        style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview.houseName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: OriaTheme.blueDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _InfoLine(label: 'E-mail convidado', value: preview.email),
                      _InfoLine(label: 'Voce entrou como', value: _currentEmail),
                      if (!emailMatches) ...[
                        const SizedBox(height: 12),
                        const _WarningBox(
                          text: 'Esse convite pertence a outro e-mail. Saia e entre com o e-mail convidado.',
                        ),
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _WarningBox(text: _error!),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _loading || _joining || !emailMatches ? null : _join,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(_joining ? 'Ingressando...' : 'Ingressar no grupo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair e usar outro e-mail'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  final String text;

  const _WarningBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: OriaTheme.danger, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
      ),
    );
  }
}
