import 'package:flutter/material.dart';

class Ativo {
  final String ticker;
  final String quantidade;
  final String precoMedio;
  String precoAtual;

  Ativo({
    required this.ticker,
    required this.quantidade,
    required this.precoMedio,
    required this.precoAtual,
  });
}

class ClasseAtivo {
  final String nome;
  final Color cor;
  final IconData icone;
  final List<Ativo> ativos;

  ClasseAtivo({
    required this.nome,
    required this.cor,
    required this.icone,
    List<Ativo>? ativos,
  }) : ativos = ativos ?? [];
} 