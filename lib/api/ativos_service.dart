import 'package:http/http.dart' as http;
import 'dart:convert';

class AtivosService {
  static const String _spreadsheetId = '1vW1Zd8r0A7QcbLVmGisfTXcOxFk8arPziqVZIK6AazU';
  static const String _sheetName = 'ATIVOS';
  
  // URL base para acessar a planilha como JSON
  static String get _baseUrl => 'https://opensheet.elk.sh/$_spreadsheetId/$_sheetName';

  // Buscar todos os ativos da planilha
  static Future<List<Map<String, dynamic>>> getAtivos() async {
    try {
      print('🔗 Tentando conectar com a aba ATIVOS...');
      print('📡 URL: $_baseUrl');
      
      final response = await http.get(Uri.parse(_baseUrl));
      
      print('📊 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
              print('✅ Dados carregados com sucesso!');
      
      // Filtrar linhas vazias baseado nas colunas corretas
      final validAtivos = data.where((ativo) => 
        ativo['TICKER'] != null && 
        ativo['TICKER'].toString().isNotEmpty &&
        ativo['NOME DO ATIVO'] != null && 
        ativo['NOME DO ATIVO'].toString().isNotEmpty
      ).toList();
      
      print('✅ Ativos válidos filtrados');
        return validAtivos.cast<Map<String, dynamic>>();
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

  // Buscar ativos por ticker
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

  // Buscar ativo por nome
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

  // Buscar ativos por CNPJ
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

  // Calcular valor total dos ativos
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

  // Buscar estatísticas dos ativos
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


} 