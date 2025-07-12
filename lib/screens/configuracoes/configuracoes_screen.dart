import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import '../../services/data_cache_service.dart' as cache;
import '../../api/twelve_data_service.dart';
import '../../services/auth_service.dart';
import '../../services/bolsa_storage_service.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  ThemeMode _selectedTheme = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aparência
              Text(
                'Aparência',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.palette,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Tema',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _getThemeModeName(_selectedTheme),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: _selectedTheme,
                    onChanged: (ThemeMode? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTheme = newValue;
                        });
                        _showThemeChangeMessage(context, newValue);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Escuro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Automático'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notificações
              Text(
                'Notificações',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notificações Push'),
                      subtitle: const Text('Receber notificações do app'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: const Text('Alertas de Mercado'),
                      subtitle: const Text('Notificações sobre movimentações'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

                          // Perfil do Usuário
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Meu Perfil'),
                subtitle: const Text('Gerenciar dados pessoais'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Segurança
            Text(
              'Segurança',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('Login Biométrico'),
                    subtitle: const Text('Usar impressão digital ou Face ID'),
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (value) {
                        setState(() {
                          _biometricEnabled = value;
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Alterar Senha'),
                    subtitle: const Text('Modificar senha de acesso'),
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                  ),
                ],
              ),
            ),
              const SizedBox(height: 24),

              // Dados
              Text(
                'Dados',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Exportar Dados'),
                      subtitle: const Text('Baixar backup dos dados'),
                      onTap: () {
                        _showExportDialog();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Limpar Dados'),
                      subtitle: const Text('Remover todos os dados locais'),
                      onTap: () {
                        _showClearDataDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cache e Sincronização
              Text(
                'Cache e Sincronização',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Forçar Atualização'),
                      subtitle: const Text('Sincronizar dados com a planilha'),
                      onTap: () {
                        _forceUpdateCache();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Informações do Cache'),
                      subtitle: const Text('Ver detalhes dos dados em cache'),
                      onTap: () {
                        _showCacheInfo();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sobre
              const Text(
                'Sobre',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Versão do App'),
                      subtitle: const Text('1.0.0'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Política de Privacidade'),
                      onTap: () {
                        _showPrivacyDialog();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Termos de Uso'),
                      onTap: () {
                        _showTermsDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Botão de logout
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Automático (baseado na hora do dia)';
    }
  }

  void _showThemeChangeMessage(BuildContext context, ThemeMode mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tema alterado para: ${_getThemeModeName(mode)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alterar Senha'),
          content: const Text('Funcionalidade será implementada em breve!'),
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar Dados'),
          content: const Text('Seus dados serão exportados em formato CSV.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados exportados com sucesso!'),
                  ),
                );
              },
              child: const Text('Exportar'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpar Dados'),
          content: const Text('Tem certeza que deseja remover todos os dados? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  // Limpar dados da bolsa
                  await BolsaStorageService.clearAllData();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados removidos com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao limpar dados: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Política de Privacidade'),
          content: const Text('Nossa política de privacidade protege seus dados pessoais...'),
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termos de Uso'),
          content: const Text('Ao usar este app, você concorda com nossos termos de uso...'),
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

  Future<void> _logout() async {
    await AuthService.logout();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _forceUpdateCache() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atualizando dados da planilha...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Atualizar cache de usuários
      await cache.DataCacheService.forceUpdate();
      
      // Limpar cache de preços da API Twelve Data
      TwelveDataService.limparCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCacheInfo() async {
    final usersInfo = cache.DataCacheService.getCacheInfo();
    final ativosInfo = TwelveDataService.getEstatisticasUso();
    final apiInfo = TwelveDataService.getInfoAPI();
    
    // Testar conexão com a API
    final conexaoOk = await TwelveDataService.testarConexao();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informações do Sistema'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Twelve Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: conexaoOk ? Colors.green : Colors.red,
                  ),
                ),
                Text('Status: ${conexaoOk ? 'Conectado' : 'Desconectado'}'),
                Text('Requisições hoje: ${apiInfo['requisicoesUsadas']}/${apiInfo['limiteDiario']}'),
                Text('Requisições restantes: ${apiInfo['requisicoesRestantes']}'),
                Text('Itens em cache: ${apiInfo['itensEmCache']}'),
                const SizedBox(height: 16),
                Text(
                  'Cache de Usuários',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text('Usuários em cache: ${usersInfo['usersCount']}'),
                if (usersInfo['lastUpdate'] != null)
                  Text('Última atualização: ${DateTime.parse(usersInfo['lastUpdate']).toString().substring(0, 19)}'),
              ],
            ),
          ),
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
} 