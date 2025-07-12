import 'package:flutter/material.dart';
import '../configuracoes/configuracoes_screen.dart';
import '../../api/twelve_data_service.dart';
import '../../models/ativo.dart';
import '../../services/bolsa_storage_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart'; // Importa para inputFormatters
import 'dart:async';
import 'grafico_bolsa.dart';
import 'rebalance.dart';
import 'package:intl/intl.dart';
import 'bolsa_historico.dart';
import 'dart:convert'; // Importa para json
import 'package:http/http.dart' as http; // Importa para http
import '../../services/data_cache_service.dart' as cache;

class BolsaScreen extends StatefulWidget {
  const BolsaScreen({super.key});

  @override
  State<BolsaScreen> createState() => _BolsaScreenState();
}

class _BolsaScreenState extends State<BolsaScreen> {
  List<Ativo> _ativos = [];
  List<Ativo> _ativosFiltrados = [];
  bool _isLoading = true;
  bool _isUpdatingPrices = false; // Loading state para atualizações
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  Set<String> _expandedCards = {};
  Timer? _autoUpdateTimer;
  DateTime? _lastManualUpdate;
  final PageController _carouselController = PageController();
  int _currentPage = 0;
  List<String> _tickersDisponiveis = [];
  List<Map<String, dynamic>> _ativosDisponiveis = [];
  bool _isLoadingTickers = false;
  Timer? _twelveDataTimer;
  Timer? _classeCicloTimer;
  int _classeTimerIndex = 0; // Adicionar índice para controlar o ciclo

  // Adicione uma lista de classes disponíveis
  List<ClasseAtivo> _classes = [
    ClasseAtivo(nome: 'Ação', cor: Colors.blue, icone: Icons.show_chart),
    ClasseAtivo(nome: 'FII', cor: Colors.purple, icone: Icons.domain),
    ClasseAtivo(nome: 'ETF', cor: Colors.orange, icone: Icons.pie_chart),
    ClasseAtivo(nome: 'BDR', cor: Colors.teal, icone: Icons.language),
    ClasseAtivo(nome: 'Outro', cor: Colors.grey, icone: Icons.category),
  ];

  // Adicionar variáveis de estado:
  ClasseAtivo? _classeSelecionada;


