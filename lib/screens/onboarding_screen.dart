import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../services/house_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import 'join_link_screen.dart';
import 'invite_join_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onCreated;
  final VoidCallback? onBack;

  const OnboardingScreen({super.key, required this.onCreated, this.onBack});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _service = HouseService();
  final _controller = TextEditingController(text: 'Minha casa');
  final _familyController = TextEditingController();
  final _codeController = TextEditingController();
  final _linkController = TextEditingController();

  bool? _joiningFamily;
  bool _loading = false;
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _familyController.dispose();
    _codeController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _openInvitation() async {
    final uri = Uri.tryParse(_linkController.text.trim());
    final join = uri?.queryParameters['join'];
    final invite = uri?.queryParameters['invite'];
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.origin != Uri.base.origin ||
        (join?.isNotEmpty != true && invite?.isNotEmpty != true)) {
      setState(() => _error = 'Cole um link de convite válido do Oria.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) {
          Future<void> joined() async {
            Navigator.of(routeContext).pop();
            await widget.onCreated();
          }

          return join?.isNotEmpty == true
              ? JoinLinkScreen(token: join!, onJoined: joined)
              : InviteJoinScreen(token: invite!, onJoined: joined);
        },
      ),
    );
  }

  Future<void> _create() async {
    if (_loading || _joining) return;
    final name = _controller.text.trim();

    if (name.length < 3) {
      setState(() => _error = 'Use pelo menos 3 caracteres no nome da casa.');
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
      setState(
        () => _error = 'Não consegui criar a casa agora. Confira sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    if (_loading || _joining) return;
    final houseName = _familyController.text.trim();
    final code = _codeController.text.trim();

    if (houseName.length < 3) {
      setState(
        () => _error = 'Use pelo menos 3 caracteres no nome da família.',
      );
      return;
    }

    final codeLength = code.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (codeLength != 6 && codeLength != 8) {
      setState(() => _error = 'Informe o código de 6 ou 8 dígitos.');
      return;
    }

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await _service.joinHouseWithCode(houseName: houseName, code: code);
      await widget.onCreated();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is JoinHouseRateLimitException
            ? 'Muitas tentativas. Aguarde 15 minutos antes de tentar outro código.'
            : error is JoinHouseInvalidCodeException
            ? 'Código inválido ou expirado. Confira o nome da família e peça um novo código.'
            : 'Não consegui entrar na família agora. Tente novamente em instantes.',
      );
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
                          'Como você quer começar?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escolha uma opção para organizar as finanças no Oria.',
                          style: TextStyle(
                            color: OriaTheme.muted,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_joiningFamily == null) ...[
                          FilledButton.icon(
                            onPressed: () =>
                                setState(() => _joiningFamily = true),
                            icon: const Icon(Icons.family_restroom_rounded),
                            label: const Text('Entrar em uma família'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _joiningFamily = false),
                            icon: const Icon(Icons.add_home_rounded),
                            label: const Text('Criar uma casa'),
                          ),
                        ],
                        if (_joiningFamily != null)
                          TextButton(
                            onPressed: _loading || _joining
                                ? null
                                : () => setState(() {
                                    _joiningFamily = null;
                                    _error = null;
                                  }),
                            child: const Text('Escolher outra opção'),
                          ),
                        if (_joiningFamily == true)
                          ExpansionTile(
                            onExpansionChanged: (_) =>
                                setState(() => _error = null),
                            tilePadding: EdgeInsets.zero,
                            initiallyExpanded: true,
                            title: const Text(
                              'Entrar em uma família',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: const Text(
                              'Use o link ou código que o administrador da família enviou. Cada pessoa entra com sua própria conta.',
                              style: TextStyle(
                                color: OriaTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 10),
                              TextField(
                                controller: _linkController,
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  labelText: 'Link de convite',
                                  prefixIcon: Icon(Icons.link_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _joining || _loading
                                    ? null
                                    : _openInvitation,
                                child: const Text('Continuar com convite'),
                              ),
                              const SizedBox(height: 18),
                              const Text('Recebeu apenas um código?'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _familyController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nome da família',
                                  hintText: 'Ex.: Família Silva',
                                  prefixIcon: Icon(
                                    Icons.family_restroom_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                maxLength: 8,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  labelText: 'Código de 6 ou 8 dígitos',
                                  prefixIcon: Icon(Icons.password_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _joining || _loading ? null : _join,
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  _joining
                                      ? 'Entrando...'
                                      : 'Entrar na família',
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        if (_joiningFamily == false)
                          ExpansionTile(
                            onExpansionChanged: (_) =>
                                setState(() => _error = null),
                            tilePadding: EdgeInsets.zero,
                            initiallyExpanded: true,
                            title: const Text(
                              'Criar minha casa',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: const Text(
                              'Para começar uma casa nova e convidar sua família depois.',
                              style: TextStyle(
                                color: OriaTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
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
                                onPressed: _loading || _joining
                                    ? null
                                    : _create,
                                child: Text(
                                  _loading ? 'Criando...' : 'Criar e entrar',
                                ),
                              ),
                            ],
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: OriaTheme.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (widget.onBack != null)
                          TextButton.icon(
                            onPressed: _loading || _joining
                                ? null
                                : widget.onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Voltar às minhas casas'),
                          ),
                        TextButton.icon(
                          onPressed: _loading || _joining
                              ? null
                              : () async {
                                  try {
                                    await AuthService().signOut();
                                  } catch (_) {
                                    if (mounted)
                                      setState(
                                        () => _error = 'Não consegui sair. Tente novamente.',
                                      );
                                  }
                                },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sair da conta'),
                        ),
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
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
