import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function() onLoggedIn;
  final bool inviteMode;

  const LoginScreen({
    super.key,
    required this.onLoggedIn,
    this.inviteMode = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _creating = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _successMessage = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    // Em convite, comecamos em Entrar.
    // Se o e-mail ja existir no Supabase, tentar "Criar acesso" gera confusao.
    // Quem nunca usou o Oria ainda pode tocar em "Criar novo acesso".
    if (widget.inviteMode) {
      _creating = false;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _passwordResetRedirectUrl() {
    final base = Uri.base;
    var path = base.path;

    if (path.isEmpty) path = '/';

    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: const {'reset': '1'},
    ).toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _message = null;
      _successMessage = false;
    });

    try {
      if (_creating) {
        final response = await _auth.signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response.session != null) {
          await widget.onLoggedIn();
          return;
        }

        setState(() {
          _successMessage = true;
          _message = 'Acesso criado. Agora tente entrar com este e-mail e senha.';
          _creating = false;
        });
      } else {
        await _auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await widget.onLoggedIn();
      }
    } catch (error) {
      setState(() {
        _successMessage = false;
        _message = _friendlyError(error);

        if (_creating && _isAlreadyRegistered(error)) {
          _creating = false;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (!email.contains('@')) {
      setState(() {
        _successMessage = false;
        _message = 'Informe o e-mail primeiro.';
        });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _successMessage = false;
    });

    try {
      await _auth.resetPassword(
        email: email,
        redirectTo: _passwordResetRedirectUrl(),
      );
      setState(() {
        _successMessage = true;
        _message = 'Se o e-mail estiver cadastrado, enviamos um link para redefinir a senha. Confira tambem o spam/lixo eletronico.';
      });
    } catch (error) {
      setState(() {
        _successMessage = false;
        _message = 'Nao consegui solicitar redefinicao agora.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isAlreadyRegistered(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('already registered') || raw.contains('user already registered');
  }

  String _friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        if (widget.inviteMode) {
          return 'Senha incorreta para este e-mail. Se a pessoa ja tinha cadastro, use a senha antiga ou toque em Esqueci minha senha.';
        }
        return 'E-mail ou senha invalidos.';
      }

      if (message.contains('email not confirmed')) {
        return 'E-mail ainda nao confirmado no Supabase.';
      }

      if (message.contains('signup disabled')) {
        return 'Cadastro esta desativado no Supabase.';
      }

      if (message.contains('already registered') || message.contains('user already registered')) {
        return 'Esse e-mail ja tem cadastro no Oria. Entramos no modo Entrar: use a senha antiga ou toque em Esqueci minha senha.';
      }

      if (message.contains('password')) {
        return 'A senha precisa ter pelo menos 6 caracteres.';
      }

      return error.message;
    }

    final raw = error.toString().toLowerCase();

    if (raw.contains('already registered') || raw.contains('user already registered')) {
      return 'Esse e-mail ja tem cadastro no Oria. Entramos no modo Entrar: use a senha antiga ou toque em Esqueci minha senha.';
    }

    if (raw.contains('invalid login credentials')) {
      if (widget.inviteMode) {
        return 'Senha incorreta para este e-mail. Se a pessoa ja tinha cadastro, use a senha antiga ou toque em Esqueci minha senha.';
      }
      return 'E-mail ou senha invalidos.';
    }

    if (raw.contains('failed to fetch') || raw.contains('xmlhttprequest') || raw.contains('network')) {
      return 'Falha de conexao com o Supabase.';
    }

    return 'Nao consegui concluir agora. Confira os dados e tente novamente.';
  }

  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OriaTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundDecor(),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo(size: 92),
                          const SizedBox(height: 28),
                          _LoginCard(state: this),
                          const SizedBox(height: 16),
                          const Text(
                            'Sua casa, seu mes, seu controle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: OriaTheme.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final _LoginScreenState state;

  const _LoginCard({required this.state});

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
      child: Form(
        key: state._formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state._creating ? 'Criar acesso' : 'Entrar',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: OriaTheme.text,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.widget.inviteMode
                  ? 'Voce recebeu um convite. Se ja usou o Oria, entre com sua senha. Se for novo, crie o acesso.'
                  : 'Acesse o controle financeiro da casa.',
              style: const TextStyle(
                color: OriaTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.widget.inviteMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OriaTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.group_add_rounded, color: OriaTheme.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use o mesmo e-mail do convite. Depois do login, voce confirma a entrada no grupo familiar.',
                        style: TextStyle(color: OriaTheme.blueDark, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (state._creating) ...[
              TextFormField(
                controller: state._nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (value) => (value == null || value.trim().length < 2) ? 'Informe seu nome.' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: state._emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_rounded),
              ),
              validator: (value) => (value == null || !value.contains('@')) ? 'Informe um e-mail valido.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: state._passwordController,
              obscureText: state._obscurePassword,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) {
                if (!state._loading) state._submit();
              },
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () => state.updateState(() => state._obscurePassword = !state._obscurePassword),
                  icon: Icon(
                    state._obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (value) => (value == null || value.length < 6) ? 'A senha precisa ter pelo menos 6 caracteres.' : null,
            ),
            if (state.widget.inviteMode && !state._creating) ...[
              const SizedBox(height: 10),
              const Text(
                'Dica: se aparecer que o e-mail ja existe, nao crie outro. Entre com a senha antiga ou redefina a senha.',
                style: TextStyle(color: OriaTheme.muted, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: state._loading ? null : state._submit,
              child: state._loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(state._creating ? 'Criar acesso' : 'Entrar'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: state._loading
                  ? null
                  : () => state.updateState(() {
                        state._creating = !state._creating;
                        state._message = null;
                        state._successMessage = false;
                      }),
              child: Text(
                state._creating
                    ? 'Ja tenho acesso'
                    : (state.widget.inviteMode ? 'Criar novo acesso' : 'Criar meu acesso'),
              ),
            ),
            if (!state._creating)
              TextButton(
                onPressed: state._loading ? null : state._resetPassword,
                child: Text(state.widget.inviteMode ? 'Nao sei a senha / esqueci minha senha' : 'Esqueci minha senha'),
              ),
            if (state._message != null) ...[
              const SizedBox(height: 12),
              _MessageBox(
                message: state._message!,
                success: state._successMessage,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;
  final bool success;

  const _MessageBox({
    required this.message,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final bg = success ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
    final fg = success ? OriaTheme.success : OriaTheme.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -80,
          right: -70,
          child: _DecorCircle(size: 190, color: Color(0x3322D3EE)),
        ),
        Positioned(
          bottom: -90,
          left: -70,
          child: _DecorCircle(size: 220, color: Color(0x332453D4)),
        ),
      ],
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
