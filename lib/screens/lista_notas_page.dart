import 'package:flutter/material.dart';
import '../repositories/nota_repository.dart';
import '../repositories/categoria_repository.dart';
import '../models/nota.dart';
import '../utils/file.dart';
import 'nota_page.dart';
import 'gerenciar_categorias_page.dart';
import 'configuracoes_page.dart';
import 'busca_avancada_page.dart';

class ListaNotasPage extends StatefulWidget {
  final NotaRepository notaRepository;
  final CategoriaRepository categoriaRepository;
  const ListaNotasPage({super.key, required this.notaRepository, required this.categoriaRepository});

  @override
  State<ListaNotasPage> createState() => _ListaNotasPageState();
}

class _ListaNotasPageState extends State<ListaNotasPage> {
  List<Nota> notas = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _menuScrollController = ScrollController();

  FiltrosAvancados _filtros = FiltrosAvancados();
  bool _filtroExcluido = false;
  String _filtroCategoria = '';
  String _currentTitle = 'Minhas Notas';

  bool _isMenuExpanded = true;
  final double _menuWidth = 250.0;

  bool _showMenuContent = true; 

  String _selectedMenuId = 'Todas as Notas';
  
  List<String> _categorias = []; 

  @override
  void initState() {
    super.initState();
    _carregarNotas();
    _carregarCategorias();
    _searchController.addListener(_filtrarNotas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarNotas({bool resetarScroll = false}) async {
    final termo = _searchController.text.trim();
    
    // Verifica busca exclusiva por tags (qnd começa com #)
    final bool buscaExclusivaPorTag = termo.startsWith('#');
    final String termoLimpo = buscaExclusivaPorTag ? termo.substring(1) : termo;
    
    List<Nota> notasEncontradas = [];
    
    if (buscaExclusivaPorTag) {
      // Busca APENAS por tags
      if (termoLimpo.isNotEmpty) {
        notasEncontradas = await _buscarNotasPorTag(termoLimpo);
      }
    } else {
      // Busca normal (por título e conteúdo)
      final lista = await widget.notaRepository.buscarNotas(
        termo: termo,
        prioridade: _filtros.prioridade == "Todas" ? null : _filtros.prioridade,
        favorito: _filtros.favorito ? true : null,
        excluido: _filtroExcluido ? true : null,
        categoria: _filtroCategoria,
        ordenacao: _filtros.ordenacao,
      );

      // Converte para objetos Nota
      notasEncontradas = lista.map((map) => Nota.fromMap(map)).toList();
      
      // Se houver termo de busca, também busca por tags
      if (termo.isNotEmpty) {
        final notasPorTag = await _buscarNotasPorTag(termo);
        
        // Combina os resultados, evitar duplicidade
        final idsEncontrados = notasEncontradas.map((n) => n.id).toSet();
        for (var nota in notasPorTag) {
          if (!idsEncontrados.contains(nota.id)) {
            notasEncontradas.add(nota);
          }
        }
      }
    }

    setState(() {
      notas = notasEncontradas;
    });
    
    // Reseta o scroll se solicitado
    if (resetarScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    
    // Carrega as tags para cada nota
    for (var n in notas) {
      if (n.id != null) {
        final tags = await widget.notaRepository.tagRepository.buscarTagsPorNota(n.id!);
        setState(() {
          n.tags = tags;
        });
      }
    }
  }

  // Função para buscar notas que contenham uma tag específica
  Future<List<Nota>> _buscarNotasPorTag(String termo) async {
    final termoLower = termo.toLowerCase();
    
    // Busca todas as notas (respeitando os filtros atuais)
    final todasNotas = await widget.notaRepository.buscarNotas(
      termo: "",
      prioridade: _filtros.prioridade == "Todas" ? null : _filtros.prioridade,
      favorito: _filtros.favorito ? true : null,
      excluido: _filtroExcluido ? true : null,
      categoria: _filtroCategoria,
      ordenacao: _filtros.ordenacao,
    );

    List<Nota> notasComTag = [];
    
    for (var notaMap in todasNotas) {
      final nota = Nota.fromMap(notaMap);
      if (nota.id != null) {
        final tags = await widget.notaRepository.tagRepository.buscarTagsPorNota(nota.id!);
        nota.tags = tags;
        
        // Verifica se alguma tag contém o termo
        if (tags.any((tag) => tag.toLowerCase().contains(termoLower))) {
          notasComTag.add(nota);
        }
      }
    }
    
    return notasComTag;
  }

  void _filtrarNotas() {
    _carregarNotas();
  }

  Future<void> _carregarCategorias() async {
    final categorias = await widget.categoriaRepository.buscarCategoriasUnicas();
    if (mounted) {
      setState(() {
        _categorias = categorias;
      });
    }
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
        builder: (context) => GerenciarCategoriasPage(notaRepository: widget.notaRepository, categoriaRepository: widget.categoriaRepository),
      ),
    );
    _carregarCategorias();
    setState(() {});
  }

  Future<void> _navegarConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfiguracoesPage(),
      ),
    );
  }

  Future<void> _abrirFiltrosAvancados() async {
    final filtrosAtualizados = await Navigator.push<FiltrosAvancados>(
      context,
      MaterialPageRoute(
        builder: (context) => BuscaAvancadaPage(filtrosAtuais: _filtros),
      ),
    );

    if (filtrosAtualizados != null) {
      setState(() {
        _filtros = filtrosAtualizados;
      });
      _carregarNotas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuColor = theme.brightness == Brightness.dark 
        ? Colors.black26 
        : Colors.grey;
    
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isMenuExpanded ? _menuWidth : 60,
            color: menuColor,
            child: Column(
              children: [
                if (_isMenuExpanded)
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark 
                          ? const Color.fromRGBO(241, 242, 242, 100) 
                          : const Color.fromRGBO(241, 242, 242, 100) , // ainda na duvida da cor
                    ),
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
                      if (_isMenuExpanded) {
                        _showMenuContent = false;
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() {
                              _showMenuContent = true;
                            });
                          }
                        });
                      } else {
                        _showMenuContent = false;
                      }
                    });
                  },
                ),
                const Divider(color: Colors.white),
                Expanded(
                  child: _showMenuContent || !_isMenuExpanded
                      ? ListView(
                    key: const PageStorageKey<String>('menuListView'),
                    controller: _menuScrollController,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _buildMenuItem(
                        id: "Nova Nota",
                        icon: Icons.note,
                        text: 'Nova Nota',
                        onTap: () {
                          _abrirNota();
                        },
                      ),
                      _buildMenuItem(
                        id: "Importar",
                        icon: Icons.file_download,
                        text: 'Importar',
                        onTap: () async {
                          await lerJsonComDialogo();
                          setState(() {
                            _filtros = FiltrosAvancados();
                            _filtroExcluido = false;
                            _filtroCategoria = '';
                            _currentTitle = "Minhas Notas";
                            _selectedMenuId = "Todas as Notas";
                          });
                          _carregarNotas(resetarScroll: true);
                        },
                      ),
                      _buildMenuItem(
                        id: "Exportar",
                        icon: Icons.file_upload,
                        text: 'Exportar',
                        onTap: () async {
                          final listaNotas = await widget.notaRepository.buscarNotas(
                            termo: "",
                            prioridade: null,
                            favorito: null,
                            excluido: null,
                            categoria: '',
                            ordenacao: null,
                          );

                          salvarJsonComDialogo(listaNotas.map((map) => Nota.fromMap(map)).toList());
                        },
                      ),
                      _buildMenuItem(
                        id: "Configurações",
                        icon: Icons.settings,
                        text: 'Configurações',
                        onTap: _navegarConfiguracoes,
                      ),
                      const Divider(color: Colors.white),
                      
                      _buildMenuItem(
                        id: 'Todas as Notas',
                        icon: Icons.description,
                        text: 'Todas as Notas',
                        onTap: () {
                          setState(() {
                            _filtros = FiltrosAvancados();
                            _filtroExcluido = false;
                            _filtroCategoria = '';
                            _currentTitle = "Minhas Notas";
                            _selectedMenuId = "Todas as Notas";
                          });
                          _carregarNotas(resetarScroll: true);
                        },
                      ),
                      _buildMenuItem(
                        id: 'Favoritas',
                        icon: Icons.star,
                        text: 'Favoritas',
                        onTap: () {
                          setState(() {
                            _filtros = FiltrosAvancados(favorito: true);
                            _filtroExcluido = false;
                            _filtroCategoria = '';
                            _currentTitle = "Favoritas";
                            _selectedMenuId = "Favoritas";
                          });
                          _carregarNotas(resetarScroll: true);
                        },
                      ),
                      _buildMenuItem(
                        id: "Lixeira",
                        icon: Icons.delete,
                        text: 'Lixeira',
                        onTap: () {
                          setState(() {
                            _filtros = FiltrosAvancados();
                            _filtroExcluido = true;
                            _filtroCategoria = '';
                            _currentTitle = "Lixeira";
                            _selectedMenuId = "Lixeira";
                          });
                          _carregarNotas(resetarScroll: true);
                        },
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
                      // Categorias carregadas diretamente sem FutureBuilder
                      ..._categorias.map((categoria) => _buildMenuItem(
                        id: categoria,
                        icon: Icons.folder,
                        text: categoria,
                        onTap: () {
                          setState(() {
                            _filtros = FiltrosAvancados();
                            _filtroExcluido = false;
                            _filtroCategoria = categoria;
                            _currentTitle = categoria;
                            _selectedMenuId = categoria;
                          });
                          _carregarNotas(resetarScroll: true);
                        },
                      )).toList(),
                      _buildMenuItem(
                        id: "Gerenciar Categorias",
                        icon: Icons.add,
                        text: "Gerenciar Categorias",
                        onTap: () {
                          _navegarGerenciarCategoria();
                        },
                      ),
                      
                    ],
                  )
                      : Center(
                          child: _isMenuExpanded ? const CircularProgressIndicator(color: Colors.white) : const SizedBox(),
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
                    // Badge para mostrar filtros ativos
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _abrirFiltrosAvancados,
                        ),
                        if (_temFiltrosAtivos())
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _contarFiltrosAtivos().toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
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
                      fillColor: theme.brightness == Brightness.dark 
                          ? Colors.grey[800] 
                          : Colors.grey[200],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
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
                                  children: nota.tags.map((tag) => Chip(label: Text('#$tag'))).toList(),
                                ),
                              if (nota.categorias.isNotEmpty)
                                Text('Categoria: ${nota.categorias.join(', ')}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              nota.excluido ? Icons.restore_page : nota.favorito ? Icons.favorite : Icons.favorite_border,
                              color: !nota.excluido && nota.favorito ? Colors.red : null,
                            ),
                            onPressed: () async {
                              if (nota.excluido)
                                await widget.notaRepository.restaurarNota(nota.id!);
                              else
                                await widget.notaRepository.marcarNotaComoFavorita(nota.id!, !nota.favorito);

                              await _carregarNotas();
                            },
                          ),
                          onTap: () => nota.excluido ? Null : _abrirNota(nota: nota) ,
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

  bool _temFiltrosAtivos() {
    return (_filtros.prioridade != null && _filtros.prioridade != 'Todas') || 
           _filtros.favorito;
  }

  int _contarFiltrosAtivos() {
    int count = 0;
    if (_filtros.prioridade != null && _filtros.prioridade != 'Todas') count++;
    if (_filtros.favorito) count++;
    return count;
  }

  Widget _buildMenuItem({
    required String id,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedMenuId == id;
    final Color highlightColor = isSelected ? Colors.white12 : Colors.transparent;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: highlightColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              if (_isMenuExpanded) const SizedBox(width: 16),
              if (_isMenuExpanded)
              AnimatedOpacity(
                opacity: _showMenuContent ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Text(text, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}