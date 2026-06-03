import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

class PublicShareScreen extends StatelessWidget {
  const PublicShareScreen({super.key});

  static const String publicLink = 'https://jarrye16-svg.github.io/oria/';

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(const ClipboardData(text: publicLink));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copiado.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui copiar automaticamente. Selecione o link e copie manualmente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OriaTheme.background,
      appBar: AppBar(
        title: const Text('Compartilhar Oria'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2453D4), Color(0xFF102B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.ios_share_rounded, color: Colors.white, size: 34),
                  SizedBox(height: 16),
                  Text(
                    'Convide alguem para usar o Oria',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Esse link e para a pessoa criar a propria conta e usar o app dela. Nao da acesso a sua familia.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: OriaTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Link publico do app',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use este link para indicar o Oria para amigos ou familiares que vao criar uma conta separada.',
                    style: TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OriaTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const SelectableText(
                      publicLink,
                      style: TextStyle(
                        color: OriaTheme.blueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copiar link'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: OriaTheme.cardBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quando usar cada convite?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.public_rounded,
                    title: 'Link publico',
                    text: 'Para a pessoa usar o Oria sozinha, com a propria casa.',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.group_add_rounded,
                    title: 'Convite de membro',
                    text: 'Para a pessoa entrar na sua familia e ver os mesmos dados que voce.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: OriaTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: OriaTheme.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
