import 'package:flutter/material.dart';
import '../repositories/nota_repository.dart';
import '../models/nota.dart';

class NotaPage extends StatefulWidget {
  final NotaRepository notaRepository;
  final Nota? nota;
  const NotaPage({super.key, required this.notaRepository, this.nota});

  @override
  State<NotaPage> createState() => _NotaPageState();
}

class _NotaPageState extends State<NotaPage> {
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  String _prioridade = 'Baixa';
  final _tagTextController = TextEditingController();
  List<String> _tags = [];
  final _categoriaTextController = TextEditingController();
  List<String> _categorias = [];

  @override
  void initState() {
    super.initState();
    if (widget.nota != null) {
      _tituloController.text = widget.nota!.titulo;
      _conteudoController.text = widget.nota!.conteudo;
      _prioridade = widget.nota!.prioridade;
      _tags = widget.nota!.tags;
      _categorias = widget.nota!.categorias;
    }
  }

  Future<void> _salvarNota() async {
    if (_tituloController.text.isEmpty && _conteudoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A nota não pode estar vazia.')),
      );
      return;
    }

    if (widget.nota != null) {
      await widget.notaRepository.atualizarNota(
        widget.nota!.id!,
        _tituloController.text,
        _conteudoController.text,
        prioridade: _prioridade,
        tags: _tags,
        categorias: _categorias,
      );
    } else {
      await widget.notaRepository.inserirNota(
        _tituloController.text,
        _conteudoController.text,
        prioridade: _prioridade,
        tags: _tags,
        categorias: _categorias,
      );
    }
    Navigator.pop(context);
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }

    _tagTextController.clear();
  }
  
  void _addCategoria(String categoria) {
    if (categoria.isNotEmpty && !_categorias.contains(categoria)) {
      setState(() {
        _categorias.add(categoria);
      });
    }

    _categoriaTextController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nota != null ? 'Editar Nota' : 'Nova Nota'),
        actions: [
          if (widget.nota != null)
            IconButton(
  icon: const Icon(Icons.delete),
  onPressed: () async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Nota'),
          content: const Text('Tem certeza que deseja excluir esta nota?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Retorna 'false' se cancelar
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Retorna 'true' se confirmar
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    // Se o usuário confirmar a exclusão
    if (confirmar == true) {
      await widget.notaRepository.excluirNota(widget.nota!.id!);
      Navigator.pop(context); // Volta para a lista de notas
    }
  },
),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarNota,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration.collapsed(hintText: "Título"),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _conteudoController,
                decoration: const InputDecoration.collapsed(hintText: "Conteúdo"),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            // Seção de Prioridade
            Row(
              children: [
                const Text('Prioridade: ', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _prioridade,
                  items: <String>['Alta', 'Média', 'Baixa']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _prioridade = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Seção de Tags (UC05)
            _buildTagSection(),
            const SizedBox(height: 16),
            // Seção de Categorias (UC04)
            _buildCategorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Tags: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: TextField(
                controller: _tagTextController,
                onSubmitted: (value) {
                  _addTag(value);
                },
                decoration: const InputDecoration(
                  hintText: 'Adicionar tags (ex: #trabalho)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text('#$tag'),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Categorias: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: TextField(
                controller: _categoriaTextController,
                onSubmitted: (value) {
                  _addCategoria(value);
                },
                decoration: const InputDecoration(
                  hintText: 'Adicionar categoria',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: _categorias.map((categoria) {
            return Chip(
              label: Text(categoria),
              onDeleted: () {
                setState(() {
                  _categorias.remove(categoria);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}