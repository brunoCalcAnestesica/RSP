import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleSheetsService {
  static const String _spreadsheetId = '1vW1Zd8r0A7QcbLVmGisfTXcOxFk8arPziqVZIK6AazU';
  static const String _sheetName = 'USUARIO%2FSENHA'; // URL encoded para /
  
  // URL base para acessar a planilha como JSON
  static String get _baseUrl => 'https://opensheet.elk.sh/$_spreadsheetId/$_sheetName';

  // Buscar todos os usuários da planilha
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      print('🔗 Tentando conectar com a planilha...');
      print('📡 URL: $_baseUrl');
      
      final response = await http.get(Uri.parse(_baseUrl));
      
      print('📊 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Dados carregados com sucesso! ${data.length} usuários encontrados');
        
        // Filtrar linhas vazias
        final validUsers = data.where((user) => 
          user['NOME'] != null && 
          user['NOME'].toString().isNotEmpty &&
          user['EMAIL'] != null && 
          user['EMAIL'].toString().isNotEmpty
        ).toList();
        
        print('✅ ${validUsers.length} usuários válidos encontrados');
        return validUsers.cast<Map<String, dynamic>>();
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception('Falha ao carregar dados da planilha: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erro de conexão: $e');
      throw Exception('Erro ao conectar com a planilha: $e');
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
        
        print('👤 Verificando usuário: $userEmail');
        
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
      return null; // Usuário não encontrado
    } catch (e) {
      print('💥 Erro na autenticação: $e');
      throw Exception('Erro na autenticação: $e');
    }
  }

  // Verificar se email existe
  static Future<bool> emailExists(String email) async {
    try {
      final users = await getUsers();
      return users.any((user) => user['EMAIL'] == email);
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }

  // Buscar usuário por email
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

  // Validar credenciais (para login)
  static Future<bool> validateCredentials(String email, String password) async {
    try {
      final user = await authenticateUser(email, password);
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Buscar todos os usuários (para debug)
  static Future<void> debugPrintUsers() async {
    try {
      final users = await getUsers();
      print('=== USUÁRIOS NA PLANILHA ===');
      for (var user in users) {
        print('Nome: ${user['NOME']}');
        print('Email: ${user['EMAIL']}');
        print('Telefone: ${user['TELEFONE']}');
        print('Senha: ${user['SENHA']}');
        print('---');
      }
    } catch (e) {
      print('Erro ao debug: $e');
    }
  }
} 