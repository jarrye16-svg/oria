import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/house_member_info.dart';
import '../services/member_service.dart';

class JoinLinkScreen extends StatefulWidget {
  final String token;
  final Future<void> Function() onJoined;

  const JoinLinkScreen({
    super.key,
    required this.token,
    required this.onJoined,
  });

  @override
  State<JoinLinkScreen> createState() => _JoinLinkScreenState();
}

class _JoinLinkScreenState extends State<JoinLinkScreen> {
  final _service = MemberService();

  JoinLinkPreview? _preview;
  bool _loading = true;
  bool _joining = false;
  String? _error;

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
      final preview = await _service.getJoinLinkPreview(widget.token);

      if (!mounted) return;

      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Link invalido ou indisponivel.';
      });
    }
  }

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await _service.acceptJoinLink(widget.token);
      await widget.onJoined();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _joining = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _timeLeft(DateTime? expiresAt) {
    if (expiresAt == null) return '15 min';
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inMinutes <= 0) return 'expirado';
    return '${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final valid = preview != null && preview.status == 'active' && (preview.expiresAt?.isAfter(DateTime.now()) ?? true);

    return Scaffold(
      backgroundColor: OriaTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: OriaTheme.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: OriaTheme.shadow,
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
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
                      'Entrar na familia',
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
                      const Text(
                        'Voce recebeu um link para acessar o grupo:',
                        style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview.houseName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: OriaTheme.blueDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: OriaTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          valid
                              ? 'Link de uso unico. Expira em aproximadamente ${_timeLeft(preview.expiresAt)}.'
                              : 'Este link ja foi usado, cancelado ou expirou.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: valid ? OriaTheme.blueDark : OriaTheme.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _WarningBox(text: _error!),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _loading || _joining || !valid ? null : _join,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(_joining ? 'Entrando...' : 'Entrar na familia'),
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
