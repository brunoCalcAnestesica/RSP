import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _usersKey = 'cached_users';
  static const String _lastUpdateKey = 'last_update_timestamp';
  
  // Dados de usuários padrão (substituindo a planilha)
  static const List<Map<String, dynamic>> _defaultUsers = [
    {
      'NOME': 'Usuário Teste',
      'EMAIL': 'teste@teste.com',
      'SENHA': '123456',
      'TELEFONE': '(11) 99999-9999',
    },
    {
      'NOME': 'Admin',
      'EMAIL': 'admin@admin.com',
      'SENHA': 'admin123',
      'TELEFONE': '(11) 88888-8888',
    },
  ];

  // Inicializar dados de usuários
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) {
        // Primeira execução, salvar usuários padrão
        await _saveUsers(_defaultUsers);
        print('✅ Usuários padrão criados');
      } else {
        print('✅ Usuários carregados do cache');
      }
    } catch (e) {
      print('❌ Erro ao inicializar AuthService: $e');
    }
  }

  // Salvar usuários no cache
  static Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = json.encode(users);
      await prefs.setString(_usersKey, usersJson);
      
      final now = DateTime.now();
      await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Erro ao salvar usuários: $e');
    }
  }

  // Obter usuários do cache
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.cast<Map<String, dynamic>>();
      }
      
      return _defaultUsers;
    } catch (e) {
      print('❌ Erro ao obter usuários: $e');
      return _defaultUsers;
    }
  }

  // Autenticar usuário
  static Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    try {
      print('🔐 Tentando autenticar usuário: $email');
      final users = await getUsers();
      
      for (var user in users) {
        final userEmail = user['EMAIL']?.toString().trim().toLowerCase() ?? '';
        final userPassword = user['SENHA']?.toString().trim() ?? '';
        final inputEmail = email.trim().toLowerCase();
        final inputPassword = password.trim();
        
        if (userEmail == inputEmail && userPassword == inputPassword) {
          print('✅ Usuário autenticado com sucesso!');
          return {
            'nome': user['NOME']?.toString().trim() ?? '',
            'email': userEmail,
            'telefone': user['TELEFONE']?.toString().trim() ?? '',
            'senha': userPassword,
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

  // Verificar se email existe
  static Future<bool> emailExists(String email) async {
    try {
      final users = await getUsers();
      return users.any((user) => 
        user['EMAIL']?.toString().trim().toLowerCase() == email.trim().toLowerCase()
      );
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }

  // Buscar usuário por email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final users = await getUsers();
      
      for (var user in users) {
        if (user['EMAIL']?.toString().trim().toLowerCase() == email.trim().toLowerCase()) {
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

  // Validar credenciais
  static Future<bool> validateCredentials(String email, String password) async {
    try {
      final user = await authenticateUser(email, password);
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Login
  static Future<bool> login(String email, String password) async {
    try {
      final user = await authenticateUser(email, password);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);
        await prefs.setString('userName', user['nome'] ?? '');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erro no login: $e');
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      print('✅ Logout realizado com sucesso');
    } catch (e) {
      print('❌ Erro no logout: $e');
    }
  }

  // Verificar se está logado
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Obter dados do usuário logado
  static Future<Map<String, String>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? '';
      final name = prefs.getString('userName') ?? '';
      
      return {
        'email': email,
        'name': name,
      };
    } catch (e) {
      return {'email': '', 'name': ''};
    }
  }

  // Forçar atualização
  static Future<void> forceUpdate() async {
    try {
      await _saveUsers(_defaultUsers);
      print('✅ Dados de usuários atualizados');
    } catch (e) {
      print('❌ Erro ao atualizar dados: $e');
    }
  }

  // Obter informações do cache
  static Map<String, dynamic> getCacheInfo() {
    return {
      'usersCount': _defaultUsers.length,
      'lastUpdate': DateTime.now().toIso8601String(),
      'isValid': true,
    };
  }
} 