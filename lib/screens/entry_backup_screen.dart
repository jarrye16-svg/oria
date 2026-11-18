import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/entry_csv.dart';
import '../core/friendly_error.dart';
import '../models/house.dart';
import '../services/entry_service.dart';

class EntryBackupScreen extends StatefulWidget {
  final House house;
  final Future<void> Function() onChanged;
  const EntryBackupScreen({
    super.key,
    required this.house,
    required this.onChanged,
  });
  @override
  State<EntryBackupScreen> createState() => _EntryBackupScreenState();
}

class _EntryBackupScreenState extends State<EntryBackupScreen> {
  final _text = TextEditingController();
  final _service = EntryService();
  List<Map<String, dynamic>>? _preview;
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _message = null;
      _preview = null;
    });
    try {
      final entries = await _service.getAllEntries(houseId: widget.house.id);
      if (!mounted) return;
      _text.text = exportEntryCsv(entries);
      setState(
        () => _message =
            '${entries.length} lançamentos exportados. Copie o CSV e guarde em um local seguro.',
      );
    } catch (error) {
      if (mounted) setState(() => _message = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _prepare() {
    try {
      final rows = importEntryCsv(_text.text, widget.house.id);
      if (rows.isEmpty)
        throw const FormatException('Nenhum lançamento para importar.');
      setState(() {
        _preview = rows;
        _message = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _preview = null;
        _message = error.message;
      });
    }
  }

  Future<void> _restore() async {
    final rows = _preview;
    if (rows == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _service.restoreEntries(widget.house.id, rows);
      await widget.onChanged();
      if (mounted)
        setState(() {
          _preview = null;
          _message = 'Importação concluída: ${rows.length} lançamentos.';
        });
    } catch (error) {
      if (mounted) setState(() => _message = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cópia dos lançamentos')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Exporte todos os meses ou restaure um CSV desta mesma casa. A restauração atualiza os lançamentos com o mesmo identificador, sem apagar os demais.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Inclui lançamentos. Cartões, categorias e porquinhos vinculados precisam continuar existindo nesta casa.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _export,
          child: const Text('Exportar todos os lançamentos'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 8,
          maxLines: 14,
          enabled: !_busy,
          onChanged: (_) => setState(() => _preview = null),
          decoration: const InputDecoration(
            labelText: 'CSV',
            hintText: 'Cole aqui um CSV exportado pelo Oria',
          ),
        ),
        Wrap(
          spacing: 12,
          children: [
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: _text.text));
                      if (mounted) setState(() => _message = 'CSV copiado.');
                    },
              child: const Text('Copiar CSV'),
            ),
            TextButton(
              onPressed: _busy ? null : _prepare,
              child: const Text('Conferir importação'),
            ),
          ],
        ),
        if (_preview != null) ...[
          Text(
            '${_preview!.length} lançamentos para restaurar em ${widget.house.name}.',
          ),
          ..._preview!
              .take(5)
              .map(
                (row) => ListTile(
                  title: Text(row['title']),
                  subtitle: Text(
                    '${row['competence_month']} · ${row['amount']}',
                  ),
                ),
              ),
          const Text(
            'Os valores existentes desses lançamentos serão substituídos. Confira o CSV antes de confirmar.',
          ),
          FilledButton(
            onPressed: _busy ? null : _restore,
            child: const Text('Confirmar restauração'),
          ),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!),
          ),
      ],
    ),
  );
}
