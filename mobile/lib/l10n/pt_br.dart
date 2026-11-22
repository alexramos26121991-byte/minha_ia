/// Formatação e locale do português do Brasil usados em toda a aplicação.
library;

import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

/// Locale fixo do produto: todo o app é pt-BR, sem seletor de idioma.
const Locale ptBrLocale = Locale('pt', 'BR');

final NumberFormat _reais = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

final DateFormat _dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

/// Formata valores monetários no padrão brasileiro (R$ 1.234,56).
String formatarReais(num valor) => _reais.format(valor);

/// Formata datas e horas no padrão brasileiro (dd/MM/yyyy HH:mm).
String formatarDataHora(DateTime valor) => _dataHora.format(valor.toLocal());

/// Rótulo relativo curto, em pt-BR, para itens da galeria.
String formatarRelativo(DateTime criadoEm, {DateTime? agora}) {
  final diferenca = (agora ?? DateTime.now()).difference(criadoEm);
  if (diferenca.inMinutes < 1) return 'Agora';
  if (diferenca.inHours < 1) return '${diferenca.inMinutes} min';
  if (diferenca.inDays < 1) return '${diferenca.inHours} h';
  if (diferenca.inDays == 1) return 'Ontem';
  return '${diferenca.inDays} dias';
}
