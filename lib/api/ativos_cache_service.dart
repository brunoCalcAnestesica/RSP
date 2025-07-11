import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'ativos_service.dart';

class AtivosCacheService {
  static const String _ativosCacheKey = 'cached_ativos';
  static const String _lastUpdateKey = 'last_update_ativos_timestamp';
  static const int _updateIntervalMinutes = 10;
  
  static Timer? _updateTimer;
  static List<Map<String, dynamic>>? _cachedAtivos;
  static DateTime? _lastUpdate;

  // Inicializar o serviço de cache
  static Future<void> initialize() async {
    print('🚀 Inicializando AtivosCacheService...');
    
    // Carregar dados do cache local
    await _loadFromCache();
    
    // Verificar se precisa atualizar
    if (_shouldUpdate()) {
      print('🔄 Dados de ativos desatualizados, atualizando...');
      await _updateData();
    } else {
      print('✅ Dados de ativos em cache ainda válidos');
    }
    
    // Configurar timer para atualização automática
    _startUpdateTimer();
  }

  // Verificar se precisa atualizar (mais de 10 minutos desde última atualização)
  static bool _shouldUpdate() {
    if (_lastUpdate == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);
    return difference.inMinutes >= _updateIntervalMinutes;
  }

  // Carregar dados do cache local
  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar ativos
      final ativosJson = prefs.getString(_ativosCacheKey);
      if (ativosJson != null) {
        final List<dynamic> ativosList = json.decode(ativosJson);
        _cachedAtivos = ativosList.cast<Map<String, dynamic>>();
        print('📦 Cache de ativos carregado');
      }
      
      // Carregar timestamp da última atualização
      final lastUpdateMillis = prefs.getInt(_lastUpdateKey);
      if (lastUpdateMillis != null) {
        _lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
        print('🕒 Última atualização de ativos: $_lastUpdate');
      }
    } catch (e) {
      print('⚠️ Erro ao carregar cache de ativos: $e');
    }
  }

  // Salvar dados no cache local
  static Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar ativos
      if (_cachedAtivos != null) {
        final ativosJson = json.encode(_cachedAtivos);
        await prefs.setString(_ativosCacheKey, ativosJson);
        print('💾 Cache de ativos salvo');
      }
      
      // Salvar timestamp
      final now = DateTime.now();
      await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
      _lastUpdate = now;
      print('🕒 Timestamp de atualização de ativos salvo: $_lastUpdate');
    } catch (e) {
      print('⚠️ Erro ao salvar cache de ativos: $e');
    }
  }

  // Atualizar dados da planilha
  static Future<void> _updateData() async {
    try {
      print('📡 Atualizando dados de ativos da planilha...');
      final ativos = await AtivosService.getAtivos();
      _cachedAtivos = ativos;
      await _saveToCache();
      print('✅ Dados de ativos atualizados com sucesso!');
    } catch (e) {
      print('❌ Erro ao atualizar dados de ativos: $e');
      // Se falhar na atualização, manter dados em cache se disponível
      if (_cachedAtivos == null) {
        print('⚠️ Nenhum dado de ativos em cache disponível');
      }
    }
  }

  // Iniciar timer para atualização automática
  static void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      Duration(minutes: _updateIntervalMinutes),
      (timer) async {
        print('⏰ Timer disparado - atualizando dados de ativos...');
        await _updateData();
      },
    );
    print('⏰ Timer configurado para atualizar ativos a cada $_updateIntervalMinutes minutos');
  }

  // Parar timer
  static void dispose() {
    _updateTimer?.cancel();
    print('🛑 Timer de atualização de ativos cancelado');
  }

  // Obter ativos (do cache ou da planilha)
  static Future<List<Map<String, dynamic>>> getAtivos() async {
    if (_cachedAtivos != null) {
      print('📦 Retornando ativos do cache');
      return _cachedAtivos!;
    } else {
      print('🔄 Cache de ativos vazio, buscando dados da planilha...');
      await _updateData();
      return _cachedAtivos ?? [];
    }
  }

  // Buscar ativos por ticker usando cache
  static Future<List<Map<String, dynamic>>> getAtivosByTicker(String ticker) async {
    try {
      final ativos = await getAtivos();
      return ativos.where((ativo) => 
        (ativo['TICKER']?.toString().toLowerCase() ?? '').contains(ticker.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Erro ao buscar ativos por ticker: $e');
    }
  }

  // Buscar ativo por nome usando cache
  static Future<Map<String, dynamic>?> getAtivoByNome(String nome) async {
    try {
      final ativos = await getAtivos();
      
      for (var ativo in ativos) {
        if (ativo['NOME DO ATIVO']?.toString().toLowerCase() == nome.toLowerCase()) {
          return ativo;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar ativo por nome: $e');
    }
  }

  // Buscar ativos por CNPJ usando cache
  static Future<List<Map<String, dynamic>>> getAtivosByCNPJ(String cnpj) async {
    try {
      final ativos = await getAtivos();
      return ativos.where((ativo) => 
        (ativo['CNPJ']?.toString().toLowerCase() ?? '').contains(cnpj.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Erro ao buscar ativos por CNPJ: $e');
    }
  }

  // Calcular valor total dos ativos usando cache
  static Future<double> getValorTotalAtivos() async {
    try {
      final ativos = await getAtivos();
      double total = 0.0;
      
      for (var ativo in ativos) {
        final valor = double.tryParse(ativo['PREÇO ATUAL']?.toString().replaceAll(',', '.') ?? '0') ?? 0.0;
        total += valor;
      }
      
      return total;
    } catch (e) {
      throw Exception('Erro ao calcular valor total: $e');
    }
  }

  // Buscar estatísticas dos ativos usando cache
  static Future<Map<String, dynamic>> getEstatisticasAtivos() async {
    try {
      final ativos = await getAtivos();
      final total = await getValorTotalAtivos();
      
      // Agrupar por ticker
      Map<String, double> porTicker = {};
      Map<String, int> contagemPorTicker = {};
      
      for (var ativo in ativos) {
        final ticker = ativo['TICKER']?.toString() ?? 'Sem Ticker';
        final valor = double.tryParse(ativo['PREÇO ATUAL']?.toString().replaceAll(',', '.') ?? '0') ?? 0.0;
        
        porTicker[ticker] = (porTicker[ticker] ?? 0.0) + valor;
        contagemPorTicker[ticker] = (contagemPorTicker[ticker] ?? 0) + 1;
      }
      
      return {
        'totalAtivos': ativos.length,
        'valorTotal': total,
        'porTicker': porTicker,
        'contagemPorTicker': contagemPorTicker,
      };
    } catch (e) {
      throw Exception('Erro ao calcular estatísticas: $e');
    }
  }

  // Forçar atualização manual
  static Future<void> forceUpdate() async {
    print('🔄 Forçando atualização manual de ativos...');
    await _updateData();
  }

  // Obter informações do cache
  static Map<String, dynamic> getCacheInfo() {
    return {
      'ativosCount': _cachedAtivos?.length ?? 0,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'isValid': !_shouldUpdate(),
    };
  }
} 