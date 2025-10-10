import 'package:flutter/material.dart';
import '../repositories/nota_repository.dart';
import '../models/nota.dart';

class BuscaAvancadaPage extends StatefulWidget {
  final NotaRepository notaRepository;
  const BuscaAvancadaPage({super.key, required this.notaRepository});

  @override
  State<BuscaAvancadaPage> createState() => _BuscaAvancadaPageState();
}

class _BuscaAvancadaPageState extends State<BuscaAvancadaPage> {
  final _termoController = TextEditingController();
  List<Nota> resultados = [];
  bool isLoading = false;
  String? _filtroPrioridade;
  bool _filtroFavorito = false;
  bool _filtroExcluido = false;

  Future<void> _buscarNotas() async {
    setState(() => isLoading = true);
    final resultadosRaw = await widget.notaRepository.buscarNotas(
      termo: _termoController.text,
      prioridade: _filtroPrioridade == "Todas" ? null : _filtroPrioridade ,
      favorito: _filtroFavorito ? true : null,
      excluido: _filtroExcluido ? true : null,
    );
    setState(() {
      resultados = resultadosRaw.map((map) => Nota.fromMap(map)).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Notas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _termoController,
                  decoration: const InputDecoration(
                    labelText: 'Termo de Busca',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _buscarNotas(),
                ),
                const SizedBox(height: 16),
                // Adicionei Padding para um visual mais organizado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filtro de Prioridade
                      DropdownButton<String>(
                        hint: const Text('Prioridade'),
                        value: _filtroPrioridade,
                        items: <String>['Alta', 'Média', 'Baixa', 'Todas']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _filtroPrioridade = newValue;
                            _buscarNotas();
                          });
                        },
                      ),
                      // Filtro de Favorito
                      Row(
                        children: [
                          Checkbox(
                            value: _filtroFavorito,
                            onChanged: (bool? value) {
                              setState(() {
                                _filtroFavorito = value ?? false;
                                _buscarNotas();
                              });
                            },
                          ),
                          const Text('Favorito'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _buscarNotas,
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final nota = resultados[index];
                  return ListTile(
                    title: Text(nota.titulo),
                    subtitle: Text(nota.conteudo),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}