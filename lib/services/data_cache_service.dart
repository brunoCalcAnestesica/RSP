import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/google_sheets_service.dart';

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

  // Atualizar dados da planilha
  static Future<void> _updateData() async {
    try {
      print('📡 Atualizando dados da planilha...');
      final users = await GoogleSheetsService.getUsers();
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