import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class TwelveDataService {
  static const String _apiKey = '80def4ab34e84758998a8ad4e0fbe26d'; // Chave fornecida pelo usuário
  static const String _baseUrl = 'https://api.twelvedata.com';
  
  // Lista de ativos brasileiros pré-definidos (sem duplicatas)
  static const List<Map<String, dynamic>> _ativosBrasileiros = [
    // Ações Brasileiras
    {'ticker': 'PETR4', 'nome': 'Petrobras PN', 'tipo': 'Ação'},
    {'ticker': 'VALE3', 'nome': 'Vale ON', 'tipo': 'Ação'},
    {'ticker': 'ITUB4', 'nome': 'Itaú Unibanco PN', 'tipo': 'Ação'},
    {'ticker': 'BBDC4', 'nome': 'Bradesco PN', 'tipo': 'Ação'},
    {'ticker': 'ABEV3', 'nome': 'Ambev ON', 'tipo': 'Ação'},
    {'ticker': 'WEGE3', 'nome': 'WEG ON', 'tipo': 'Ação'},
    {'ticker': 'RENT3', 'nome': 'Localiza ON', 'tipo': 'Ação'},
    {'ticker': 'LREN3', 'nome': 'Lojas Renner ON', 'tipo': 'Ação'},
    {'ticker': 'MGLU3', 'nome': 'Magazine Luiza ON', 'tipo': 'Ação'},
    {'ticker': 'JBSS3', 'nome': 'JBS ON', 'tipo': 'Ação'},
    {'ticker': 'RAIL3', 'nome': 'Rumo ON', 'tipo': 'Ação'},
    {'ticker': 'CCRO3', 'nome': 'CCR ON', 'tipo': 'Ação'},
    {'ticker': 'EMBR3', 'nome': 'Embraer ON', 'tipo': 'Ação'},
    {'ticker': 'SUZB3', 'nome': 'Suzano ON', 'tipo': 'Ação'},
    {'ticker': 'GGBR4', 'nome': 'Gerdau PN', 'tipo': 'Ação'},
    {'ticker': 'CSAN3', 'nome': 'Cosan ON', 'tipo': 'Ação'},
    {'ticker': 'USIM5', 'nome': 'Usiminas PNA', 'tipo': 'Ação'},
    {'ticker': 'CSNA3', 'nome': 'CSN ON', 'tipo': 'Ação'},
    {'ticker': 'GOAU4', 'nome': 'Gerdau Met PN', 'tipo': 'Ação'},
    {'ticker': 'CESP6', 'nome': 'CESP PNB', 'tipo': 'Ação'},
    {'ticker': 'HYPE3', 'nome': 'Hypera ON', 'tipo': 'Ação'},
    {'ticker': 'IRBR3', 'nome': 'IRB Brasil ON', 'tipo': 'Ação'},
    {'ticker': 'QUAL3', 'nome': 'Qualicorp ON', 'tipo': 'Ação'},
    {'ticker': 'CVCB3', 'nome': 'CVC Brasil ON', 'tipo': 'Ação'},
    {'ticker': 'AZUL4', 'nome': 'Azul PN', 'tipo': 'Ação'},
    {'ticker': 'GOLL4', 'nome': 'Gol PN', 'tipo': 'Ação'},
    {'ticker': 'SMTO3', 'nome': 'São Martinho ON', 'tipo': 'Ação'},
    {'ticker': 'MRFG3', 'nome': 'Marfrig ON', 'tipo': 'Ação'},
    {'ticker': 'BRFS3', 'nome': 'BRF ON', 'tipo': 'Ação'},
    {'ticker': 'JHSF3', 'nome': 'JHSF ON', 'tipo': 'Ação'},
    {'ticker': 'CYRE3', 'nome': 'Cyrela ON', 'tipo': 'Ação'},
    {'ticker': 'MRVE3', 'nome': 'MRV ON', 'tipo': 'Ação'},
    {'ticker': 'TEND3', 'nome': 'Tenda ON', 'tipo': 'Ação'},
    {'ticker': 'CRFB3', 'nome': 'Carrefour Brasil ON', 'tipo': 'Ação'},
    {'ticker': 'LAME4', 'nome': 'Lojas Americanas PN', 'tipo': 'Ação'},
    {'ticker': 'VIVT3', 'nome': 'Telefônica Brasil ON', 'tipo': 'Ação'},
    {'ticker': 'TIMS3', 'nome': 'TIM ON', 'tipo': 'Ação'},
    {'ticker': 'OIBR3', 'nome': 'Oi ON', 'tipo': 'Ação'},
    {'ticker': 'CMIG4', 'nome': 'Cemig PN', 'tipo': 'Ação'},
    {'ticker': 'CPLE6', 'nome': 'Copel PNB', 'tipo': 'Ação'},
    {'ticker': 'ELET3', 'nome': 'Eletrobras ON', 'tipo': 'Ação'},
    {'ticker': 'ENBR3', 'nome': 'Eneva ON', 'tipo': 'Ação'},
    {'ticker': 'EGIE3', 'nome': 'Engie Brasil ON', 'tipo': 'Ação'},
    {'ticker': 'TAEE11', 'nome': 'Taesa UNT', 'tipo': 'Ação'},
    {'ticker': 'TRPL4', 'nome': 'Trans Paulista PN', 'tipo': 'Ação'},
    {'ticker': 'SBSP3', 'nome': 'Sabesp ON', 'tipo': 'Ação'},
    {'ticker': 'SAPR4', 'nome': 'Sanepar PN', 'tipo': 'Ação'},
    {'ticker': 'BRKM5', 'nome': 'Braskem PNA', 'tipo': 'Ação'},
    {'ticker': 'FIBR3', 'nome': 'Fibria ON', 'tipo': 'Ação'},
    {'ticker': 'KLBN4', 'nome': 'Klabin PN', 'tipo': 'Ação'},
    {'ticker': 'SUZANO', 'nome': 'Suzano Papel', 'tipo': 'Ação'},
    {'ticker': 'B3SA3', 'nome': 'B3 ON', 'tipo': 'Ação'},
    {'ticker': 'RADL3', 'nome': 'Raia Drogasil ON', 'tipo': 'Ação'},
    {'ticker': 'FLRY3', 'nome': 'Fleury ON', 'tipo': 'Ação'},
    {'ticker': 'DASA3', 'nome': 'Dasa ON', 'tipo': 'Ação'},
    {'ticker': 'HAPV3', 'nome': 'Hapvida ON', 'tipo': 'Ação'},
    {'ticker': 'GNDI3', 'nome': 'Grupo Notre Dame ON', 'tipo': 'Ação'},
    {'ticker': 'ODPV3', 'nome': 'Odontoprev ON', 'tipo': 'Ação'},
    {'ticker': 'BIDI4', 'nome': 'Banco Inter PN', 'tipo': 'Ação'},
    
    // FIIs
    {'ticker': 'HGLG11', 'nome': 'CSHG Logística', 'tipo': 'FII'},
    {'ticker': 'XPML11', 'nome': 'XP Malls', 'tipo': 'FII'},
    {'ticker': 'HGRU11', 'nome': 'CSHG Renda Urbana', 'tipo': 'FII'},
    {'ticker': 'IRDM11', 'nome': 'Iridium Renda', 'tipo': 'FII'},
    {'ticker': 'VISC11', 'nome': 'Vinci Shopping', 'tipo': 'FII'},
    {'ticker': 'XPIN11', 'nome': 'XP Industrial', 'tipo': 'FII'},
    {'ticker': 'HFOF11', 'nome': 'Hedge Office', 'tipo': 'FII'},
    {'ticker': 'HGRE11', 'nome': 'CSHG Real Estate', 'tipo': 'FII'},
    {'ticker': 'HGBS11', 'nome': 'CSHG Brasil', 'tipo': 'FII'},
    {'ticker': 'HGCR11', 'nome': 'CSHG Credito', 'tipo': 'FII'},
    {'ticker': 'JURO11', 'nome': 'Juros Real', 'tipo': 'FII'},
    {'ticker': 'KDIF11', 'nome': 'Kinea Renda', 'tipo': 'FII'},
    {'ticker': 'IFRA11', 'nome': 'IFRA Renda', 'tipo': 'FII'},
    
    // ETFs
    {'ticker': 'BOVA11', 'nome': 'iShares Ibovespa', 'tipo': 'ETF'},
    {'ticker': 'SMAL11', 'nome': 'iShares Small Cap', 'tipo': 'ETF'},
    {'ticker': 'IVVB11', 'nome': 'iShares S&P 500', 'tipo': 'ETF'},
    {'ticker': 'HASH11', 'nome': 'Hashdex Bitcoin', 'tipo': 'ETF'},
    {'ticker': 'QETH11', 'nome': 'QR Asset Ethereum', 'tipo': 'ETF'},
    {'ticker': 'BBSD11', 'nome': 'BB Small Cap', 'tipo': 'ETF'},
    {'ticker': 'BOVV11', 'nome': 'Vanguard Ibovespa', 'tipo': 'ETF'},
    {'ticker': 'BOVX11', 'nome': 'Vanguard Small Cap', 'tipo': 'ETF'},
    
    // Criptomoedas
    {'ticker': 'BTC', 'nome': 'Bitcoin', 'tipo': 'Cripto'},
    {'ticker': 'ETH', 'nome': 'Ethereum', 'tipo': 'Cripto'},
    {'ticker': 'BNB', 'nome': 'Binance Coin', 'tipo': 'Cripto'},
    {'ticker': 'ADA', 'nome': 'Cardano', 'tipo': 'Cripto'},
    {'ticker': 'SOL', 'nome': 'Solana', 'tipo': 'Cripto'},
    {'ticker': 'DOT', 'nome': 'Polkadot', 'tipo': 'Cripto'},
    {'ticker': 'DOGE', 'nome': 'Dogecoin', 'tipo': 'Cripto'},
    {'ticker': 'AVAX', 'nome': 'Avalanche', 'tipo': 'Cripto'},
    {'ticker': 'MATIC', 'nome': 'Polygon', 'tipo': 'Cripto'},
    {'ticker': 'LINK', 'nome': 'Chainlink', 'tipo': 'Cripto'},
    {'ticker': 'UNI', 'nome': 'Uniswap', 'tipo': 'Cripto'},
    {'ticker': 'ATOM', 'nome': 'Cosmos', 'tipo': 'Cripto'},
    {'ticker': 'LTC', 'nome': 'Litecoin', 'tipo': 'Cripto'},
    {'ticker': 'BCH', 'nome': 'Bitcoin Cash', 'tipo': 'Cripto'},
    {'ticker': 'XLM', 'nome': 'Stellar', 'tipo': 'Cripto'},
    {'ticker': 'ALGO', 'nome': 'Algorand', 'tipo': 'Cripto'},
    {'ticker': 'VET', 'nome': 'VeChain', 'tipo': 'Cripto'},
    {'ticker': 'ICP', 'nome': 'Internet Computer', 'tipo': 'Cripto'},
    {'ticker': 'FIL', 'nome': 'Filecoin', 'tipo': 'Cripto'},
    {'ticker': 'TRX', 'nome': 'TRON', 'tipo': 'Cripto'},
    {'ticker': 'ETC', 'nome': 'Ethereum Classic', 'tipo': 'Cripto'},
    {'ticker': 'XMR', 'nome': 'Monero', 'tipo': 'Cripto'},
    {'ticker': 'EOS', 'nome': 'EOS', 'tipo': 'Cripto'},
    {'ticker': 'AAVE', 'nome': 'Aave', 'tipo': 'Cripto'},
    {'ticker': 'MKR', 'nome': 'Maker', 'tipo': 'Cripto'},
    {'ticker': 'COMP', 'nome': 'Compound', 'tipo': 'Cripto'},
    {'ticker': 'SUSHI', 'nome': 'SushiSwap', 'tipo': 'Cripto'},
    {'ticker': 'YFI', 'nome': 'yearn.finance', 'tipo': 'Cripto'},
    {'ticker': 'CRV', 'nome': 'Curve DAO Token', 'tipo': 'Cripto'},
    {'ticker': '1INCH', 'nome': '1inch', 'tipo': 'Cripto'},
    {'ticker': 'ZRX', 'nome': '0x', 'tipo': 'Cripto'},
    {'ticker': 'BAL', 'nome': 'Balancer', 'tipo': 'Cripto'},
    {'ticker': 'SNX', 'nome': 'Synthetix', 'tipo': 'Cripto'},
    {'ticker': 'REN', 'nome': 'Ren', 'tipo': 'Cripto'},
    {'ticker': 'KNC', 'nome': 'Kyber Network', 'tipo': 'Cripto'},
    {'ticker': 'BAND', 'nome': 'Band Protocol', 'tipo': 'Cripto'},
    {'ticker': 'UMA', 'nome': 'UMA', 'tipo': 'Cripto'},
    {'ticker': 'LRC', 'nome': 'Loopring', 'tipo': 'Cripto'},
    {'ticker': 'STORJ', 'nome': 'Storj', 'tipo': 'Cripto'},
    {'ticker': 'MANA', 'nome': 'Decentraland', 'tipo': 'Cripto'},
    {'ticker': 'SAND', 'nome': 'The Sandbox', 'tipo': 'Cripto'},
    {'ticker': 'ENJ', 'nome': 'Enjin Coin', 'tipo': 'Cripto'},
    {'ticker': 'CHZ', 'nome': 'Chiliz', 'tipo': 'Cripto'},
    {'ticker': 'HOT', 'nome': 'Holo', 'tipo': 'Cripto'},
    {'ticker': 'BAT', 'nome': 'Basic Attention Token', 'tipo': 'Cripto'},
    {'ticker': 'DASH', 'nome': 'Dash', 'tipo': 'Cripto'},
    {'ticker': 'ZEC', 'nome': 'Zcash', 'tipo': 'Cripto'},
    {'ticker': 'DCR', 'nome': 'Decred', 'tipo': 'Cripto'},
    {'ticker': 'NEO', 'nome': 'Neo', 'tipo': 'Cripto'},
    {'ticker': 'QTUM', 'nome': 'Qtum', 'tipo': 'Cripto'},
    {'ticker': 'IOTA', 'nome': 'IOTA', 'tipo': 'Cripto'},
    {'ticker': 'NANO', 'nome': 'Nano', 'tipo': 'Cripto'},
    {'ticker': 'VTHO', 'nome': 'VeThor Token', 'tipo': 'Cripto'},
    {'ticker': 'TFUEL', 'nome': 'Theta Fuel', 'tipo': 'Cripto'},
    {'ticker': 'THETA', 'nome': 'Theta Network', 'tipo': 'Cripto'},
    {'ticker': 'ZIL', 'nome': 'Zilliqa', 'tipo': 'Cripto'},
    {'ticker': 'ONE', 'nome': 'Harmony', 'tipo': 'Cripto'},
    {'ticker': 'IOTX', 'nome': 'IoTeX', 'tipo': 'Cripto'},
    {'ticker': 'ANKR', 'nome': 'Ankr', 'tipo': 'Cripto'},
    {'ticker': 'COTI', 'nome': 'COTI', 'tipo': 'Cripto'},
    {'ticker': 'CELO', 'nome': 'Celo', 'tipo': 'Cripto'},
    {'ticker': 'SKL', 'nome': 'Skale', 'tipo': 'Cripto'},
    {'ticker': 'AR', 'nome': 'Arweave', 'tipo': 'Cripto'},
    {'ticker': 'RLC', 'nome': 'iExec RLC', 'tipo': 'Cripto'},
    {'ticker': 'OCEAN', 'nome': 'Ocean Protocol', 'tipo': 'Cripto'},
    {'ticker': 'AUDIO', 'nome': 'Audius', 'tipo': 'Cripto'},
    {'ticker': 'LPT', 'nome': 'Livepeer', 'tipo': 'Cripto'},
    {'ticker': 'GRT', 'nome': 'The Graph', 'tipo': 'Cripto'},
    {'ticker': 'ANKR', 'nome': 'Ankr', 'tipo': 'Cripto'},
    {'ticker': 'COTI', 'nome': 'COTI', 'tipo': 'Cripto'},
    {'ticker': 'CELO', 'nome': 'Celo', 'tipo': 'Cripto'},
    {'ticker': 'SKL', 'nome': 'Skale', 'tipo': 'Cripto'},
    {'ticker': 'AR', 'nome': 'Arweave', 'tipo': 'Cripto'},
    {'ticker': 'RLC', 'nome': 'iExec RLC', 'tipo': 'Cripto'},
    {'ticker': 'OCEAN', 'nome': 'Ocean Protocol', 'tipo': 'Cripto'},
    {'ticker': 'AUDIO', 'nome': 'Audius', 'tipo': 'Cripto'},
    {'ticker': 'LPT', 'nome': 'Livepeer', 'tipo': 'Cripto'},
    {'ticker': 'GRT', 'nome': 'The Graph', 'tipo': 'Cripto'},
  ];

  // Cache de preços
  static final Map<String, double> _priceCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 20);
  
  // Controle de requisições
  static int _requestCount = 0;
  static const int _maxRequestsPerDay = 8000;
  static DateTime _lastResetDate = DateTime.now();

  // Buscar todos os ativos disponíveis
  static Future<List<Map<String, dynamic>>> getAtivos() async {
    return _ativosBrasileiros;
  }

  // Buscar ativos por ticker
  static Future<List<Map<String, dynamic>>> getAtivosByTicker(String ticker) async {
    final ativos = await getAtivos();
    return ativos.where((ativo) => 
      ativo['ticker'].toString().toLowerCase().contains(ticker.toLowerCase())
    ).toList();
  }

  // Buscar ativo por nome
  static Future<Map<String, dynamic>?> getAtivoByNome(String nome) async {
    final ativos = await getAtivos();
    
    for (var ativo in ativos) {
      if (ativo['nome'].toString().toLowerCase() == nome.toLowerCase()) {
        return ativo;
      }
    }
    return null;
  }

  static bool isTickerValido(String ticker) {
    // Não pode ser vazio
    if (ticker.trim().isEmpty) return false;
    if (ticker.contains('"') || ticker.contains("'")) return false;
    
    // Verificar se está na lista de ativos conhecidos
    final ativoEncontrado = _ativosBrasileiros.any((a) => a['ticker'].toString().toUpperCase() == ticker.toUpperCase());
    
    if (!ativoEncontrado) {
      print('⚠️ Ticker não encontrado na lista: $ticker');
      return false;
    }
    
    return true;
  }

  // Verificar se um ticker é suportado pela API
  static bool isTickerSuportadoAPI(String ticker) {
    // Lista de tickers que funcionam na API gratuita
    final tickersSuportados = [
      // Ações principais (testadas e funcionando)
      'PETR4', 'VALE3', 'ITUB4', 'BBDC4', 'ABEV3', 'WEGE3', 'RENT3', 'BIDI4',
      // FIIs que funcionam na versão gratuita (limitados)
      'HGLG11', 'XPML11', 'HGRU11', 'IRDM11', 'VISC11', 'XPIN11',
      // ETFs principais
      'BOVA11', 'SMAL11', 'IVVB11',
      // Criptos
      'BTC', 'ETH', 'BNB', 'ADA', 'SOL', 'DOT', 'DOGE'
    ];
    
    return tickersSuportados.contains(ticker.toUpperCase());
  }

  static Future<double?> getPrecoAtivo(String ticker) async {
    if (!isTickerValido(ticker)) {
      print('⛔ Ticker inválido ignorado: $ticker');
      return null;
    }
    
    // Verificar se o ticker é suportado pela API
    if (!isTickerSuportadoAPI(ticker)) {
      print('⚠️ Ticker não testado na API: $ticker - tentando mesmo assim...');
    }
    try {
      if (_priceCache.containsKey(ticker)) {
        final timestamp = _cacheTimestamps[ticker];
        if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiration) {
          return _priceCache[ticker];
        }
      }
      _checkRequestLimit();
      final symbol = _formatSymbolForAPI(ticker);
      final url = Uri.parse('$_baseUrl/price?symbol=$symbol&apikey=$_apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'error') {
          final errorMessage = data['message']?.toString() ?? 'Erro desconhecido';
          print('❌ API error para $ticker: $errorMessage');
          print('🔍 Símbolo enviado para API: $symbol');
          
          // Logs mais específicos para diferentes tipos de erro
          if (errorMessage.toLowerCase().contains('not supported') || 
              errorMessage.toLowerCase().contains('symbol') ||
              errorMessage.toLowerCase().contains('figi')) {
            print('⛔ Símbolo não suportado pela API: $ticker (${symbol})');
            print('💡 Sugestão: Verificar se o símbolo está correto para o mercado brasileiro');
          } else if (errorMessage.toLowerCase().contains('limit')) {
            print('🚫 Limite da API atingido - aguardando próximo ciclo');
          } else if (errorMessage.toLowerCase().contains('grow') || 
                     errorMessage.toLowerCase().contains('upgrading') ||
                     errorMessage.toLowerCase().contains('pricing')) {
            print('💳 Símbolo requer plano pago: $ticker');
            print('💡 Sugestão: Atualizar para plano Grow em https://twelvedata.com/pricing');
          } else {
            print('🔍 Erro específico da API - verificar documentação');
          }
          return null;
        }
        final price = double.tryParse(data['price'] ?? '0');
        if (price != null && price > 0) {
          _priceCache[ticker] = price;
          _cacheTimestamps[ticker] = DateTime.now();
          _requestCount++;
          print('💰 Preço atualizado para $ticker: R\$ ${price.toStringAsFixed(2)}');
          return price;
        } else {
          print('❌ Preço inválido para $ticker. Resposta: ${response.body}');
        }
      } else {
        print('❌ Erro HTTP ${response.statusCode} ao buscar preço para $ticker. Resposta: ${response.body}');
      }
      return null;
    } catch (e) {
      print('💥 Erro na API Twelve Data para $ticker: $e');
      return null;
    }
  }

  // Formatar símbolo para a API
  static String _formatSymbolForAPI(String ticker) {
    // Limpar o ticker de espaços e caracteres especiais
    String cleanTicker = ticker.trim().toUpperCase();
    
    // Para criptomoedas, usar par USD
    if (['BTC', 'ETH', 'BNB', 'ADA', 'SOL', 'DOT', 'DOGE', 'AVAX', 'MATIC', 'LINK', 'UNI', 'ATOM', 'LTC', 'BCH', 'XLM', 'ALGO', 'VET', 'ICP', 'FIL', 'TRX', 'ETC', 'XMR', 'EOS', 'AAVE', 'MKR', 'COMP', 'SUSHI', 'YFI', 'CRV', '1INCH', 'ZRX', 'BAL', 'SNX', 'REN', 'KNC', 'BAND', 'UMA', 'LRC', 'STORJ', 'MANA', 'SAND', 'ENJ', 'CHZ', 'HOT', 'BAT', 'DASH', 'ZEC', 'DCR', 'NEO', 'QTUM', 'IOTA', 'NANO', 'VTHO', 'TFUEL', 'THETA', 'ZIL'].contains(cleanTicker)) {
      return '$cleanTicker/USD';
    }
    
    // Para ações brasileiras (B3), usar formato sem sufixo
    if (cleanTicker.endsWith('3') || cleanTicker.endsWith('4') || cleanTicker.endsWith('5') || cleanTicker.endsWith('6')) {
      return cleanTicker;
    }
    
    // Para FIIs brasileiros (terminam em 11), usar formato sem sufixo
    if (cleanTicker.endsWith('11')) {
      return cleanTicker;
    }
    
    // Para ETFs brasileiros (terminam em 11), usar formato sem sufixo
    if (cleanTicker.endsWith('11')) {
      return cleanTicker;
    }
    
    // Para outros ativos brasileiros, retornar como está
    return cleanTicker;
  }

  // Converter símbolo da API de volta para ticker original
  static String _convertSymbolToTicker(String symbol) {
    // Remover sufixos da API
    if (symbol.endsWith('.SA')) {
      return symbol.replaceAll('.SA', '');
    }
    if (symbol.endsWith('/USD')) {
      return symbol.replaceAll('/USD', '');
    }
    return symbol;
  }

  // Buscar preços em lote (requisições individuais)
  static Future<Map<String, double>> getPrecosEmLote(List<String> tickers) async {
    final Map<String, double> precos = {};
    final List<String> tickersParaBuscar = [];
    
    // Verificar cache primeiro
    for (final ticker in tickers) {
      if (_priceCache.containsKey(ticker)) {
        final timestamp = _cacheTimestamps[ticker];
        if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiration) {
          precos[ticker] = _priceCache[ticker]!;
          print('💰 Preço em cache para $ticker: R\$ ${_priceCache[ticker]!.toStringAsFixed(2)}');
        } else {
          tickersParaBuscar.add(ticker);
        }
      } else {
        tickersParaBuscar.add(ticker);
      }
    }

    // Buscar preços individualmente
    for (int i = 0; i < tickersParaBuscar.length; i++) {
      final ticker = tickersParaBuscar[i];
      try {
        _checkRequestLimit();
        final symbol = _formatSymbolForAPI(ticker);
        final url = Uri.parse('$_baseUrl/price?symbol=$symbol&apikey=$_apiKey');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'error') {
            final errorMessage = data['message']?.toString() ?? 'Erro desconhecido';
            print('❌ API error para $ticker: $errorMessage');
            print('🔍 Símbolo enviado para API: $symbol');
            
            // Logs específicos para diferentes tipos de erro
            if (errorMessage.toLowerCase().contains('grow') || 
                errorMessage.toLowerCase().contains('upgrading') ||
                errorMessage.toLowerCase().contains('pricing')) {
              print('💳 Símbolo requer plano pago: $ticker');
            }
            continue;
          }
          
          final price = double.tryParse(data['price'] ?? '0');
          if (price != null && price > 0) {
            precos[ticker] = price;
            _priceCache[ticker] = price;
            _cacheTimestamps[ticker] = DateTime.now();
            _requestCount++;
            print('💰 Preço atualizado para $ticker: R\$ ${price.toStringAsFixed(2)}');
          } else {
            print('❌ Preço inválido para $ticker: ${data['price']}');
          }
        } else {
          print('❌ Erro HTTP ${response.statusCode} para $ticker: ${response.body}');
        }
      } catch (e) {
        print('💥 Erro ao buscar preço para $ticker: $e');
      }
      
      // Delay entre requisições para não estourar o limite
      if (i < tickersParaBuscar.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    print('📦 Processamento concluído: ${precos.length} preços obtidos de ${tickers.length} tickers');
    return precos;
  }

  // Verificar limite de requisições
  static void _checkRequestLimit() {
    final now = DateTime.now();
    if (now.day != _lastResetDate.day) {
      _requestCount = 0;
      _lastResetDate = now;
    }
    
    if (_requestCount >= _maxRequestsPerDay) {
      throw Exception('Limite diário de requisições atingido (8000)');
    }
  }

  // Buscar todos os tickers únicos
  static Future<List<String>> getTickers() async {
    final ativos = await getAtivos();
    return ativos.map((ativo) => ativo['ticker'].toString()).toList();
  }

  // Calcular valor total dos ativos
  static Future<double> getValorTotalAtivos() async {
    final ativos = await getAtivos();
    double total = 0.0;
    
    for (var ativo in ativos) {
      final preco = await getPrecoAtivo(ativo['ticker']);
      if (preco != null) {
        total += preco;
      }
    }
    
    return total;
  }

  // Buscar estatísticas dos ativos
  static Future<Map<String, dynamic>> getEstatisticasAtivos() async {
    final ativos = await getAtivos();
    final total = await getValorTotalAtivos();
    
    Map<String, double> porTipo = {};
    Map<String, int> contagemPorTipo = {};
    
    for (var ativo in ativos) {
      final tipo = ativo['tipo'] ?? 'Outro';
      final preco = await getPrecoAtivo(ativo['ticker']);
      
      if (preco != null) {
        porTipo[tipo] = (porTipo[tipo] ?? 0.0) + preco;
        contagemPorTipo[tipo] = (contagemPorTipo[tipo] ?? 0) + 1;
      }
    }
    
    return {
      'totalAtivos': ativos.length,
      'valorTotal': total,
      'porTipo': porTipo,
      'contagemPorTipo': contagemPorTipo,
    };
  }

  // Limpar cache
  static void limparCache() {
    _priceCache.clear();
    _cacheTimestamps.clear();
    print('🗑️ Cache de preços limpo');
  }

  // Obter estatísticas de uso
  static Map<String, dynamic> getEstatisticasUso() {
    return {
      'requisicoesHoje': _requestCount,
      'limiteDiario': _maxRequestsPerDay,
      'itensEmCache': _priceCache.length,
    };
  }

  // Testar conexão com a API
  static Future<bool> testarConexao() async {
    try {
      final url = Uri.parse('$_baseUrl/price?symbol=PETR4&apikey=$_apiKey');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['price'] != null;
      }
      return false;
    } catch (e) {
      print('❌ Erro ao testar conexão com API: $e');
      return false;
    }
  }

  // Obter informações da API
  static Map<String, dynamic> getInfoAPI() {
    return {
      'nome': 'Twelve Data API',
      'baseUrl': _baseUrl,
      'status': 'Ativo',
      'limiteDiario': _maxRequestsPerDay,
      'requisicoesUsadas': _requestCount,
      'requisicoesRestantes': _maxRequestsPerDay - _requestCount,
      'cacheAtivo': _priceCache.length > 0,
      'itensEmCache': _priceCache.length,
    };
  }
} 