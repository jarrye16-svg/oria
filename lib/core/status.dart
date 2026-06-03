import 'package:flutter/material.dart';

import '../app/theme.dart';

class EntryStatus {
  static const pending = 'pending';
  static const paid = 'paid';
  static const partial = 'partial';
  static const ignored = 'ignored';
  static const canceled = 'canceled';

  static const all = [pending, paid, partial, ignored, canceled];

  static String label(String value) {
    switch (value) {
      case paid:
        return 'Pago/Recebido';
      case partial:
        return 'Parcial';
      case ignored:
        return 'Ignorado no mes';
      case canceled:
        return 'Cancelado';
      default:
        return 'Pendente';
    }
  }

  static Color color(String value) {
    switch (value) {
      case paid:
        return OriaTheme.success;
      case partial:
        return const Color(0xFFCA8A04);
      case ignored:
      case canceled:
        return OriaTheme.muted;
      default:
        return OriaTheme.danger;
    }
  }
}

class EntryType {
  static const income = 'income';
  static const expense = 'expense';

  static const all = [income, expense];

  static String label(String value) => value == income ? 'Entrada' : 'Despesa';
}

class EntryMode {
  static const income = 'income';
  static const fixedExpense = 'fixed_expense';
  static const cardInvoice = 'card_invoice';
  static const thirdParty = 'third_party';
  static const financing = 'financing';
  static const goalContribution = 'goal_contribution';

  static const all = [income, fixedExpense, cardInvoice, goalContribution];

  static String label(String value) {
    switch (value) {
      case income:
        return 'Entrada';
      case cardInvoice:
        return 'Cartao de credito';
      case financing:
        return 'Moto/Carro';
      case goalContribution:
        return 'Porquinho';
      default:
        return 'Contas';
    }
  }

  static IconData icon(String value) {
    switch (value) {
      case income:
        return Icons.south_west_rounded;
      case cardInvoice:
        return Icons.credit_card_rounded;
      case financing:
        return Icons.two_wheeler_rounded;
      case goalContribution:
        return Icons.savings_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
