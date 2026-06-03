import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';

class PasswordResetScreen extends StatefulWidget {
  final Future<void> Function() onDone;

  const PasswordResetScreen({
    super.key,
    required this.onDone,
  });

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _success = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _message = null;
      _success = false;
    });

    try {
      await _auth.updatePassword(_passwordController.text);

      if (!mounted) return;

      setState(() {
        _success = true;
        _message = 'Senha alterada com sucesso. Voce ja pode continuar usando o Oria.';
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
      await widget.onDone();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _success = false;
        _message = 'Nao consegui alterar a senha. Abra o link novamente ou solicite outro e-mail.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    await _auth.signOut();
    await widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OriaTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 88),
                  const SizedBox(height: 24),
                  Container(
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
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Criar nova senha',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: OriaTheme.text,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Digite uma nova senha para acessar o Oria.',
                            style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'A senha precisa ter pelo menos 6 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: const InputDecoration(
                              labelText: 'Confirmar senha',
                              prefixIcon: Icon(Icons.lock_reset_rounded),
                            ),
                            onFieldSubmitted: (_) {
                              if (!_loading) _save();
                            },
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'As senhas nao conferem.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _loading ? null : _save,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                  )
                                : const Text('Salvar nova senha'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading ? null : _cancel,
                            child: const Text('Cancelar'),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 12),
                            _MessageBox(message: _message!, success: _success),
                          ],
                        ],
                      ),
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
      child: Text(
        message,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, height: 1.3),
      ),
    );
  }
}
