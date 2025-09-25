import 'package:flutter/material.dart';
import '../repositories/nota_repository.dart';
import '../models/nota.dart';
import 'nota_page.dart';
import 'gerenciar_categorias_page.dart';

class ListaNotasPage extends StatefulWidget {
  final NotaRepository notaRepository;
  const ListaNotasPage({super.key, required this.notaRepository});

  @override
  State<ListaNotasPage> createState() => _ListaNotasPageState();
}

class _ListaNotasPageState extends State<ListaNotasPage> {
  List<Nota> notas = [];
  final _searchController = TextEditingController();

  String? _filtroPrioridade;
  bool _filtroFavorito = false;
  String _ordenacao = 'atualizado_em DESC';
  String _currentTitle = 'Minhas Notas';

  bool _isMenuExpanded = true;
  final double _menuWidth = 250.0;

  @override
  void initState() {
    super.initState();
    _carregarNotas();
    _searchController.addListener(_filtrarNotas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarNotas() async {
    final termo = _searchController.text;
    final lista = await widget.notaRepository.buscarNotas(
      termo: termo,
      prioridade: _filtroPrioridade == "Todas" ? null : _filtroPrioridade,
      favorito: _filtroFavorito ? true : null,
      ordenacao: _ordenacao,
    );

    setState(() {
      notas = lista.map((map) => Nota.fromMap(map)).toList();
    });
  }

  void _filtrarNotas() {
    _carregarNotas();
  }

  Future<void> _abrirNota({Nota? nota}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotaPage(notaRepository: widget.notaRepository, nota: nota),
      ),
    );
    _carregarNotas();
  }

  Future<void> _navegarGerenciarCategoria() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GerenciarCategoriasPage(notaRepository: widget.notaRepository),
      ),
    );
    setState(() {});
  }

  void _abrirFiltrosModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Filtros Avançados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _filtroPrioridade,
                      hint: const Text('Filtrar por prioridade'),
                      items: <String>['Alta', 'Média', 'Baixa', 'Todas']
                          .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                        setStateModal(() {
                          _filtroPrioridade = newValue;
                        });
                        _carregarNotas();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _filtroFavorito,
                          onChanged: (bool? value) {
                            setStateModal(() {
                              _filtroFavorito = value ?? false;
                            });
                            _carregarNotas();
                          },
                        ),
                        const Text('Apenas Favoritas'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _ordenacao,
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'atualizado_em DESC', child: Text('Mais Recentes')),
                        const DropdownMenuItem(value: 'atualizado_em ASC', child: Text('Mais Antigas')),
                      ],
                      onChanged: (String? newValue) {
                        setStateModal(() {
                          _ordenacao = newValue!;
                        });
                        _carregarNotas();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isMenuExpanded ? _menuWidth : 60,
            color: Colors.black26,
            child: Column(
              children: [
                if (_isMenuExpanded)
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color.fromRGBO(241, 242, 242, 100)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 60),
                IconButton(
                  icon: Icon(_isMenuExpanded ? Icons.menu_open : Icons.menu),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      _isMenuExpanded = !_isMenuExpanded;
                    });
                  },
                ),
                const Divider(color: Colors.white),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildMenuItem(
                        icon: Icons.note,
                        text: 'Nova Nota',
                        onTap: () {
                          _abrirNota();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.file_upload,
                        text: 'Importar',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.file_download,
                        text: 'Exportar',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        text: 'Configurações',
                        onTap: () {},
                      ),
                      const Divider(color: Colors.white),
                      if (_isMenuExpanded)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      FutureBuilder<List<String>>(
                        future: widget.notaRepository.buscarCategoriasUnicas(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Text('Erro ao carregar categorias.');
                          } else {
                            final categorias = snapshot.data ?? [];
                            return Column(
                              children: [
                                ...categorias.map((categoria) => _buildMenuItem(
                                  icon: Icons.folder,
                                  text: categoria,
                                  onTap: () {
                                    // TODO: Implementar filtro por categoria (RF02)
                                  },
                                )).toList(),
                                _buildMenuItem(
                                  icon: Icons.add,
                                  text: 'Adicionar Categoria',
                                  onTap: () {
                                    _navegarGerenciarCategoria();
                                  },
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const Divider(color: Colors.white),
                      if (_isMenuExpanded)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Favoritos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      _buildMenuItem(
                        icon: Icons.star,
                        text: 'Favoritas',
                        onTap: () {
                          setState(() {
                            _filtroFavorito = true;
                            _currentTitle = "Favoritos";
                            _carregarNotas();
                          });
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.description,
                        text: 'Todas as Notas',
                        onTap: () {
                          setState(() {
                            _filtroFavorito = false;
                            _currentTitle = "Minhas Notas";
                            _carregarNotas();
                          });
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.delete,
                        text: 'Lixeira',
                        onTap: () {
                          setState(() {
                            _currentTitle = "Lixeira";
                            // TODO: Lógica para exibir notas na lixeira
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: Text(_currentTitle),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _abrirFiltrosModal,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar notas...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: notas.length,
                    itemBuilder: (context, index) {
                      final nota = notas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(nota.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nota.conteudo, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('Prioridade: ${nota.prioridade}'),
                              ),
                              if (nota.tags.isNotEmpty)
                                Wrap(
                                  spacing: 4.0,
                                  children: nota.tags.map((tag) => Text('#$tag', style: const TextStyle(color: Colors.blueAccent))).toList(),
                                ),
                              if (nota.categorias.isNotEmpty)
                                Text('Categoria: ${nota.categorias.join(', ')}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              nota.favorito ? Icons.favorite : Icons.favorite_border,
                              color: nota.favorito ? Colors.red : null,
                            ),
                            onPressed: () async {
                              await widget.notaRepository.marcarNotaComoFavorita(nota.id!, !nota.favorito);
                              await _carregarNotas();
                            },
                          ),
                          onTap: () => _abrirNota(nota: nota),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            if (_isMenuExpanded) const SizedBox(width: 16),
            if (_isMenuExpanded) Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}