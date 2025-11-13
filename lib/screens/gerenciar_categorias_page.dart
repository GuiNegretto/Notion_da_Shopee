// Novo arquivo: lib/screens/gerenciar_categorias_page.dart

import 'package:flutter/material.dart';
import '../repositories/nota_repository.dart';
import '../repositories/categoria_repository.dart';

class GerenciarCategoriasPage extends StatefulWidget {
  final NotaRepository notaRepository;
  final CategoriaRepository categoriaRepository;
  const GerenciarCategoriasPage({super.key, required this.notaRepository, required this.categoriaRepository});

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
      _categoriasFuture = widget.categoriaRepository.buscarCategoriasUnicas();
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
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isNotEmpty) {
                await widget.categoriaRepository.adicionarCategoria(nomeController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _carregarCategorias();
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCategoria(String categoria) async {
    // Diálogo de confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a categoria "$categoria"?\n\nEsta ação removerá a categoria de todas as notas associadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    // Se confirmou, exclui a categoria
    if (confirmar == true) {
      try {
        await widget.categoriaRepository.excluirCategoria(categoria);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Categoria "$categoria" excluída com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarCategorias();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir categoria: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar categorias: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _carregarCategorias,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma categoria criada',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toque no botão + para adicionar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          final categorias = snapshot.data!;
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blue),
                  title: Text(
                    categoria,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    tooltip: 'Excluir categoria',
                    onPressed: () => _excluirCategoria(categoria),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCategoria,
        tooltip: 'Adicionar categoria',
        child: const Icon(Icons.add),
      ),
    );
  }
}