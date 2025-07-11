# RSP - Rebalancing Service Portfolio

Um aplicativo Flutter para gerenciamento de portfólio com rebalanceamento automático.

## Funcionalidades

### Adição de Ativos com Lista do Google Sheets

Ao adicionar um novo ativo, o aplicativo agora oferece uma lista completa de ativos disponíveis resgatados do Google Sheets:

- **Lista de Ativos**: Clique no ícone de lista (📋) para ver todos os ativos disponíveis
- **Busca Inteligente**: Digite para filtrar ativos por nome/símbolo
- **Preços em Tempo Real**: Cada ativo mostra seu preço atual
- **Seleção Fácil**: Toque em um ativo para selecioná-lo automaticamente
- **Busca de Preço**: O preço atual é buscado automaticamente após a seleção

### Como Usar

1. Vá para a tela de Ativos
2. Clique em "Adicionar Ativo"
3. Selecione o tipo de ativo (Ação, FII, ETF, etc.)
4. Clique no ícone de lista (📋) para ver ativos disponíveis
5. Use o campo de busca para filtrar ativos
6. Toque em um ativo para selecioná-lo
7. Preencha quantidade e preço médio
8. Clique em "Adicionar"

### Recursos da Lista de Ativos

- ✅ **Ativos do Google Sheets**: Lista completa de ativos disponíveis
- ✅ **Preços Atuais**: Mostra o preço de cada ativo
- ✅ **Busca Rápida**: Filtre por nome ou símbolo
- ✅ **Indicadores Visuais**: Ícones coloridos para ativos com preços
- ✅ **Contagem**: Mostra quantos ativos estão disponíveis
- ✅ **Estado de Carregamento**: Indicador visual durante o carregamento

### Configuração do Google Sheets

O aplicativo usa uma planilha pública do Google Sheets para obter os preços dos ativos. A planilha deve ter:

- Coluna A: Símbolo/Nome do ativo
- Coluna B: Preço atual

URL da planilha: `https://docs.google.com/spreadsheets/d/1vW1Zd8r0A7QcbLVmGisfTXcOxFk8arPziqVZIK6AazU/edit`

## Estrutura do Projeto

```
lib/
├── models/           # Modelos de dados
├── screens/          # Telas do aplicativo
├── services/         # Serviços (Google Sheets, preços)
├── widgets/          # Widgets reutilizáveis
└── config/           # Configurações
```

## Tecnologias Utilizadas

- Flutter
- Google Sheets API (pública)
- HTTP para requisições
- Shared Preferences para cache local

## Como Executar

1. Clone o repositório
2. Execute `flutter pub get`
3. Execute `flutter run`

## Contribuição

Para contribuir com o projeto:

1. Faça um fork
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request
