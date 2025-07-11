import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _userPhoneKey = 'userPhone';
  static const String _savedEmailKey = 'savedEmail';
  static const String _savedPasswordKey = 'savedPassword';
  static const String _rememberMeKey = 'rememberMe';

  // Verificar se usuário está logado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Obter dados do usuário logado
  static Future<Map<String, String>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nome': prefs.getString(_userNameKey) ?? '',
      'email': prefs.getString(_userEmailKey) ?? '',
      'telefone': prefs.getString(_userPhoneKey) ?? '',
    };
  }

  // Salvar dados de login
  static Future<void> saveLoginData({
    required String nome,
    required String email,
    required String telefone,
    String? savedEmail,
    String? savedPassword,
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salvar dados do usuário
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userNameKey, nome);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userPhoneKey, telefone);
    
    // Salvar credenciais se "Lembrar de mim" estiver marcado
    if (rememberMe && savedEmail != null && savedPassword != null) {
      await prefs.setString(_savedEmailKey, savedEmail);
      await prefs.setString(_savedPasswordKey, savedPassword);
      await prefs.setBool(_rememberMeKey, true);
    } else {
      // Limpar credenciais salvas
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  // Obter credenciais salvas
  static Future<Map<String, String>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    
    if (rememberMe) {
      return {
        'email': prefs.getString(_savedEmailKey) ?? '',
        'password': prefs.getString(_savedPasswordKey) ?? '',
      };
    }
    
    return {'email': '', 'password': ''};
  }

  // Verificar se há credenciais salvas
  static Future<bool> hasSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey) ?? '';
    
    return rememberMe && savedEmail.isNotEmpty;
  }

  // Fazer logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Limpar todos os dados de login
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
    await prefs.remove(_rememberMeKey);
  }

  // Limpar apenas credenciais salvas (mantém login atual)
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
    await prefs.setBool(_rememberMeKey, false);
  }

  // Obter informações de login
  static Future<Map<String, dynamic>> getLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
      'userName': prefs.getString(_userNameKey) ?? '',
      'userEmail': prefs.getString(_userEmailKey) ?? '',
      'userPhone': prefs.getString(_userPhoneKey) ?? '',
      'hasSavedCredentials': await hasSavedCredentials(),
      'rememberMe': prefs.getBool(_rememberMeKey) ?? false,
    };
  }
} 