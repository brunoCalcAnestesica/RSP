import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/ativo.dart';
import 'dart:math';

class BolsaHistoricoMenu extends StatefulWidget {
  final List<ClasseAtivo> classes;
  const BolsaHistoricoMenu({super.key, required this.classes});

  @override
  State<BolsaHistoricoMenu> createState() => _BolsaHistoricoMenuState();
}

class _BolsaHistoricoMenuState extends State<BolsaHistoricoMenu> {
  bool _expanded = false;

  double _valorClasse(ClasseAtivo classe) {
    double total = 0;
    for (var ativo in classe.ativos) {
      final quantidade = double.tryParse(ativo.quantidade.replaceAll(',', '.')) ?? 0;
      final precoMedio = double.tryParse(ativo.precoMedio.replaceAll(',', '.')) ?? 0;
      final precoAtual = double.tryParse(ativo.precoAtual.replaceAll(',', '.')) ?? 0;
      final bool tickerExisteNaPlanilha = ativo.precoAtual.isNotEmpty && ativo.precoAtual != '0,00' && ativo.precoAtual != '0.00' && (precoAtual) > 0;
      if (tickerExisteNaPlanilha) {
        total += quantidade * precoAtual;
      } else {
        total += quantidade * precoMedio;
      }
    }
    return total;
  }

  double get _valorTotalInvestido {
    return widget.classes.fold(0.0, (sum, c) => sum + _valorClasse(c));
  }

