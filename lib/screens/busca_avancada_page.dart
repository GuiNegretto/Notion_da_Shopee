import 'package:flutter/material.dart';

class FiltrosAvancados {
  String? prioridade;
  bool favorito;
  String ordenacao;

  FiltrosAvancados({
    this.prioridade,
    this.favorito = false,
    this.ordenacao = 'atualizado_em DESC',
  });

  FiltrosAvancados copyWith({
    String? prioridade,
    bool? favorito,
    String? ordenacao,
  }) {
    return FiltrosAvancados(
      prioridade: prioridade ?? this.prioridade,
      favorito: favorito ?? this.favorito,
      ordenacao: ordenacao ?? this.ordenacao,
    );
  }
}

class BuscaAvancadaPage extends StatefulWidget {
  final FiltrosAvancados filtrosAtuais;

  const BuscaAvancadaPage({
    super.key,
    required this.filtrosAtuais,
  });

  @override
  State<BuscaAvancadaPage> createState() => _BuscaAvancadaPageState();
}

class _BuscaAvancadaPageState extends State<BuscaAvancadaPage> {
  late FiltrosAvancados _filtros;

  @override
  void initState() {
    super.initState();
    _filtros = FiltrosAvancados(
      prioridade: widget.filtrosAtuais.prioridade,
      favorito: widget.filtrosAtuais.favorito,
      ordenacao: widget.filtrosAtuais.ordenacao,
    );
  }

  void _limparFiltros() {
    setState(() {
      _filtros = FiltrosAvancados();
    });
  }

  void _aplicarFiltros() {
    Navigator.pop(context, _filtros);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros Avançados'),
        actions: [
          TextButton.icon(
            onPressed: _limparFiltros,
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpar'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Prioridade
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Prioridade',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _filtros.prioridade,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecione a prioridade',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: <String>['Alta', 'Média', 'Baixa', 'Todas']
                          .map((String value) => DropdownMenuItem(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: _getCorPrioridade(value),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _filtros.prioridade = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            

            const SizedBox(height: 16),

            // Seção de Ordenação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sort, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Ordenação',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _filtros.ordenacao,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'atualizado_em DESC',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 16),
                              SizedBox(width: 8),
                              Text('Mais Recentes'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'atualizado_em ASC',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 16),
                              SizedBox(width: 8),
                              Text('Mais Antigas'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _filtros.ordenacao = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Resumo dos filtros ativos
            if (_temFiltrosAtivos())
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filtros Ativos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._getResumoFiltros(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _aplicarFiltros,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Aplicar Filtros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCorPrioridade(String prioridade) {
    switch (prioridade) {
      case 'Alta':
        return Colors.red;
      case 'Média':
        return Colors.orange;
      case 'Baixa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _temFiltrosAtivos() {
    return _filtros.prioridade != null;
    //return _filtros.prioridade != null || _filtros.favorito;
  }

  List<Widget> _getResumoFiltros() {
    List<Widget> resumo = [];
    
    if (_filtros.prioridade != null && _filtros.prioridade != 'Todas') {
      resumo.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16),
              const SizedBox(width: 8),
              Text('Prioridade: ${_filtros.prioridade}'),
            ],
          ),
        ),
      );
    }

    
    if (resumo.isEmpty) {
      resumo.add(
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Nenhum filtro ativo'),
        ),
      );
    }
    
    return resumo;
  }
}