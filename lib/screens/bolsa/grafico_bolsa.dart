import 'package:flutter/material.dart';
import '../../models/ativo.dart';

class GraficoBolsa extends StatelessWidget {
  final List<ClasseAtivo> classes;

  const GraficoBolsa({
    super.key,
    required this.classes,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular valores totais de cada classe
    final valoresClasses = _calcularValoresClasses();
    final valorTotal = valoresClasses.values.fold(0.0, (sum, value) => sum + value);

    // Filtrar apenas classes que têm valor
    final classesComValor = valoresClasses.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (classesComValor.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Nenhum ativo encontrado',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Gráfico de pizza
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                                 CustomPaint(
                   size: const Size(150, 150),
                   painter: PizzaChartPainter(
                     classesComValor: classesComValor,
                     valorTotal: valorTotal,
                     classes: classes,
                   ),
                 ),
                // Valor total no centro
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$ ${_formatarValor(valorTotal)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Legenda
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: classesComValor.map((entry) {
                  final classe = classes.firstWhere((c) => c.nome == entry.key);
                  final valor = entry.value;
                  final percentual = valorTotal > 0 ? (valor / valorTotal) * 100 : 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: classe.cor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classe.nome,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'R\$ ${_formatarValor(valor)} (${percentual.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calcularValoresClasses() {
    final Map<String, double> valores = {};
    
    for (var classe in classes) {
      double total = 0;
      for (var ativo in classe.ativos) {
        final quantidade = double.tryParse(ativo.quantidade.replaceAll(',', '.')) ?? 0;
        final precoMedio = double.tryParse(ativo.precoMedio.replaceAll(',', '.')) ?? 0;
        final precoAtual = double.tryParse(ativo.precoAtual.replaceAll(',', '.')) ?? 0;
        
        // Verificar se o ticker existe na planilha (tem preço atual válido)
        final bool tickerExisteNaPlanilha = ativo.precoAtual.isNotEmpty && 
                                           ativo.precoAtual != '0,00' && 
                                           ativo.precoAtual != '0.00' && 
                                           (precoAtual) > 0;
        
        // Se o ticker não está na planilha, usar preço médio
        if (tickerExisteNaPlanilha) {
          total += quantidade * precoAtual;
        } else {
          total += quantidade * precoMedio;
        }
      }
      valores[classe.nome] = total;
    }
    
    return valores;
  }

  String _formatarValor(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class PizzaChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> classesComValor;
  final double valorTotal;
  final List<ClasseAtivo> classes;

  PizzaChartPainter({
    required this.classesComValor,
    required this.valorTotal,
    required this.classes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (classesComValor.isEmpty || valorTotal <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8; // 80% do tamanho disponível

    double startAngle = -90 * (3.14159 / 180); // Começar do topo

    for (var entry in classesComValor) {
      final valor = entry.value;
      final sweepAngle = (valor / valorTotal) * 2 * 3.14159;

      // Encontrar a cor da classe
      final cor = _getCorClasse(entry.key);

      final paint = Paint()
        ..color = cor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  Color _getCorClasse(String nomeClasse) {
    // Encontrar a classe pelo nome e retornar sua cor
    final classe = classes.firstWhere(
      (c) => c.nome == nomeClasse,
      orElse: () => ClasseAtivo(nome: nomeClasse, cor: Colors.grey, icone: Icons.category),
    );
    return classe.cor;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 