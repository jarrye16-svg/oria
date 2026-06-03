import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';
import '../core/status.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/goal.dart';
import '../models/house.dart';
import '../models/oria_card.dart';
import '../services/auth_service.dart';
import '../services/card_service.dart';
import '../services/entry_service.dart';
import '../services/goal_service.dart';


String _entryCardDisplayName(OriaCardModel card) {
  final name = _entryCleanCardName(card.name, card.ownerName);
  if (card.ownerName.trim().isEmpty) return name;
  return '$name - ${card.ownerName.trim()}';
}

String _entryCleanCardName(String name, String ownerName) {
  var cleaned = name.trim();
  final owner = ownerName.trim();

  if (owner.isEmpty) return cleaned;

  final normalizedCleaned = cleaned.toLowerCase();
  final normalizedOwner = owner.toLowerCase();

  if (normalizedCleaned.endsWith(' $normalizedOwner')) {
    cleaned = cleaned.substring(0, cleaned.length - owner.length).trim();
  }

  if (normalizedCleaned.endsWith('- $normalizedOwner')) {
    cleaned = cleaned.substring(0, cleaned.length - owner.length - 1).trim();
  }

  return cleaned.isEmpty ? name.trim() : cleaned;
}

class EntryFormScreen extends StatefulWidget {
  final House house;
  final DateTime month;
  final List<EntryGroup> groups;
  final Entry? entry;
  final String? initialMode;