  @override
  void initState() {
    super.initState();
    _loadAtivos();
    _startAutoUpdateTimer();
    _loadTickersFromAPI();
    _startTwelveDataTimer();
    // Remover atualização inicial de preços - será feita pelo timer cíclico
    _startClasseCicloTimer();
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    _carouselController.dispose();
    _twelveDataTimer?.cancel();
    _classeCicloTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAtivos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Carregar classes e ativos salvos
      final classesSalvas = await BolsaStorageService.loadClasses();
      setState(() {
        _classes = classesSalvas;
        _ativos = [];
        _ativosFiltrados = [];
        _isLoading = false;
      });
      
      // Não importar todos os ativos da API - apenas carregar os que já estão salvos
      // Os ativos serão adicionados apenas quando o usuário adicionar manualmente
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar ativos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterAtivos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _ativosFiltrados = _ativos;
      } else {
        _ativosFiltrados = _ativos.where((ativo) {
          final ticker = ativo.ticker.toLowerCase();
          final searchLower = query.toLowerCase();
          return ticker.contains(searchLower);
        }).toList();
      }
    });
  }

  Widget _buildClassesList() {
    // Verificar se há ativos em alguma classe
    final hasAtivos = _classes.any((classe) => classe.ativos.isNotEmpty);
    
    if (!hasAtivos) {
      return _buildEmptyState();
    }

    return ListView(
      children: [
        ..._classes.map((classe) {
          return ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: classe.cor.withOpacity(0.15),
              child: Icon(classe.icone, color: classe.cor),
            ),
            title: Text(
              classe.nome,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: classe.cor),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Mercado: ' + formatarReais(_valorTotalMercado(classe)),
                style: TextStyle(fontSize: 13, color: classe.cor, fontWeight: FontWeight.bold),
              ),
            ),
            children: [
              ...classe.ativos.map((ativo) => _buildAtivoCard(ativo)).toList(),
              TextButton.icon(
                onPressed: () => _showAddAtivoDialog(classe),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Ativo'),
              ),
            ],
          );
        }).toList(),
        RebalanceContainer(classes: _classes),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum ativo adicionado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seus primeiros ativos para começar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_classes.isNotEmpty) {
                _showAddAtivoDialog(_classes.first);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Primeiro Ativo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Função para atualizar apenas os ativos do usuário
  Future<void> _atualizarMeusAtivos() async {
    setState(() {
      _isUpdatingPrices = true;
    });

    try {
      // Coletar todos os ativos das classes que o usuário possui
      final List<Ativo> ativosDasClasses = [];
      for (var classe in _classes) {
        for (var ativo in classe.ativos) {
          final qtd = double.tryParse(ativo.quantidade.replaceAll(',', '.')) ?? 0;
          if (qtd > 0) {
            ativosDasClasses.add(ativo);
          }
        }
      }

      if (ativosDasClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Você não possui ativos nas classes para atualizar'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final tickers = ativosDasClasses.map((a) => a.ticker).toList();
      print('🔄 Atualizando ${tickers.length} ativos das classes: ${tickers.join(', ')}');
      
      final prices = await TwelveDataService.getPrecosEmLote(tickers);
      
      if (mounted) {
        setState(() {
          // Atualizar preços apenas nas classes
          for (var classe in _classes) {
            for (var ativo in classe.ativos) {
              if (prices.containsKey(ativo.ticker)) {
                ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
              }
            }
          }
        });

        // Mostrar resultado
        final ativosAtualizados = prices.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${ativosAtualizados} ativos das classes atualizados'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao atualizar ativos das classes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPrices = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Bolsa'),
            if (_isUpdatingPrices) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Meus Ativos',
            onPressed: () => _atualizarMeusAtivos(),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Gerenciar Classes',
            onPressed: _showGerenciarClassesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navegar para configurações
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfiguracoesScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isUpdatingPrices = true;
                });
                await _atualizarPrecosAtuais(isManual: true);
                setState(() {
                  _isUpdatingPrices = false;
                });
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                children: [
                  // Carrossel com gráfico e histórico
                  Container(
                    height: 300,
                    child: PageView(
                      controller: _carouselController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                        children: [
                        // Página 1: Gráfico de pizza
                        GraficoBolsa(classes: _classes),
                        // Página 2: Gráfico de linhas total
                        BolsaHistoricoGrafico(classes: _classes),
                      ],
                    ),
                  ),
                  // Indicadores de página
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == 0 ? Colors.blue : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == 1 ? Colors.blue : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                  ),
                  // Remover qualquer Padding/Wrap/ListView/Chip relacionado a _tickersDisponiveis na tela principal
                  // Lista de classes
                  Expanded(
                      child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildClassesList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildIndexCard(String name, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String formatPercent(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',') + '%';
  }

  Ativo? _getAtivoByTicker(String ticker) {
    for (var classe in _classes) {
      for (var ativo in classe.ativos) {
        if (ativo.ticker == ticker) {
          return ativo;
        }
      }
    }
    return null;
  }

  Widget _buildAtivoCard(Ativo ativo) {
    final ticker = ativo.ticker;
    final quantidade = ativo.quantidade;
    final preco = ativo.precoAtual;
    final precoMedio = ativo.precoMedio;

    // Verificar se o ticker tem preço atual válido
    final double? precoAtualNum = _parsePreco(preco);
    final bool tickerTemPreco = preco.isNotEmpty && 
                                preco != '0,00' && 
                                preco != '0.00' && 
                                (precoAtualNum ?? 0) > 0;

    // Cálculos
    final double? quantidadeNum = double.tryParse(quantidade.replaceAll(',', '.')) ?? 0;
    final double? precoMedioNum = double.tryParse(precoMedio.replaceAll(',', '.')) ?? 0;
    final double valorPago = (quantidadeNum ?? 0) * (precoMedioNum ?? 0);
    final double valorMercado = (quantidadeNum ?? 0) * (precoAtualNum ?? 0);
    final double diferenca = valorMercado - valorPago;
    final double percentual = valorPago > 0 ? (diferenca / valorPago) * 100 : 0;

    String formatReais(double valor) {
      return 'R\$ ' + valor.toStringAsFixed(2).replaceAll('.', ',');
    }
    
    Color? diffColor;
    if (diferenca > 0) {
      diffColor = Colors.green[700];
    } else if (diferenca < 0) {
      diffColor = Colors.red[700];
    } else {
      diffColor = Colors.grey[600];
    }

    final bool isExpanded = _expandedCards.contains(ticker);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_expandedCards.contains(ticker)) {
              _expandedCards.remove(ticker);
            } else {
              _expandedCards.add(ticker);
            }
          });
        },
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isExpanded 
            ? (tickerTemPreco 
                ? _buildExpandedCard(ticker, quantidade, preco, precoMedio, quantidadeNum ?? 0, valorPago, valorMercado, diferenca, percentual, diffColor, precoMedioNum ?? 0)
                : _buildExpandedCardSimplificado(ticker, quantidade, precoMedio, quantidadeNum ?? 0, valorPago, precoMedioNum ?? 0))
            : (tickerTemPreco 
                ? _buildCollapsedCard(ticker, preco, diferenca, percentual, diffColor)
                : _buildCollapsedCardSimplificado(ticker, quantidade, precoMedio)),
        ),
      ),
    );
  }

  Widget _buildExpandedCard(String ticker, String quantidade, String preco, String precoMedio, 
                           double? quantidadeNum, double valorPago, double valorMercado, 
                           double diferenca, double percentual, Color? diffColor, double precoMedioNum) {
    String formatReais(double valor) {
      String formatted = valor.toStringAsFixed(2).replaceAll('.', ',');
      if (!formatted.contains(',')) {
        formatted += ',00';
      } else if (formatted.split(',')[1].length == 1) {
        formatted += '0';
      }
      return 'R\$ ' + formatted;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Ticker e Quantidade
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
            child: Text(
                ticker,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                  fontSize: 18,
              ),
            ),
          ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Quantidade: $quantidade',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    print('🔧 Botão de edição pressionado para ticker: $ticker');
                    final ativo = _getAtivoByTicker(ticker);
                    print('🔧 Ativo encontrado: ${ativo?.ticker}');
                    if (ativo != null) {
                      _showEditAtivoDialog(ativo);
                    } else {
                      print('❌ Ativo não encontrado para ticker: $ticker');
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Seção de Preços
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // Linha 1: Títulos das colunas
              Row(
                children: [
                  Expanded(
                  child: Text(
                      'Preço Médio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Preço de Mercado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                  ),
                ),
            ],
          ),
              const SizedBox(height: 8),
              
              // Linha 2: Valores dos preços
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatReais(precoMedioNum),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
            child: Row(
              children: [
                        Expanded(
                          child: Text(
                      'R\$ $preco',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                        ),
                        Icon(
                          diferenca >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: diffColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Linha 3: Valores calculados
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatReais(valorPago),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatReais(valorMercado),
                        style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
                        ],
                      ),
                    ),
        
        const SizedBox(height: 12),
        
        // Seção de Valorização
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: diffColor?.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: diffColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
            ),
          ),
                      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
              Row(
                children: [
                  Icon(
                    diferenca >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: diffColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    diferenca >= 0 ? 'Valorização' : 'Desvalorização',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: diffColor,
                    ),
                  ),
                ],
              ),
              Text(
                (diferenca >= 0 ? '+' : '') + formatReais(diferenca) + ' (' + (diferenca >= 0 ? '+' : '') + formatPercent(percentual) + ')',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: diffColor,
                      ),
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedCard(String ticker, String preco, double diferenca, double percentual, Color? diffColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          ticker,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            Text(
              'R\$ $preco',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              diferenca >= 0 ? Icons.trending_up : Icons.trending_down,
              color: diffColor,
              size: 16,
            ),
            Text(
              (diferenca >= 0 ? '+' : '') + formatPercent(percentual),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: diffColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final ativo = _getAtivoByTicker(ticker);
                if (ativo != null) {
                  _showEditAtivoDialog(ativo);
                }
              },
              icon: const Icon(Icons.edit, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtros'),
          content: const Text('Funcionalidade de filtros será implementada em breve!'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handleAtivoAction(String action, Ativo ativo) {
    switch (action) {
      case 'view':
        _showAtivoDetails(ativo);
        break;
      case 'edit':
        _showEditAtivoDialog(ativo);
        break;
      case 'delete':
        _showDeleteConfirmation(ativo);
        break;
    }
  }

  void _showAtivoDetails(Ativo ativo) {
    final quantidade = ativo.quantidade;
    final precoMedio = ativo.precoMedio;
    final precoAtual = ativo.precoAtual;
    final double? quantidadeNum = double.tryParse(quantidade.replaceAll(',', '.'));
    final double? precoMedioNum = double.tryParse(precoMedio.replaceAll(',', '.'));
    final double? precoAtualNum = double.tryParse(precoAtual.replaceAll(',', '.'));
    final double valorPago = (quantidadeNum ?? 0) * (precoMedioNum ?? 0);
    final double valorMercado = (quantidadeNum ?? 0) * (precoAtualNum ?? 0);
    final double diferenca = valorMercado - valorPago;
    final double percentual = valorPago > 0 ? (diferenca / valorPago) * 100 : 0;
    String formatReais(double valor) {
      String formatted = valor.toStringAsFixed(2).replaceAll('.', ',');
      // Se o valor termina com ",00", mantém, senão adiciona ",00"
      if (!formatted.contains(',')) {
        formatted += ',00';
      } else if (formatted.split(',')[1].length == 1) {
        formatted += '0';
      }
      return 'R\$ ' + formatted;
    }
    String formatPercent(double valor) {
      return valor.toStringAsFixed(2).replaceAll('.', ',') + '%';
    }
    Color? diffColor;
    if (diferenca > 0) {
      diffColor = Colors.green[700];
    } else if (diferenca < 0) {
      diffColor = Colors.red[700];
    } else {
      diffColor = Colors.grey[600];
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ativo.ticker),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantidade: $quantidade'),
                const SizedBox(height: 8),
                Text('Preço Atual: R\$ $precoAtual'),
                const SizedBox(height: 8),
                Text('Preço Médio: R\$ $precoMedio'),
                const SizedBox(height: 8),
                Text('Valor Pago: ' + formatReais(valorPago)),
                const SizedBox(height: 8),
                Text('Valor de Mercado: ' + formatReais(valorMercado)),
                const SizedBox(height: 8),
                Text(
                  (diferenca >= 0 ? '+' : '') + formatReais(diferenca) + ' (' + (diferenca >= 0 ? '+' : '') + formatPercent(percentual) + ')',
                  style: TextStyle(fontWeight: FontWeight.bold, color: diffColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAtivoDialog(Ativo ativo) {
    final precoController = TextEditingController(text: ativo.precoAtual);
    final quantidadeController = TextEditingController(text: ativo.quantidade);
    final precoMedioController = TextEditingController(text: ativo.precoMedio);

    // 4. Ajuste a edição para não tentar mover ativos entre classes.
    // Encontre a classe atual do ativo
    final classeAtual = _classes.firstWhere((c) => c.ativos.any((a) => a.ticker == ativo.ticker));
    String classeSelecionada = classeAtual.nome;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ativo.ticker),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preço Atual',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ' + (precoController.text.isNotEmpty ? precoController.text : '0,00'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Campos Editáveis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMonetaryField(
                  controller: precoMedioController,
                  label: 'Preço Médio',
                  hint: '0,00',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: classeSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Classe do Ativo',
                    border: OutlineInputBorder(),
                  ),
                  items: _classes.map((classe) => DropdownMenuItem(
                    value: classe.nome,
                    child: Text(classe.nome),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        classeSelecionada = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                print('🗑️ Botão Excluir pressionado para ativo: ${ativo.ticker}');
                final classeAtual = _classes.firstWhere((c) => c.ativos.any((a) => a.ticker == ativo.ticker));
                print('🗑️ Classe encontrada: ${classeAtual.nome}');
                _deleteAtivo(classeAtual, ativo);
                _saveData();
                Navigator.of(context).pop();
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                // 2. No update, encontre o ativo na lista da ClasseAtivo e atualize os campos diretamente.
                final classeAtual = _classes.firstWhere((c) => c.ativos.any((a) => a.ticker == ativo.ticker));
                final index = classeAtual.ativos.indexWhere((a) => a.ticker == ativo.ticker);
                if (index != -1) {
                  classeAtual.ativos[index] = Ativo(
                    ticker: ativo.ticker,
                    quantidade: quantidadeController.text.trim(),
                    precoMedio: precoMedioController.text.trim(),
                    precoAtual: precoController.text.trim(),
                  );
                }
                _saveData();
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _updateAtivo(Ativo ativoOriginal, Map<String, dynamic> novosDados) {
    setState(() {
      // Atualizar o ativo na lista
      final index = _ativos.indexWhere((a) => a.ticker == ativoOriginal.ticker);
      if (index != -1) {
        _ativos[index] = Ativo(
          ticker: ativoOriginal.ticker,
          quantidade: novosDados['QUANTIDADE'] ?? '',
          precoMedio: novosDados['PREÇO MÉDIO'] ?? '',
          precoAtual: '0,00', // Garantir que o preço atual seja 0,00
        );
        
        // Atualizar também na lista filtrada
        final filteredIndex = _ativosFiltrados.indexWhere((a) => a.ticker == ativoOriginal.ticker);
        if (filteredIndex != -1) {
          _ativosFiltrados[filteredIndex] = Ativo(
            ticker: ativoOriginal.ticker,
            quantidade: novosDados['QUANTIDADE'] ?? '',
            precoMedio: novosDados['PREÇO MÉDIO'] ?? '',
            precoAtual: '0,00', // Garantir que o preço atual seja 0,00
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ativo ${novosDados['TICKER']} atualizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmation(Ativo ativo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o ativo ${ativo.ticker}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 3. No delete, remova o ativo da lista da ClasseAtivo.
                final classeAtual = _classes.firstWhere((c) => c.ativos.any((a) => a.ticker == ativo.ticker));
                final index = classeAtual.ativos.indexWhere((a) => a.ticker == ativo.ticker);
                if (index != -1) {
                  classeAtual.ativos.removeAt(index);
                }
                _deleteAtivo(classeAtual, ativo);
                await _saveData();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAtivo(ClasseAtivo classe, Ativo ativo) {
    print('🗑️ Iniciando exclusão do ativo: ${ativo.ticker}');
    print('🗑️ Classe antes da exclusão: ${classe.nome} com ${classe.ativos.length} ativos');
    
    setState(() {
      classe.ativos.remove(ativo);
      _ativos.removeWhere((a) => a.ticker == ativo.ticker);
      _ativosFiltrados.removeWhere((a) => a.ticker == ativo.ticker);
    });
    
    print('🗑️ Classe após a exclusão: ${classe.nome} com ${classe.ativos.length} ativos');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ativo ${ativo.ticker} excluído com sucesso!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addAtivo(Map<String, dynamic> dadosEditaveis) {
    // Implementar adição de ativo diretamente no app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de adicionar ativo será implementada em breve.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Função utilitária para calcular o valor de mercado da classe:
  double _valorTotalMercado(ClasseAtivo classe) {
    double total = 0;
    for (var ativo in classe.ativos) {
      final quantidade = double.tryParse(ativo.quantidade.replaceAll(',', '.')) ?? 0;
      final precoMedio = double.tryParse(ativo.precoMedio.replaceAll(',', '.')) ?? 0;
      final precoAtual = _parsePreco(ativo.precoAtual);
      
      // Verificar se o ticker tem preço atual válido
      final bool tickerTemPreco = ativo.precoAtual.isNotEmpty && 
                                  ativo.precoAtual != '0,00' && 
                                  ativo.precoAtual != '0.00' && 
                                  (precoAtual) > 0;
      
      // Se o ticker tem preço atual, usar ele
      if (tickerTemPreco) {
        total += quantidade * precoAtual;
      } else {
        total += quantidade * precoMedio;
      }
    }
    return total;
  }

  // Adicionar função utilitária para formatar reais
  String formatarReais(double valor) {
    final formatador = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 2);
    return formatador.format(valor);
  }

  double _parsePreco(String preco) {
    return double.tryParse(preco.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  }

  // 3. Método para mostrar o diálogo de gerenciamento de classes
  void _showGerenciarClassesDialog() {
    final nomeController = TextEditingController();
    
    // Definir cores disponíveis e sugerir a primeira não usada
    final List<Color> todasCores = [
      Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.grey, Colors.red, Colors.green, Colors.amber, Colors.cyan, Colors.indigo, Colors.pink, Colors.brown, Colors.lime, Colors.deepOrange, Colors.deepPurple, Colors.lightBlue, Colors.lightGreen, Colors.yellow, Colors.black, Colors.blueGrey
    ];
    
    List<Color> coresUsadas = _classes.map((c) => c.cor).toList();
    List<Color> coresDisponiveis = todasCores.where((cor) => !coresUsadas.contains(cor)).toList();
    
    // Sugerir a primeira cor disponível
    Color corSelecionada = coresDisponiveis.isNotEmpty ? coresDisponiveis.first : Colors.blue;
    IconData iconeSelecionado = Icons.category;
    String? erroClasse;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Recalcular cores disponíveis a cada rebuild
            List<Color> coresUsadas = _classes.map((c) => c.cor).toList();
            List<Color> coresDisponiveis = todasCores.where((cor) => !coresUsadas.contains(cor)).toList();
            
            // Se a cor selecionada não está mais disponível, escolher a primeira disponível
            if (!coresDisponiveis.contains(corSelecionada)) {
              corSelecionada = coresDisponiveis.isNotEmpty ? coresDisponiveis.first : Colors.blue;
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.category, size: 28, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          'Gerenciar Classes',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Conteúdo com scroll
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção: Adicionar Nova Classe
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.add_circle, color: Colors.blue, size: 24),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Adicionar Nova Classe',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Campo Nome
                                  TextField(
                                    controller: nomeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome da Classe',
                                      border: OutlineInputBorder(),
                                      hintText: 'Ex: Criptomoedas, REITs...',
                                      prefixIcon: Icon(Icons.edit),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Seleção de Cor e Ícone
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Cor:', style: TextStyle(fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () async {
                                                final picked = await showDialog<Color>(
                                                  context: context,
                                                  builder: (context) {
                                                    Color tempColor = corSelecionada;
        return AlertDialog(
                                                      title: const Text('Escolha uma cor'),
          content: SingleChildScrollView(
                                                        child: BlockPicker(
                                                          pickerColor: tempColor,
                                                          availableColors: coresDisponiveis,
                                                          onColorChanged: (color) {
                                                            tempColor = color;
                                                          },
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(tempColor),
                                                          child: const Text('OK'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                if (picked != null) {
                                                  setState(() {
                                                    corSelecionada = picked;
                                                  });
                                                }
                                              },
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: corSelecionada,
                                                  borderRadius: BorderRadius.circular(25),
                                                  border: Border.all(color: Colors.black26, width: 2),
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 24),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
            child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                            const Text('Ícone:', style: TextStyle(fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () async {
                                                final todosIcones = [
                                                  Icons.show_chart, Icons.domain, Icons.pie_chart, 
                                                  Icons.language, Icons.category, Icons.currency_bitcoin,
                                                  Icons.account_balance, Icons.trending_up, Icons.attach_money,
                                                  Icons.savings, Icons.credit_card, Icons.account_balance_wallet
                                                ];
                                                final iconesUsados = _classes.map((c) => c.icone).toList();
                                                final icons = todosIcones.where((icon) => !iconesUsados.contains(icon)).toList();

                                                final picked = await showDialog<IconData>(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: const Text('Escolha um ícone'),
                                                      content: SizedBox(
                                                        width: 300,
                                                        height: 200,
                                                        child: GridView.builder(
                                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                            crossAxisCount: 4,
                                                            crossAxisSpacing: 8,
                                                            mainAxisSpacing: 8,
                                                          ),
                                                          itemCount: icons.length,
                                                          itemBuilder: (context, index) {
                                                            return GestureDetector(
                                                              onTap: () => Navigator.of(context).pop(icons[index]),
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color: iconeSelecionado == icons[index] 
                                                                      ? Colors.blue.withOpacity(0.2) 
                                                                      : Colors.grey.withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(
                                                                    color: iconeSelecionado == icons[index] 
                                                                        ? Colors.blue 
                                                                        : Colors.transparent,
                                                                  ),
                                                                ),
                                                                child: Icon(icons[index], size: 24),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: const Text('Cancelar'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                if (picked != null) {
                                                  setState(() {
                                                    iconeSelecionado = picked;
                                                  });
                                                }
                                              },
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(25),
                                                  border: Border.all(color: Colors.black26, width: 2),
                                                ),
                                                child: Icon(iconeSelecionado, size: 24),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Botão Adicionar
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final nome = nomeController.text.trim();
                                        final corUsada = _classes.any((c) => c.cor.value == corSelecionada.value);
                                        if (nome.isEmpty || _classes.any((c) => c.nome == nome)) {
                                          setState(() { erroClasse = 'Nome inválido ou já existe.'; });
                                          return;
                                        }
                                        if (corUsada) {
                                          setState(() { erroClasse = 'Esta cor já está sendo usada por outra classe.'; });
                                          return;
                                        }
                                        setState(() {
                                          _classes.add(ClasseAtivo(
                                            nome: nome, 
                                            cor: corSelecionada, 
                                            icone: iconeSelecionado
                                          ));
                                          erroClasse = null;
                                        });
                                        _saveData();
                                        nomeController.clear();
                                        // Resetar para a primeira cor disponível
                                        List<Color> novasCoresUsadas = _classes.map((c) => c.cor).toList();
                                        List<Color> novasCoresDisponiveis = todasCores.where((cor) => !novasCoresUsadas.contains(cor)).toList();
                                        corSelecionada = novasCoresDisponiveis.isNotEmpty ? novasCoresDisponiveis.first : Colors.blue;
                                        iconeSelecionado = Icons.category;
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Adicionar Classe', style: TextStyle(fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (erroClasse != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error, color: Colors.red, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(erroClasse!, style: TextStyle(color: Colors.red, fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Seção: Classes Existentes
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.list, color: Colors.grey, size: 24),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Classes Existentes',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_classes.length}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ..._classes.map((classe) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: classe.cor.withOpacity(0.2),
                                          child: Icon(classe.icone, color: classe.cor, size: 28),
                                        ),
                                        title: Text(
                                          classe.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                                            color: classe.cor,
                                            fontSize: 16,
                  ),
                ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                Text(
                                              '${classe.ativos.length} ativos',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            Text(
                                              'R\$ ' + formatarReais(_valorTotalMercado(classe)),
                  style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: classe.cor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Confirmar Exclusão'),
                                                content: Text('Tem certeza que deseja excluir a classe "${classe.nome}"? Todos os ativos desta classe serão perdidos.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      setState(() {
                                                        _classes.remove(classe);
                                                      });
                                                      await _saveData();
                                                      Navigator.of(context).pop();
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Excluir'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadTickersFromAPI() async {
    setState(() {
      _isLoadingTickers = true;
    });
    try {
      final ativos = await TwelveDataService.getAtivos();
      setState(() {
        _ativosDisponiveis = ativos;
        _tickersDisponiveis = ativos.map((a) => a['ticker'].toString()).toList();
        _isLoadingTickers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTickers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar ativos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'Ação':
        return Colors.blue;
      case 'FII':
        return Colors.purple;
      case 'ETF':
        return Colors.orange;
      case 'Cripto':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showAddAtivoDialog(ClasseAtivo classe) async {
    if (_tickersDisponiveis.isEmpty) {
      // Mostra loading até carregar os tickers
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await _loadTickersFromAPI();
      Navigator.of(context).pop(); // Fecha o loading
    }
    final precoController = TextEditingController(text: '0,00');
    final quantidadeController = TextEditingController(text: '0');
    final precoMedioController = TextEditingController(text: '0,00');
    String tickerSelecionado = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Ativo à ${classe.nome}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preço Atual',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: quantidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMonetaryField(
                  controller: precoMedioController,
                  label: 'Preço Médio',
                  hint: '0,00',
                ),
                const SizedBox(height: 16),
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _ativosDisponiveis.take(10).toList();
                    }
                    return _ativosDisponiveis.where((ativo) {
                      final ticker = ativo['ticker'].toString().toLowerCase();
                      final nome = ativo['nome'].toString().toLowerCase();
                      final searchText = textEditingValue.text.toLowerCase();
                      return ticker.contains(searchText) || nome.contains(searchText);
                    }).take(15).toList();
                  },
                  displayStringForOption: (Map<String, dynamic> option) => option['ticker'],
                  onSelected: (Map<String, dynamic> selection) {
                    tickerSelecionado = selection['ticker'];
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Material(
                      elevation: 4.0,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option['ticker'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(option['nome']),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getTipoColor(option['tipo']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  option['tipo'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                  decoration: const InputDecoration(
                        labelText: 'Buscar Ativo',
                        hintText: 'Digite o ticker ou nome do ativo',
                    border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        tickerSelecionado = value;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final precoAtualNum = _parsePreco(precoController.text);
                final quantidade = double.tryParse(quantidadeController.text.replaceAll(',', '.')) ?? 0;
                final precoMedioNum = double.tryParse(precoMedioController.text.replaceAll(',', '.')) ?? 0;

                if (quantidade == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A quantidade deve ser maior que zero.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final novoAtivo = Ativo(
                  ticker: tickerSelecionado.trim().toUpperCase(),
                  quantidade: quantidadeController.text.trim(),
                  precoMedio: precoMedioController.text.trim(),
                  precoAtual: precoController.text.trim(),
                );

                setState(() {
                  classe.ativos.add(novoAtivo);
                  _ativos.add(novoAtivo);
                  _ativosFiltrados.add(novoAtivo);
                });
                _saveData();
                Navigator.of(context).pop();
              },
              child: const Text('Adicionar Ativo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _atualizarPrecosAtuais({bool isManual = false}) async {
    if (isManual) {
      setState(() {
        _isUpdatingPrices = true;
      });
      _lastManualUpdate = DateTime.now();
    } else {
      // Se for automática, verificar se o usuário atualizou manualmente nos últimos 2 minutos
      if (_lastManualUpdate != null) {
        final difference = DateTime.now().difference(_lastManualUpdate!);
        if (difference.inMinutes < 2) {
          print('⏰ Atualização automática ignorada - usuário atualizou manualmente há ${difference.inMinutes} minutos');
          return;
        }
      }
    }

    try {
      // Atualizar apenas ativos com quantidade > 0
      final ativosComQuantidade = _ativos.where((a) {
        final qtd = double.tryParse(a.quantidade.replaceAll(',', '.')) ?? 0;
        return qtd > 0;
      }).toList();
      
      if (ativosComQuantidade.isEmpty) {
        print('📊 Nenhum ativo com quantidade para atualizar');
        return;
      }
      
      final tickers = ativosComQuantidade.map((ativo) => ativo.ticker).toList();
      print('📊 Atualizando ${tickers.length} ativos');
      final prices = await TwelveDataService.getPrecosEmLote(tickers);
      
      if (mounted) {
        setState(() {
          for (var classe in _classes) {
            for (var ativo in classe.ativos) {
              if (prices.containsKey(ativo.ticker)) {
                ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
              }
            }
          }
          for (var ativo in _ativos) {
            if (prices.containsKey(ativo.ticker)) {
              ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
            }
          }
        });
        
        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${tickers.length} ativos atualizados'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      if (isManual) {
        print('✅ Preços atualizados manualmente');
      } else {
        print('⏰ Preços atualizados automaticamente');
      }
    } catch (e) {
      print('Erro ao atualizar preços: $e');
      if (isManual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao atualizar preços: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (isManual && mounted) {
        setState(() {
          _isUpdatingPrices = false;
        });
      }
    }
  }

  Future<void> _atualizarPrecosClasseSelecionada({bool isManual = false}) async {
    if (_classeSelecionada == null) return;
    try {
      if (isManual) {
        _lastManualUpdate = DateTime.now();
      } else if (_lastManualUpdate != null) {
        final difference = DateTime.now().difference(_lastManualUpdate!);
        if (difference.inMinutes < 2) return;
      }
      final tickers = _classeSelecionada!.ativos.map((a) => a.ticker).toList();
      final prices = await TwelveDataService.getPrecosEmLote(tickers);
      if (mounted) {
        setState(() {
          for (var ativo in _classeSelecionada!.ativos) {
            if (prices.containsKey(ativo.ticker)) {
              ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
            }
          }
        });
      }
    } catch (e) {
      print('Erro ao atualizar preços da classe: $e');
    }
  }

  void _startAutoUpdateTimer() {
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _atualizarPrecosAtuais();
    });
  }

  void _startTwelveDataTimer() {
    _twelveDataTimer = Timer.periodic(const Duration(minutes: 20), (timer) {
      _updateTwelveDataPrices();
    });
  }

  Future<void> _updateTwelveDataPrices() async {
    try {
      // Atualizar apenas ativos com quantidade > 0
      final ativosComQuantidade = _ativos.where((a) {
        final qtd = double.tryParse(a.quantidade.replaceAll(',', '.')) ?? 0;
        return qtd > 0;
      }).toList();
      
      if (ativosComQuantidade.isEmpty) {
        print('📊 Nenhum ativo com quantidade para atualizar inicialmente');
        return;
      }
      
      final tickers = ativosComQuantidade.map((ativo) => ativo.ticker).toList();
      print('📊 Atualizando ${tickers.length} ativos inicialmente');
      final prices = await TwelveDataService.getPrecosEmLote(tickers);
      
      setState(() {
        for (var classe in _classes) {
          for (var ativo in classe.ativos) {
            if (prices.containsKey(ativo.ticker)) {
              ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
            }
          }
        }
        for (var ativo in _ativos) {
          if (prices.containsKey(ativo.ticker)) {
            ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
          }
        }
      });
    } catch (e) {
      print('Erro ao atualizar preços via Twelve Data: $e');
    }
  }

  String _getTwelveDataSymbol(String ticker) {
    // Mapear tickers para o formato esperado pela API
    if (ticker == 'BTC') return 'BTC/BRL';
    if (ticker == 'USDT') return 'USDT/BRL';
    return ticker.endsWith('.SA') ? ticker : ticker + '.SA';
  }

  Future<void> _saveData() async {
    try {
      await BolsaStorageService.saveClasses(_classes);
    } catch (e) {
      print('Erro ao salvar dados: $e');
    }
  }

  // Widget personalizado para campos monetários
  Widget _buildMonetaryField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixText: 'R\$',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      onChanged: (value) {
        // Permitir apenas uma vírgula ou ponto
        final commaCount = value.split(',').length - 1;
        final dotCount = value.split('.').length - 1;
        
        if (commaCount > 1 || dotCount > 1) {
          // Remover caracteres extras
          final cleanValue = value.replaceAll(',', '').replaceAll('.', '');
          controller.text = cleanValue;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: cleanValue.length),
          );
        }
      },
    );
  }

  Widget _buildExpandedCardSimplificado(String ticker, String quantidade, String precoMedio, 
                                       double? quantidadeNum, double valorPago, double precoMedioNum) {
    String formatReais(double valor) {
      String formatted = valor.toStringAsFixed(2).replaceAll('.', ',');
      if (!formatted.contains(',')) {
        formatted += ',00';
      } else if (formatted.split(',')[1].length == 1) {
        formatted += '0';
      }
      return 'R\$ ' + formatted;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Ticker, Quantidade e Botão Editar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ticker,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qtd: $quantidade',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final ativo = _getAtivoByTicker(ticker);
                    if (ativo != null) {
                      _showEditAtivoDialog(ativo);
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Seção de Dados Básicos
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Preço Médio',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formatReais(precoMedioNum),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                formatReais(valorPago),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedCardSimplificado(String ticker, String quantidade, String precoMedio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticker,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Qtd: $quantidade • PM: R\$ $precoMedio',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                'Aguardando',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final ativo = _getAtivoByTicker(ticker);
                if (ativo != null) {
                  _showEditAtivoDialog(ativo);
                }
              },
              icon: const Icon(Icons.edit, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  void _startClasseCicloTimer() {
    _classeCicloTimer?.cancel();
    _classeCicloTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_classes.isEmpty) return;
      final idx = _classeTimerIndex % _classes.length;
      final classe = _classes[idx];
      print('⏰ Atualizando preços da classe: ${classe.nome}');
      _atualizarPrecosPorClasse(classe);
      _classeTimerIndex = (_classeTimerIndex + 1) % _classes.length;
    });
  }

  Future<void> _atualizarPrecosPorClasse(ClasseAtivo classe) async {
    try {
      // Filtrar apenas ativos com quantidade > 0 (adicionados pelo usuário)
      final ativosComQuantidade = classe.ativos.where((a) {
        final qtd = double.tryParse(a.quantidade.replaceAll(',', '.')) ?? 0;
        return qtd > 0;
      }).toList();
      
      if (ativosComQuantidade.isEmpty) {
        print('⏰ Nenhum ativo com quantidade na classe: ${classe.nome}');
        return;
      }
      
      final tickers = ativosComQuantidade.map((a) => a.ticker).toList();
      print('⏰ Atualizando ${tickers.length} ativos da classe: ${classe.nome}');
      final prices = await TwelveDataService.getPrecosEmLote(tickers);
      
      if (mounted) {
        setState(() {
          for (var ativo in ativosComQuantidade) {
            if (prices.containsKey(ativo.ticker)) {
              ativo.precoAtual = prices[ativo.ticker]!.toStringAsFixed(2).replaceAll('.', ',');
            }
          }
        });
      }
    } catch (e) {
      print('Erro ao atualizar preços da classe: $e');
    }
  }
}

 
 
 