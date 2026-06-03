import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/house_service.dart';
import '../widgets/app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onCreated;

  const OnboardingScreen({super.key, required this.onCreated});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _service = HouseService();
  final _controller = TextEditingController(text: 'Minha casa');
  final _familyController = TextEditingController();
  final _codeController = TextEditingController();

  bool _loading = false;
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _familyController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _controller.text.trim();

    if (name.length < 3) {
      setState(() => _error = 'Informe um nome para a casa.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.createHouseWithDefaults(name);
      await widget.onCreated();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nao consegui criar a casa. Confira o Supabase e tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final houseName = _familyController.text.trim();
    final code = _codeController.text.trim();

    if (houseName.length < 3) {
      setState(() => _error = 'Informe o nome da familia.');
      return;
    }

    if (code.replaceAll(RegExp(r'[^0-9]'), '').length != 6) {
      setState(() => _error = 'Informe o codigo de 6 digitos.');
      return;
    }

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await _service.joinHouseWithCode(
        houseName: houseName,
        code: code,
      );
      await widget.onCreated();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OriaTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(),
                  const SizedBox(height: 28),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Comecar no Oria',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crie uma nova casa ou entre em uma familia existente com o codigo do administrador.',
                          style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          initiallyExpanded: true,
                          title: const Text('Entrar em uma familia', style: TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: const Text(
                            'Use o nome da familia e o codigo temporario de 6 digitos.',
                            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            const SizedBox(height: 10),
                            TextField(
                              controller: _familyController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nome da familia',
                                hintText: 'Ex.: Familia Dal Magro',
                                prefixIcon: Icon(Icons.family_restroom_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                counterText: '',
                                labelText: 'Codigo de 6 digitos',
                                prefixIcon: Icon(Icons.password_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _joining ? null : _join,
                              icon: const Icon(Icons.login_rounded),
                              label: Text(_joining ? 'Entrando...' : 'Entrar na familia'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Criar uma nova casa', style: TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: const Text(
                            'Use se voce vai administrar um novo grupo familiar.',
                            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            const SizedBox(height: 10),
                            TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                labelText: 'Nome da casa',
                                hintText: 'Ex.: Casa Jarrye e Thaissa',
                                prefixIcon: Icon(Icons.home_rounded),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loading ? null : _create,
                              child: Text(_loading ? 'Criando...' : 'Criar e entrar'),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: OriaTheme.danger, fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(22),
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
      child: child,
    );
  }
}
