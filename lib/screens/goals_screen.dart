
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../models/goal.dart';
import '../models/house.dart';
import '../services/goal_service.dart';

class GoalsScreen extends StatefulWidget {
  final House house;
  final Future<void> Function() onRefresh;

  const GoalsScreen({
    super.key,
    required this.house,
    required this.onRefresh,
  });

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _service = GoalService();

  bool _loading = true;
  String? _error;
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final goals = await _service.getGoals(widget.house.id);
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Nao consegui abrir a tela do porquinho agora.';
      });
    }
  }

  Future<void> _reload() async {
    await _load();
    await widget.onRefresh();
  }

  Future<void> _openGoalForm([Goal? goal]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalForm(house: widget.house, goal: goal),
    );

    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _openMovement(Goal goal) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MovementForm(house: widget.house, goal: goal),
    );

    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar porquinho?'),
        content: Text(
          'O porquinho "${goal.name}" será apagado junto com o histórico de aportes e retiradas. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: OriaTheme.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteGoal(goal.id);
      await _reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Porquinho apagado.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui apagar este porquinho. Verifique se você é administrador da casa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 104),
          children: [
            _HeaderCard(
              icon: Icons.savings_rounded,
              eyebrow: 'PORQUINHO',
              title: 'Porquinhos',
              subtitle: 'Acompanhe reservas e objetivos da casa.',
              buttonLabel: 'Nova meta',
              onPressed: () => _openGoalForm(),
            ),
            const SizedBox(height: 8),
            if (_loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            if (_error != null)
              _ErrorCard(
                title: 'Metas indisponiveis',
                message: _error!,
                onRetry: _reload,
              )
            else if (!_loading && _goals.isEmpty)
              _EmptyCard(
                icon: Icons.savings_rounded,
                title: 'Nenhum porquinho criado',
                message: 'Toque em "Nova meta" para criar sua reserva, viagem, reforma ou qualquer objetivo da casa.',
                buttonLabel: 'Criar primeiro porquinho',
                onPressed: () => _openGoalForm(),
              )
            else
              ..._goals.map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: OriaTheme.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: OriaTheme.shadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: OriaTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.savings_rounded, color: OriaTheme.blue),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    goal.ownerName.isEmpty ? 'Casa' : goal.ownerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: OriaTheme.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => _openGoalForm(goal),
                                    icon: const Icon(Icons.edit_rounded, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: OriaTheme.surfaceAlt,
                                      foregroundColor: OriaTheme.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: IconButton(
                                    tooltip: 'Apagar',
                                    onPressed: () => _deleteGoal(goal),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFEDEE),
                                      foregroundColor: OriaTheme.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${money(goal.currentAmount)} de ${money(goal.targetAmount)}',
                          style: const TextStyle(
                            color: OriaTheme.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 8,
                            backgroundColor: OriaTheme.surfaceAlt,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Falta para concluir',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: OriaTheme.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    money(goal.remaining),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: OriaTheme.blueDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _openMovement(goal),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Aporte'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: OriaTheme.blue,
                                side: const BorderSide(color: OriaTheme.cardBorder),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _HeaderCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _HeaderCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2453D4), Color(0xFF102B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            eyebrow,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 21,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: OriaTheme.blueDark,
            ),
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: OriaTheme.blue, size: 34),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _GoalForm extends StatefulWidget {
  final House house;
  final Goal? goal;
  const _GoalForm({required this.house, this.goal});

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final _service = GoalService();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _current = TextEditingController();
  final _owner = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name.text = g?.name ?? '';
    _target.text = g == null ? '' : g.targetAmount.toStringAsFixed(2).replaceAll('.', ',');
    _current.text = g == null ? '0,00' : g.currentAmount.toStringAsFixed(2).replaceAll('.', ',');
    _owner.text = g?.ownerName ?? 'Casa';
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _current.dispose();
    _owner.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2 || parseMoney(_target.text) <= 0) return;
    setState(() => _saving = true);
    try {
      await _service.upsertGoal(
        id: widget.goal?.id,
        houseId: widget.house.id,
        name: _name.text,
        targetAmount: parseMoney(_target.text),
        currentAmount: parseMoney(_current.text),
        ownerName: _owner.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.goal == null ? 'Nova meta' : 'Editar meta',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome da meta'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor alvo', prefixText: 'R\$ '),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _current,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor atual', prefixText: 'R\$ '),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _owner,
                decoration: const InputDecoration(labelText: 'Dono do porquinho'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando...' : 'Salvar meta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementForm extends StatefulWidget {
  final House house;
  final Goal goal;
  const _MovementForm({required this.house, required this.goal});

  @override
  State<_MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends State<_MovementForm> {
  final _service = GoalService();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _kind = 'deposit';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount <= 0) return;
    setState(() => _saving = true);
    try {
      await _service.addMovement(
        houseId: widget.house.id,
        goalId: widget.goal.id,
        amount: amount,
        kind: _kind,
        note: _note.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Movimentar ${widget.goal.name}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'deposit', label: Text('Aporte')),
                ButtonSegment(value: 'withdraw', label: Text('Retirada')),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() => _kind = v.first),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
                inputFormatters: const [MoneyInputFormatter()],
              decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Observacao'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando...' : 'Salvar movimentacao'),
            ),
          ],
        ),
      ),
    );
  }
}
