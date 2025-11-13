import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final Database db;
  CategoriaRepository(this.db);

  Future<List<String>> listarTodasCategorias() async {
    final List<Map<String, dynamic>> resultado = await db.query('categorias');
    return resultado.map((e) => e['nome'] as String).toList();
  }

  
  Future<void> inserirCategorias(int notaId, List<String> categorias) async {
    for (var nomeCategoria in categorias) {
      final categoriaId = await obterOuCriarCategoria(nomeCategoria);
      await db.insert('nota_categoria', {'nota_id': notaId, 'categoria_id': categoriaId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<int> obterOuCriarCategoria(String nome) async {
    final List<Map<String, dynamic>> resultado = await db.query('categorias', where: 'nome = ?', whereArgs: [nome]);
    if (resultado.isNotEmpty) {
      return resultado.first['id'];
    } else {
      return await db.insert('categorias', {'nome': nome});
    }
  }
  
  Future<List<String>> buscarCategoriasPorNota(int notaId) async {
    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT c.nome FROM categorias c
      INNER JOIN nota_categoria nc ON c.id = nc.categoria_id
      WHERE nc.nota_id = ?
    ''', [notaId]);
    return resultado.map((e) => e['nome'] as String).toList();
  }

  Future<List<String>> buscarCategoriasUnicas() async {
    final List<Map<String, dynamic>> categoriasRaw = await db.query('categorias');
    return categoriasRaw.map((e) => e['nome'] as String).toList();
  }

  Future<void> adicionarCategoria(String nome) async {
    await db.insert('categorias', {'nome': nome}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> editarCategoria(int id, String novoNome) async {
    await db.update(
      'categorias',
      {'nome': novoNome},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> excluirCategoria(String nome) async {
    // A exclusão de notas associadas será gerenciada pelas chaves estrangeiras
    await db.delete(
      'categorias',
      where: 'nome = ?',
      whereArgs: [nome],
    );
  }
}