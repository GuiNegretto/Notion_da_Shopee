// Novo arquivo: lib/screens/gerenciar_categorias_page.dart

import 'package:flutter/material.dart';
import '../data/nota_repository.dart';

class GerenciarCategoriasPage extends StatefulWidget {
  final NotaRepository repo;
  const GerenciarCategoriasPage({super.key, required this.repo});

  @override
  State<GerenciarCategoriasPage> createState() => _GerenciarCategoriasPageState();
}

class _GerenciarCategoriasPageState extends State<GerenciarCategoriasPage> {
  Future<List<String>>? _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _categoriasFuture = widget.repo.buscarCategoriasUnicas();
    });
  }

  Future<void> _adicionarCategoria() async {
    final nomeController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty) {
                await widget.repo.adicionarCategoria(nomeController.text);
                Navigator.pop(context);
                _carregarCategorias();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCategoria(String categoria) async {
    // Adicionar um diálogo de confirmação aqui
    await widget.repo.excluirCategoria(categoria);
    _carregarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
      ),
      body: FutureBuilder<List<String>>(
        future: _categoriasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar categorias.'));
          }
          final categorias = snapshot.data!;
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(categoria),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _excluirCategoria(categoria),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCategoria,
        child: const Icon(Icons.add),
      ),
    );
  }
}