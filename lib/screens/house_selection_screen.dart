import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/house.dart';
import '../widgets/app_logo.dart';

class HouseSelectionScreen extends StatelessWidget {
  final List<House> houses;
  final String? selectedHouseId;
  final ValueChanged<House> onSelected;
  final VoidCallback onAddHouse;

  const HouseSelectionScreen({
    super.key,
    required this.houses,
    this.selectedHouseId,
    required this.onSelected,
    required this.onAddHouse,
  });

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
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: OriaTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: OriaTheme.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: OriaTheme.shadow,
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Escolha uma casa',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sua conta pode acessar sua casa pessoal e as famílias que compartilharam acesso com você. Cada casa mantém seus dados separados.',
                          style: TextStyle(
                            color: OriaTheme.muted,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (var index = 0; index < houses.length; index++) ...[
                          if (index > 0) const SizedBox(height: 10),
                          _HouseChoiceCard(
                            house: houses[index],
                            isCurrent: houses[index].id == selectedHouseId,
                            onTap: () => onSelected(houses[index]),
                          ),
                        ],
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: onAddHouse,
                          icon: const Icon(Icons.add_home_work_rounded),
                          label: const Text(
                            'Entrar em outra família ou criar casa',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
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

class _HouseChoiceCard extends StatelessWidget {
  final House house;
  final bool isCurrent;
  final VoidCallback onTap;

  const _HouseChoiceCard({
    required this.house,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final role = house.isAdmin
        ? 'Administra esta casa'
        : 'Participa desta casa';

    return Material(
      color: OriaTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: OriaTheme.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.home_rounded, color: OriaTheme.blue),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.name,
                      style: const TextStyle(
                        color: OriaTheme.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      style: const TextStyle(
                        color: OriaTheme.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Atual',
                    style: TextStyle(
                      color: OriaTheme.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: OriaTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