  String _formatarReais(double valor) {
    return 'R\$ ' + valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatarCompacto(double valor) {
    if (valor.abs() >= 1e9) {
      return (valor / 1e9).toStringAsFixed(2).replaceAll('.', ',') + ' Bi';
    } else if (valor.abs() >= 1e6) {
      return (valor / 1e6).toStringAsFixed(2).replaceAll('.', ',') + ' Mi';
    } else if (valor.abs() >= 1e3) {
      return (valor / 1e3).toStringAsFixed(2).replaceAll('.', ',') + ' K';
    } else {
      return valor.toStringAsFixed(0);
    }
  }

  String formatarCompacto3Digitos(double valor) {
    if (valor.abs() >= 1e12) {
      return (valor / 1e12).toStringAsFixed(3) + ' Tri';
    } else if (valor.abs() >= 1e9) {
      return (valor / 1e9).toStringAsFixed(3) + ' Bi';
    } else if (valor.abs() >= 1e6) {
      return (valor / 1e6).toStringAsFixed(3) + ' Mi';
    } else if (valor.abs() >= 1e3) {
      return (valor / 1e3).toStringAsFixed(3) + ' K';
    } else {
      return valor.toStringAsFixed(3);
    }
  }

  String _formatarKInteiro(double valor) {
    return valor.abs().toStringAsFixed(0) + 'K';
  }

  // Histórico diário: cada ponto representa um dia
  List<Map<String, dynamic>> _gerarHistoricoFicticio() {
    final hoje = DateTime.now();
    // Exemplo: últimos 7 dias (pode ser ajustado para mais dias se desejar)
    return List.generate(7, (i) {
      final data = hoje.subtract(Duration(days: 6 - i));
      return {'data': data, 'valor': _valorTotalInvestido};
    });
  }

  @override
  Widget build(BuildContext context) {
    final historico = _gerarHistoricoFicticio();
    double minValor = double.infinity;
    double maxValor = 0;
    for (var ponto in historico) {
      final valor = ponto['valor'] as double;
      if (valor < minValor) minValor = valor;
      if (valor > maxValor) maxValor = valor;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gráfico de linhas
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 0.7,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxValor - minValor) / 2),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) => SizedBox(
                                width: 60, // largura fixa para alinhar
                                child: Text(
                                  value.toInt().toString() + 'K',
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              interval: (_valorTotalInvestido * 0.1).clamp(1, double.infinity),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= historico.length) return const SizedBox.shrink();
                                final data = historico[idx]['data'] as DateTime;
                                return Text('${data.day}/${data.month}', style: const TextStyle(fontSize: 10));
                              },
                              interval: 2,
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (historico.length - 1).toDouble(),
                        minY: (_valorTotalInvestido * 0.95).clamp(0, double.infinity),
                        maxY: (_valorTotalInvestido * 1.05).clamp(0, double.infinity),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < historico.length; i++)
                                FlSpot(i.toDouble(), historico[i]['valor'] as double),
                            ],
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.08)),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  formatarCompacto3Digitos(spot.y),
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Menu expansivo
          ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (val) => setState(() => _expanded = val),
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Período: toda semana', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(_formatarReais(_valorTotalInvestido), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.classes.map((classe) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: classe.cor.withOpacity(0.15),
                        radius: 12,
                        child: Icon(classe.icone, color: classe.cor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          classe.nome,
                          style: TextStyle(fontWeight: FontWeight.w500, color: classe.cor),
                        ),
                      ),
                      Text(_formatarReais(_valorClasse(classe)), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget para o gráfico de linhas (colapsado)
class BolsaHistoricoGrafico extends StatelessWidget {
  final List<ClasseAtivo> classes;
  
  const BolsaHistoricoGrafico({super.key, required this.classes});

  double _valorTotalInvestido() {
    double total = 0;
    for (var classe in classes) {
      for (var ativo in classe.ativos) {
        final quantidade = double.tryParse(ativo.quantidade.replaceAll(',', '.')) ?? 0;
        final precoMedio = double.tryParse(ativo.precoMedio.replaceAll(',', '.')) ?? 0;
        final precoAtual = double.tryParse(ativo.precoAtual.replaceAll(',', '.')) ?? 0;
        final bool tickerExisteNaPlanilha = ativo.precoAtual.isNotEmpty && ativo.precoAtual != '0,00' && ativo.precoAtual != '0.00' && (precoAtual) > 0;
        if (tickerExisteNaPlanilha) {
          total += quantidade * precoAtual;
        } else {
          total += quantidade * precoMedio;
        }
      }
    }
    return total;
  }

  String _formatarCompacto(double valor) {
    if (valor.abs() >= 1e9) {
      return (valor / 1e9).toStringAsFixed(2).replaceAll('.', ',') + ' Bi';
    } else if (valor.abs() >= 1e6) {
      return (valor / 1e6).toStringAsFixed(2).replaceAll('.', ',') + ' Mi';
    } else if (valor.abs() >= 1e3) {
      return (valor / 1e3).toStringAsFixed(2).replaceAll('.', ',') + ' K';
    } else {
      return valor.toStringAsFixed(0);
    }
  }

  String formatarCompacto3Digitos(double valor) {
    if (valor.abs() >= 1e12) {
      return (valor / 1e12).toStringAsFixed(3) + ' Tri';
    } else if (valor.abs() >= 1e9) {
      return (valor / 1e9).toStringAsFixed(3) + ' Bi';
    } else if (valor.abs() >= 1e6) {
      return (valor / 1e6).toStringAsFixed(3) + ' Mi';
    } else if (valor.abs() >= 1e3) {
      return (valor / 1e3).toStringAsFixed(3) + ' K';
    } else {
      return valor.toStringAsFixed(3);
    }
  }

  String _formatarKInteiro(double valor) {
    return valor.abs().toStringAsFixed(0) + 'K';
  }

  // Histórico diário: cada ponto representa um dia
  List<Map<String, dynamic>> _gerarHistoricoFicticio() {
    final hoje = DateTime.now();
    // Exemplo: últimos 7 dias (pode ser ajustado para mais dias se desejar)
    return List.generate(7, (i) {
      final data = hoje.subtract(Duration(days: 6 - i));
      return {'data': data, 'valor': _valorTotalInvestido()};
    });
  }

  @override
  Widget build(BuildContext context) {
    final historico = _gerarHistoricoFicticio();
    // Ajuste para minY e maxY quando só há um ponto
    double minY = historico.length == 1 ? (historico[0]['valor'] as double) * 0.95 : historico.map((e) => e['valor'] as double).reduce((a, b) => a < b ? a : b) * 0.95;
    double maxY = historico.length == 1 ? (historico[0]['valor'] as double) * 1.05 : historico.map((e) => e['valor'] as double).reduce((a, b) => a > b ? a : b) * 1.05;
    if (minY == maxY) {
      minY = minY * 0.95;
      maxY = maxY * 1.05;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Histórico Semanal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text('R\$ ${_formatarCompacto(_valorTotalInvestido())}', 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          // Gráfico de linhas
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Text(_formatarKInteiro(value), style: const TextStyle(fontSize: 10)),
                              ),
                              interval: historico.length > 2 ? ((maxY - minY) / 2).clamp(1, double.infinity) : (maxY - minY).clamp(1, double.infinity),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: historico.length > 1,
                              reservedSize: 20,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= historico.length) return const SizedBox.shrink();
                                final data = historico[idx]['data'] as DateTime;
                                return Text('${data.day}/${data.month}', style: const TextStyle(fontSize: 9));
                              },
                              interval: 2,
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (historico.length - 1).toDouble(),
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < historico.length; i++)
                                FlSpot(i.toDouble(), historico[i]['valor'] as double),
                            ],
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.08)),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  formatarCompacto3Digitos(spot.y),
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 