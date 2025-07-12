import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // Verificar se usuário está logado (sem requisições desnecessárias)
      setState(() {
        _statusText = 'Verificando login...';
        _progress = 0.5;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      setState(() {
        _statusText = 'Inicialização concluída!';
        _progress = 1.0;
      });
      
      // Navegar para a tela apropriada imediatamente
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
      // Mesmo com erro, navegar para login
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
                    
                    // Remover informações do cache para acelerar o carregamento
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