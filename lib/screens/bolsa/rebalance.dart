import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ativo.dart';
import '../../services/bolsa_storage_service.dart';

class RebalanceContainer extends StatefulWidget {
  final List<ClasseAtivo> classes;
  const RebalanceContainer({super.key, required this.classes});

  @override
  State<RebalanceContainer> createState() => _RebalanceContainerState();
}

class _RebalanceContainerState extends State<RebalanceContainer> {
  late List<TextEditingController> _controllers;
  late List<double> _percentuaisDesejados;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _initPercentuais();
  }

  Future<void> _initPercentuais() async {
    final percentuaisSalvos = await BolsaStorageService.loadRebalancePercentuais();
    final percentuaisAtuais = _calcularPercentuaisAtuais();
    setState(() {
      _percentuaisDesejados = percentuaisSalvos != null && percentuaisSalvos.length == widget.classes.length
          ? percentuaisSalvos
          : percentuaisAtuais;
      _controllers = _percentuaisDesejados
          .map((p) => TextEditingController(text: p.toStringAsFixed(1)))
          .toList();
      _carregando = false;
    });
  }

  List<double> _calcularValoresAtuais() {
    final total = widget.classes.fold<double>(0, (sum, c) => sum + _valorClasse(c));
    return widget.classes.map((c) => _valorClasse(c)).toList();
  }

  List<double> _calcularPercentuaisAtuais() {
    final valores = _calcularValoresAtuais();
    final total = valores.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) return List.filled(valores.length, 0);
    return valores.map((v) => (v / total) * 100).toList();
  }

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

  void _onPercentualChanged(int index, String value) {
    setState(() {
      final novo = double.tryParse(value.replaceAll(',', '.')) ?? 0;
      _percentuaisDesejados[index] = novo;
    });
    BolsaStorageService.saveRebalancePercentuais(_percentuaisDesejados);
  }

  String _formatarReais(double valor) {
    final formatador = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 2);
    return formatador.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    final valores = _calcularValoresAtuais();
    final total = valores.fold<double>(0, (sum, v) => sum + v);
    final percentuaisAtuais = _calcularPercentuaisAtuais();
    final somaPercentuaisDesejados = _percentuaisDesejados.fold<double>(0, (sum, v) => sum + v);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rebalanceamento de Carteira',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          ...List.generate(widget.classes.length, (i) {
            final classe = widget.classes[i];
            final valorAtual = valores[i];
            final percentualAtual = percentuaisAtuais[i];
            final percentualAlvo = _percentuaisDesejados[i];
            final valorAlvo = total * percentualAlvo / 100;
            final diff = valorAlvo - valorAtual;
            final diffColor = diff > 0 ? Colors.green[600] : (diff < 0 ? Colors.red[600] : Colors.grey[600]);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: classe.cor.withOpacity(0.15),
                        radius: 14,
                        child: Icon(classe.icone, color: classe.cor, size: 18),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      percentualAtual.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _controllers[i],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      ),
                      onChanged: (value) => _onPercentualChanged(i, value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        (diff > 0 ? '+ ' : (diff < 0 ? '- ' : '')) + _formatarReais(diff.abs()),
                        style: TextStyle(
                          color: diffColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Soma dos alvos: ${somaPercentuaisDesejados.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: somaPercentuaisDesejados == 100 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 