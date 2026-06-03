import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import '../models/house.dart';
import '../services/entry_service.dart';
import '../services/goal_service.dart';
import 'cards_screen.dart';
import 'dashboard_screen.dart';
import 'entry_form_screen.dart';
import 'goals_screen.dart';
import 'mode_entries_screen.dart';
import 'month_screen.dart';
import 'paid_entries_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  final House house;

  const ShellScreen({super.key, required this.house});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final _entryService = EntryService();
  final _goalService = GoalService();

  int _index = 0;
  DateTime _month = monthStart(DateTime.now());
  bool _loading = true;
  List<EntryGroup> _groups = [];
  List<Entry> _entries = [];
  double _goalContributions = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final groups = await _entryService.getGroups(widget.house.id);
      final entries = await _entryService.getEntries(
        houseId: widget.house.id,
        month: _month,
      );
      final goalContributions = await _goalService.getMonthContributions(
        houseId: widget.house.id,
        month: _month,
      );

      if (!mounted) return;

      setState(() {
        _groups = groups;
        _entries = entries;
        _goalContributions = goalContributions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Nao consegui carregar os dados agora.';
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
    _load();
  }

  Future<void> _openEntryForm({Entry? entry, String? initialMode}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(
          house: widget.house,
          month: _month,
          groups: _groups,
          entry: entry,
          initialMode: initialMode,
        ),
      ),
    );

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _openModeEntries(String mode) async {
    if (mode == '__paid__') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaidEntriesScreen(
            house: widget.house,
            month: _month,
            groups: _groups,
            entries: _entries,
            onRefresh: _load,
            onPreviousMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
            onEdit: (entry) => _openEntryForm(entry: entry),
          ),
        ),
      );
      await _load();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModeEntriesScreen(
          house: widget.house,
          month: _month,
          mode: mode,
          groups: _groups,
          entries: _entries,
          onRefresh: _load,
          onPreviousMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
          onEdit: (entry) => _openEntryForm(entry: entry),
          onAdd: () => _openEntryForm(initialMode: mode),
        ),
      ),
    );
    await _load();
  }

  Future<void> _onFabPressed() async {
    if (_index == 2) return; // cards screen has its own action button in header
    if (_index == 3) return; // goals screen has its own action button in header
    await _openEntryForm();
  }

  String _fabLabel() {
    switch (_index) {
      case 1:
        return 'Novo';
      case 0:
      default:
        return 'Novo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        house: widget.house,
        month: _month,
        groups: _groups,
        entries: _entries,
        loading: _loading,
        error: _error,
        goalContributions: _goalContributions,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onRefresh: _load,
        onAdd: () => _openEntryForm(),
        onOpenMode: _openModeEntries,
        onAddForMode: (mode) => _openEntryForm(initialMode: mode),
      ),
      MonthScreen(
        house: widget.house,
        month: _month,
        groups: _groups,
        entries: _entries,
        loading: _loading,
        error: _error,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onRefresh: _load,
        onEdit: (entry) => _openEntryForm(entry: entry),
      ),
      CardsScreen(
        house: widget.house,
        entries: _entries,
        onRefresh: _load,
        onEditEntry: (entry) => _openEntryForm(entry: entry),
      ),
      GoalsScreen(
        house: widget.house,
        onRefresh: _load,
      ),
      SettingsScreen(
        house: widget.house,
        month: _month,
        groups: _groups,
        entries: _entries,
        onRefresh: _load,
      ),
    ];

    final showFab = _index != 4 && _index != 2 && _index != 3;

    return Scaffold(
      body: pages[_index],
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: Text(_fabLabel()),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
              elevation: 5,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Mes',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_rounded),
            label: 'Cartoes',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_rounded),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
