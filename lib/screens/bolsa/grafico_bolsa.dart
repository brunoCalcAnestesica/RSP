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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Gráfico centralizado
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16, top: 8),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Center(
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: PizzaChartPainter(
                    classesComValor: classesComValor,
                    valorTotal: valorTotal,
                    classes: classes,
                    context: context,
                  ),
                ),
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

String formatarCompacto(double valor) {
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

class PizzaChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> classesComValor;
  final double valorTotal;
  final List<ClasseAtivo> classes;
  final BuildContext context;

  PizzaChartPainter({
    required this.classesComValor,
    required this.valorTotal,
    required this.classes,
    required this.context,
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

    // Desenhar o círculo central para criar o efeito de rosquinha
    final donutRadius = radius * 0.75; // Furo ainda maior, rosquinha mais fina
    final donutPaint = Paint()
      ..color = Theme.of(context).colorScheme.surface // Cor de fundo do card
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, donutRadius, donutPaint);

    // Desenhar o valor total centralizado
    final textSpan = TextSpan(
      text: 'R\$ ${formatarCompacto(valorTotal)}',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width * 0.7);
    final offset = Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 10);
    textPainter.paint(canvas, offset);

    // Desenhar o texto "Total" abaixo do valor
    final totalSpan = const TextSpan(
      text: 'Total',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey,
        fontWeight: FontWeight.w400,
      ),
    );
    final totalPainter = TextPainter(
      text: totalSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    totalPainter.layout(minWidth: 0, maxWidth: size.width * 0.7);
    // Aumentar o espaçamento vertical para evitar sobreposição
    final totalOffset = Offset(center.dx - totalPainter.width / 2, center.dy + textPainter.height / 2 + 8);
    totalPainter.paint(canvas, totalOffset);
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