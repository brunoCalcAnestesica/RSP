import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/data_cache_service.dart';
import '../../api/ativos_cache_service.dart';
import '../auth/login_screen.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _statusText = 'Inicializando...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Passo 1: Inicializar cache de dados de usuários
      setState(() {
        _statusText = 'Carregando dados de usuários...';
        _progress = 0.2;
      });
      
      await DataCacheService.initialize();
      
      setState(() {
        _statusText = 'Dados de usuários carregados!';
        _progress = 0.4;
      });
      
      // Passo 2: Inicializar cache de dados de ativos
      setState(() {
        _statusText = 'Carregando dados de ativos...';
        _progress = 0.6;
      });
      
      await AtivosCacheService.initialize();
      
      setState(() {
        _statusText = 'Dados carregados com sucesso!';
        _progress = 0.8;
      });
      
      // Pequena pausa para mostrar o status
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _statusText = 'Verificando login...';
        _progress = 0.8;
      });
      
      // Verificar se usuário está logado
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      setState(() {
        _statusText = 'Inicialização concluída!';
        _progress = 1.0;
      });
      
      // Pequena pausa final
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navegar para a tela apropriada
      if (mounted) {
        if (isLoggedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
      
    } catch (e) {
      print('❌ Erro na inicialização: $e');
      setState(() {
        _statusText = 'Erro na inicialização: $e';
      });
      
      // Mesmo com erro, tentar navegar para login após um tempo
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.blue[900];
    final textColor = isDark ? Colors.white : Colors.white;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.white70;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Ícone
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Título do app
                    Text(
                      'RSP',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Text(
                      'Sistema de Patrimônio',
                      style: TextStyle(
                        fontSize: 18,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Barra de progresso
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Status text
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Informações do cache
                    FutureBuilder<Map<String, dynamic>>(
                      future: Future.value(DataCacheService.getCacheInfo()),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final info = snapshot.data!;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Usuários em cache: ${info['usersCount']}',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                                if (info['lastUpdate'] != null)
                                  Text(
                                    'Última atualização: ${DateTime.parse(info['lastUpdate']).toString().substring(11, 19)}',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 