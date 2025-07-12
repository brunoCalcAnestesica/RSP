import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class DataCacheService {
  static const String _usersCacheKey = 'cached_users';
  static const String _lastUpdateKey = 'last_update_timestamp';
  static const int _updateIntervalMinutes = 10;
  
  static Timer? _updateTimer;
  static List<Map<String, dynamic>>? _cachedUsers;
  static DateTime? _lastUpdate;

  // Inicializar o serviço de cache
  static Future<void> initialize() async {
    print('🚀 Inicializando DataCacheService...');
    
    // Carregar dados do cache local
    await _loadFromCache();
    
    // Verificar se precisa atualizar
    if (_shouldUpdate()) {
      print('🔄 Dados desatualizados, atualizando...');
      await _updateData();
    } else {
      print('✅ Dados em cache ainda válidos');
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
      
      // Carregar usuários
      final usersJson = prefs.getString(_usersCacheKey);
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        _cachedUsers = usersList.cast<Map<String, dynamic>>();
        print('📦 ${_cachedUsers!.length} usuários carregados do cache');
      }
      
      // Carregar timestamp da última atualização
      final lastUpdateMillis = prefs.getInt(_lastUpdateKey);
      if (lastUpdateMillis != null) {
        _lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
        print('🕒 Última atualização: $_lastUpdate');
      }
    } catch (e) {
      print('⚠️ Erro ao carregar cache: $e');
    }
  }

  // Salvar dados no cache local
  static Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar usuários
      if (_cachedUsers != null) {
        final usersJson = json.encode(_cachedUsers);
        await prefs.setString(_usersCacheKey, usersJson);
        print('💾 ${_cachedUsers!.length} usuários salvos no cache');
      }
      
      // Salvar timestamp
      final now = DateTime.now();
      await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
      _lastUpdate = now;
      print('🕒 Timestamp de atualização salvo: $_lastUpdate');
    } catch (e) {
      print('⚠️ Erro ao salvar cache: $e');
    }
  }

  // Atualizar dados de usuários
  static Future<void> _updateData() async {
    try {
      print('📡 Atualizando dados de usuários...');
      final users = await AuthService.getUsers();
      _cachedUsers = users;
      await _saveToCache();
      print('✅ Dados atualizados com sucesso!');
    } catch (e) {
      print('❌ Erro ao atualizar dados: $e');
      // Se falhar na atualização, manter dados em cache se disponível
      if (_cachedUsers == null) {
        print('⚠️ Nenhum dado em cache disponível');
      }
    }
  }

  // Iniciar timer para atualização automática
  static void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      Duration(minutes: _updateIntervalMinutes),
      (timer) async {
        print('⏰ Timer disparado - atualizando dados...');
        await _updateData();
      },
    );
    print('⏰ Timer configurado para atualizar a cada $_updateIntervalMinutes minutos');
  }

  // Parar timer
  static void dispose() {
    _updateTimer?.cancel();
    print('🛑 Timer de atualização cancelado');
  }

  // Obter usuários (do cache ou da planilha)
  static Future<List<Map<String, dynamic>>> getUsers() async {
    if (_cachedUsers != null) {
      print('📦 Retornando ${_cachedUsers!.length} usuários do cache');
      return _cachedUsers!;
    } else {
      print('🔄 Cache vazio, buscando dados da planilha...');
      await _updateData();
      return _cachedUsers ?? [];
    }
  }

  // Autenticar usuário usando cache
  static Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    try {
      print('🔐 Tentando autenticar usuário: $email');
      final users = await getUsers();
      
      for (var user in users) {
        if (user['EMAIL'] == email && user['SENHA'] == password) {
          print('✅ Usuário autenticado com sucesso!');
          return {
            'nome': user['NOME'] ?? '',
            'email': user['EMAIL'] ?? '',
            'telefone': user['TELEFONE'] ?? '',
            'senha': user['SENHA'] ?? '',
          };
        }
      }
      print('❌ Usuário não encontrado ou senha incorreta');
      return null;
    } catch (e) {
      print('💥 Erro na autenticação: $e');
      throw Exception('Erro na autenticação: $e');
    }
  }

  // Verificar se email existe usando cache
  static Future<bool> emailExists(String email) async {
    try {
      final users = await getUsers();
      return users.any((user) => user['EMAIL'] == email);
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }

  // Buscar usuário por email usando cache
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final users = await getUsers();
      
      for (var user in users) {
        if (user['EMAIL'] == email) {
          return {
            'nome': user['NOME'] ?? '',
            'email': user['EMAIL'] ?? '',
            'telefone': user['TELEFONE'] ?? '',
            'senha': user['SENHA'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  // Forçar atualização manual
  static Future<void> forceUpdate() async {
    print('🔄 Forçando atualização manual...');
    await _updateData();
  }

  // Obter informações do cache
  static Map<String, dynamic> getCacheInfo() {
    return {
      'usersCount': _cachedUsers?.length ?? 0,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'isValid': !_shouldUpdate(),
    };
  }
} 

class TwelveDataService {
  static const String apiKey = '80def4ab34e84758998a8ad4e0fbe26d';
  static const List<String> tickers = [
    'BBAS3.SA','BBDC4.SA','TAEE11.SA','ISAE4.SA','SAPR11.SA','SBSP3.SA','TIMS3.SA','VIVT3.SA','TGMA3.SA','RAIL3.SA','BBSE3.SA','PSSA3.SA','SLCE3.SA','AGRO3.SA','PETR4.SA','VALE3.SA','XPLG11.SA','VILG11.SA','HGLG11.SA','JSRE11.SA','HGRE11.SA','PVBI11.SA','VISC11.SA','XPML11.SA','RVBI11.SA','MALL11.SA','KNCR11.SA','RBRR11.SA','KNIP11.SA','CPTS11.SA','HGRU11.SA','TRXF11.SA','VINO11.SA','IVVB11.SA','USDB11.SA','BND.SA','WRLD11.SA','BNDX11.SA','ALUG11.SA','XINA11.SA','BTC/BRL','USDT/BRL'
  ];

  static Future<Map<String, double>> fetchPrices() async {
    final Map<String, double> prices = {};
    // Twelve Data permite até 8 símbolos por requisição
    for (int i = 0; i < tickers.length; i += 8) {
      final batch = tickers.skip(i).take(8).join(',');
      final url = 'https://api.twelvedata.com/price?symbol=$batch&apikey=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          data.forEach((symbol, value) {
            if (value is Map && value['price'] != null) {
              prices[symbol] = double.tryParse(value['price'].toString().replaceAll(',', '.')) ?? 0;
            }
          });
        } else if (data['price'] != null && batch.split(',').length == 1) {
          // Caso de apenas 1 símbolo
          prices[batch] = double.tryParse(data['price'].toString().replaceAll(',', '.')) ?? 0;
        }
      }
    }
    return prices;
  }
} 