  const EntryFormScreen({
    super.key,
    required this.house,
    required this.month,
    required this.groups,
    this.entry,
    this.initialMode,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _auth = AuthService();
  final _service = EntryService();
  final _cardService = CardService();
  final _goalService = GoalService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late List<EntryGroup> _groups;
  late String _mode;
  late String _type;
  late String _status;

  String _incomeDestination = 'home';

  String? _groupId;
  String? _cardId;
  String? _goalId;
  DateTime? _dueDate;
  bool _isRecurring = false;
  bool _saving = false;

  List<OriaCardModel> _cards = [];
  List<Goal> _goals = [];

  bool get _isIncome => _mode == EntryMode.income;
  bool get _isCard => _mode == EntryMode.cardInvoice;
  bool get _isGoal => _mode == EntryMode.goalContribution;
  bool get _usesTag => _mode == EntryMode.fixedExpense;
  bool get _incomeToGoal => _isIncome && _incomeDestination == 'goal';

  bool get _modeLocked => widget.initialMode != null || widget.entry != null;

  String get _currentUserLabel {
    final user = _auth.currentUser;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'usuario logado';
  }

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;
    _groups = List<EntryGroup>.from(widget.groups);

    _titleController = TextEditingController(text: entry?.title ?? '');
    _amountController = TextEditingController(
      text: entry == null ? '' : entry.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');

    _mode = entry?.mode ??
        widget.initialMode ??
        (entry?.type == EntryType.income ? EntryMode.income : EntryMode.fixedExpense);
    _type = entry?.type ?? _typeFromMode(_mode);
    _status = entry?.status ?? _defaultStatusForMode(_mode);
    _groupId = entry?.groupId ?? _defaultGroupId(_type, _mode);
    _cardId = entry?.cardId;
    _goalId = entry?.goalId;
    _incomeDestination = entry?.goalId != null && _mode == EntryMode.income ? 'goal' : 'home';
    _dueDate = entry?.dueDate;
    _isRecurring = entry?.isRecurring ?? false;

    _loadAux();
  }

  Future<void> _loadAux() async {
    try {
      final cards = await _cardService.getCards(widget.house.id);
      final goals = await _goalService.getGoals(widget.house.id);

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _goals = goals;
        _cardId ??= cards.isEmpty ? null : cards.first.id;
        _goalId ??= goals.isEmpty ? null : goals.first.id;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _typeFromMode(String mode) => mode == EntryMode.income ? EntryType.income : EntryType.expense;

  String _defaultStatusForMode(String mode) {
    return mode == EntryMode.income ? EntryStatus.paid : EntryStatus.pending;
  }

  String _statusTitle() {
    if (_isIncome) {
      return _incomeToGoal ? 'Entrada recebida e enviada ao porquinho' : 'Entrada recebida automaticamente';
    }

    return 'Vai entrar como pendente';
  }

  String _statusSubtitle() {
    if (_isIncome) {
      return _incomeToGoal
          ? 'O valor entra como recebido e tambem alimenta o porquinho escolhido.'
          : 'Entradas entram como dinheiro recebido.';
    }

    return 'Depois e so marcar como pago quando quitar.';
  }

  String? _defaultGroupId(String type, String mode) {
    final needles = {
      EntryMode.income: ['entrada', 'receita'],
      EntryMode.cardInvoice: ['cart'],
      EntryMode.financing: ['moto', 'carro', 'financi'],
      EntryMode.goalContribution: ['porquinho', 'meta'],
      EntryMode.fixedExpense: ['casa', 'despesa', 'gasto', 'conta'],
    };

    final modeNeedles = needles[mode] ?? const <String>[];
    for (final needle in modeNeedles) {
      final found = _groups.where((g) => g.kind == type && g.name.toLowerCase().contains(needle)).toList();
      if (found.isNotEmpty) return found.first.id;
    }

    final byKind = _groups.where((group) => group.kind == type).toList();
    return byKind.isEmpty ? null : byKind.first.id;
  }

  String? _resolvedGroupId() {
    if (_usesTag) return _groupId;
    return _defaultGroupId(_type, _mode);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? widget.month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _createTag() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova tag'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome da tag',
              hintText: 'Ex.: Casa, Moto, Mercado',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().length < 2) return;

    setState(() => _saving = true);

    try {
      final created = await _service.createGroup(
        houseId: widget.house.id,
        name: name,
        kind: _type,
      );

      if (!mounted) return;

      setState(() {
        _groups = [..._groups, created];
        _groupId = created.id;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui criar a tag. Talvez ela ja exista.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  OriaCardModel? _selectedCard() {
    for (final card in _cards) {
      if (card.id == _cardId) return card;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCard && _cardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie ou selecione um cartão antes de salvar.')),
      );
      return;
    }

    if ((_isGoal || _incomeToGoal) && _goalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie ou selecione um porquinho antes de salvar.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final amount = parseMoney(_amountController.text);
      final selectedCard = _selectedCard();
      final entryTitle = _isCard
          ? (selectedCard == null ? 'Cartão de crédito' : _entryCardDisplayName(selectedCard))
          : _titleController.text.trim();

      await _service.upsertEntry(
        id: widget.entry?.id,
        houseId: widget.house.id,
        groupId: _resolvedGroupId(),
        title: entryTitle,
        amount: amount,
        type: _type,
        status: _status,
        competenceMonth: widget.month,
        dueDate: _dueDate,
        responsible: null,
        notes: _notesController.text,
        isRecurring: _isRecurring,
        mode: _mode,
        cardId: _isCard ? _cardId : null,
        goalId: (_isGoal || _incomeToGoal) ? _goalId : null,
      );

      if (_incomeToGoal && widget.entry == null) {
        await _goalService.addMovement(
          houseId: widget.house.id,
          goalId: _goalId!,
          amount: amount,
          kind: 'deposit',
          note: 'Entrada direcionada: $entryTitle',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao consegui salvar. Confira os dados e tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lancamento?'),
        content: Text('Isso vai remover "${entry.title}" deste mes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.deleteEntry(entry.id);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _changeMode(String mode) {
    setState(() {
      _mode = mode;
      _type = _typeFromMode(mode);
      _incomeDestination = 'home';
      if (widget.entry == null) {
        _status = _defaultStatusForMode(mode);
      }
      _groupId = _defaultGroupId(_type, mode);
      if (mode == EntryMode.cardInvoice && _cards.isNotEmpty) _cardId ??= _cards.first.id;
      if (mode == EntryMode.goalContribution && _goals.isNotEmpty) _goalId ??= _goals.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _groups.where((group) => group.kind == _type).toList();

    if (_usesTag && _groupId != null && !filteredGroups.any((group) => group.id == _groupId)) {
      _groupId = filteredGroups.isEmpty ? null : filteredGroups.first.id;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Novo' : 'Editar'),
        actions: [
          if (widget.entry != null)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Text(
                  _modeLocked ? _lockedTitle() : 'O que voce vai lancar?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  _modeLocked
                      ? 'Esse lancamento ja esta na area certa. Preencha so o necessario.'
                      : 'Escolha o tipo, informe valor e detalhes.',
                  style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                if (_modeLocked)
                  _LockedModeInfo(mode: _mode)
                else
                  _ModePicker(
                    selected: _mode,
                    onSelected: _changeMode,
                  ),

                const SizedBox(height: 18),

                if (!_isCard) ...[
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      hintText: _hintForMode(),
                      prefixIcon: const Icon(Icons.edit_rounded),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe o nome.' : null,
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: (value) => parseMoney(value ?? '') <= 0 ? 'Informe um valor valido.' : null,
                ),
                const SizedBox(height: 12),

                if (_isIncome) ...[
                  _IncomeDestinationPicker(
                    selected: _incomeDestination,
                    onSelected: (value) => setState(() {
                      _incomeDestination = value;
                      if (value == 'goal' && _goals.isNotEmpty) _goalId ??= _goals.first.id;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_usesTag) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _groupId,
                          decoration: const InputDecoration(
                            labelText: 'Tag',
                            helperText: 'Ex.: Casa, Moto/Carro, Mercado',
                            prefixIcon: Icon(Icons.sell_rounded),
                          ),
                          items: filteredGroups
                              .map((group) => DropdownMenuItem<String?>(
                                    value: group.id,
                                    child: Text(group.name),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _groupId = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: IconButton.filledTonal(
                          onPressed: _saving ? null : _createTag,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Criar tag',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (_isCard) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: _cardId,
                    decoration: const InputDecoration(
                      labelText: 'Cartão lançado',
                      helperText: 'Usaremos o cartão selecionado como nome',
                      prefixIcon: Icon(Icons.credit_card_rounded),
                    ),
                    items: _cards
                        .map((card) => DropdownMenuItem<String?>(
                              value: card.id,
                              child: Text(_entryCardDisplayName(card)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _cardId = value),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_isGoal || _incomeToGoal) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: _goalId,
                    decoration: InputDecoration(
                      labelText: _incomeToGoal ? 'Enviar para qual porquinho?' : 'Porquinho',
                      helperText: _incomeToGoal ? 'O valor tambem sera somado ao porquinho' : 'Esse lancamento ja entra como porquinho',
                      prefixIcon: const Icon(Icons.savings_rounded),
                    ),
                    items: _goals
                        .map((goal) => DropdownMenuItem<String?>(
                              value: goal.id,
                              child: Text(goal.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _goalId = value),
                  ),
                  const SizedBox(height: 12),
                ],

                _StatusInfo(
                  title: _statusTitle(),
                  subtitle: _statusSubtitle(),
                  positive: _isIncome,
                ),
                const SizedBox(height: 12),

                _UserInfo(label: _currentUserLabel),
                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_rounded),
                    title: const Text('Data'),
                    subtitle: Text(dateLabel(_dueDate)),
                    trailing: TextButton(onPressed: _pickDate, child: const Text('Escolher')),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _notesController,
                  minLines: _isCard ? 4 : 2,
                  maxLines: _isCard ? 8 : 4,
                  decoration: InputDecoration(
                    labelText: _isCard ? 'Detalhes da fatura' : 'Observacao',
                    hintText: _isCard
                        ? 'Opcional. Ex.:\nFutebol - R\$ 100,00\nAcademia - R\$ 100,00\nMercado - R\$ 250,00'
                        : 'Opcional',
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repetir todo mes'),
                  subtitle: const Text('Para contas, salarios e gastos recorrentes.'),
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvando...' : 'Salvar'),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _lockedTitle() {
    switch (_mode) {
      case EntryMode.income:
        return widget.entry == null ? 'Nova entrada' : 'Editar entrada';
      case EntryMode.cardInvoice:
        return widget.entry == null ? 'Nova compra no cartão' : 'Editar cartao';
      case EntryMode.goalContribution:
        return widget.entry == null ? 'Novo aporte' : 'Editar porquinho';
      default:
        return widget.entry == null ? 'Nova conta' : 'Editar conta';
    }
  }

  String _hintForMode() {
    switch (_mode) {
      case EntryMode.income:
        return 'Ex.: Salario, extra, decimo';
      case EntryMode.cardInvoice:
        return 'Ex.: Mercado, combustivel, farmacia';
      case EntryMode.goalContribution:
        return 'Ex.: Aporte do mes';
      default:
        return 'Ex.: Luz, internet, aluguel';
    }
  }
}

class _LockedModeInfo extends StatelessWidget {
  final String mode;

  const _LockedModeInfo({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OriaTheme.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(EntryMode.icon(mode), color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label(mode),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String mode) {
    switch (mode) {
      case EntryMode.fixedExpense:
        return 'Contas';
      default:
        return EntryMode.label(mode);
    }
  }
}

class _UserInfo extends StatelessWidget {
  final String label;

  const _UserInfo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: OriaTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lancado por $label',
              style: const TextStyle(
                color: OriaTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeDestinationPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _IncomeDestinationPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destino da entrada',
          style: TextStyle(
            color: OriaTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              selected: selected == 'home',
              showCheckmark: false,
              avatar: Icon(Icons.home_rounded, size: 18, color: selected == 'home' ? Colors.white : OriaTheme.blue),
              label: const Text('Saldo da casa'),
              onSelected: (_) => onSelected('home'),
              selectedColor: OriaTheme.blue,
              backgroundColor: OriaTheme.surfaceAlt,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: selected == 'home' ? Colors.white : OriaTheme.blueDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            ChoiceChip(
              selected: selected == 'goal',
              showCheckmark: false,
              avatar: Icon(Icons.savings_rounded, size: 18, color: selected == 'goal' ? Colors.white : OriaTheme.blue),
              label: const Text('Porquinho'),
              onSelected: (_) => onSelected('goal'),
              selectedColor: OriaTheme.blue,
              backgroundColor: OriaTheme.surfaceAlt,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: selected == 'goal' ? Colors.white : OriaTheme.blueDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool positive;

  const _StatusInfo({
    required this.title,
    required this.subtitle,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE9FFF1) : OriaTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: positive ? const Color(0xFFBBF7D0) : OriaTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: positive ? OriaTheme.success : OriaTheme.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: OriaTheme.text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: OriaTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ModePicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const modes = [
      EntryMode.income,
      EntryMode.fixedExpense,
      EntryMode.cardInvoice,
      EntryMode.goalContribution,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((mode) {
        final isSelected = selected == mode;
        return ChoiceChip(
          selected: isSelected,
          showCheckmark: false,
          avatar: Icon(
            EntryMode.icon(mode),
            size: 18,
            color: isSelected ? Colors.white : OriaTheme.blue,
          ),
          label: Text(EntryMode.label(mode)),
          onSelected: (_) => onSelected(mode),
          selectedColor: OriaTheme.blue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : OriaTheme.blueDark,
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide.none,
          backgroundColor: OriaTheme.surfaceAlt,
        );
      }).toList(),
    );
  }
}
