import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ativo.dart';

class BolsaStorageService {
  static const String _classesKey = 'bolsa_classes';
  static const String _ativosKey = 'bolsa_ativos';

  // Salvar classes de ativos
  static Future<void> saveClasses(List<ClasseAtivo> classes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Converter classes para JSON
      final classesJson = classes.map((classe) => {
        'nome': classe.nome,
        'cor': classe.cor.value,
        'icone': classe.icone.codePoint,
        'ativos': classe.ativos.map((ativo) => {
          'ticker': ativo.ticker,
          'quantidade': ativo.quantidade,
          'precoMedio': ativo.precoMedio,
          'precoAtual': ativo.precoAtual,
        }).toList(),
      }).toList();
      
      await prefs.setString(_classesKey, json.encode(classesJson));
      print('💾 Classes de ativos salvas com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar classes: $e');
    }
  }

  // Carregar classes de ativos
  static Future<List<ClasseAtivo>> loadClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString(_classesKey);
      
      if (classesJson != null) {
        final List<dynamic> classesList = json.decode(classesJson);
        final classes = classesList.map((classeMap) {
          final ativos = (classeMap['ativos'] as List).map((ativoMap) {
            return Ativo(
              ticker: ativoMap['ticker'] ?? '',
              quantidade: ativoMap['quantidade'] ?? '',
              precoMedio: ativoMap['precoMedio'] ?? '',
              precoAtual: ativoMap['precoAtual'] ?? '',
            );
          }).toList();
          
          return ClasseAtivo(
            nome: classeMap['nome'] ?? '',
            cor: Color(classeMap['cor'] ?? Colors.blue.value),
            icone: IconData(classeMap['icone'] ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
            ativos: ativos,
          );
        }).toList();
        
        print('📦 Classes de ativos carregadas com sucesso');
        return classes;
      }
    } catch (e) {
      print('❌ Erro ao carregar classes: $e');
    }
    
    // Retornar classes padrão se não houver dados salvos
    return [
      ClasseAtivo(nome: 'Ação', cor: Colors.blue, icone: Icons.show_chart),
      ClasseAtivo(nome: 'FII', cor: Colors.purple, icone: Icons.domain),
      ClasseAtivo(nome: 'ETF', cor: Colors.orange, icone: Icons.pie_chart),
      ClasseAtivo(nome: 'BDR', cor: Colors.teal, icone: Icons.language),
      ClasseAtivo(nome: 'Outro', cor: Colors.grey, icone: Icons.category),
    ];
  }

  // Limpar todos os dados salvos
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_classesKey);
      await prefs.remove(_ativosKey);
      print('🗑️ Dados da bolsa limpos com sucesso');
    } catch (e) {
      print('❌ Erro ao limpar dados: $e');
    }
  }

  // Verificar se há dados salvos
  static Future<bool> hasSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_classesKey) != null;
    } catch (e) {
      return false;
    }
  }
} 