import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/tag.dart';

class TagRepository {
  final Database db;
  TagRepository(this.db);

  Future<List<String>> listarTodasTags() async {
    final List<Map<String, dynamic>> resultado = await db.query('tags');
    return resultado.map((e) => e['nome'] as String).toList();
  }
    
  Future<void> inserirTags(int notaId, List<String> tags) async {
    for (var nomeTag in tags) {
      final tagId = await obterOuCriarTag(nomeTag);
      await db.insert('nota_tag', {'nota_id': notaId, 'tag_id': tagId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<int> obterOuCriarTag(String nome) async {
    final List<Map<String, dynamic>> resultado = await db.query('tags', where: 'nome = ?', whereArgs: [nome]);
    if (resultado.isNotEmpty) {
      return resultado.first['id'];
    } else {
      return await db.insert('tags', {'nome': nome});
    }
  }

  Future<List<String>> buscarTagsPorNota(int notaId) async {
    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT t.nome FROM tags t
      INNER JOIN nota_tag nt ON t.id = nt.tag_id
      WHERE nt.nota_id = ?
    ''', [notaId]);
    return resultado.map((e) => e['nome'] as String).toList();
  }

  Future<void> adicionarTagNaNota(int notaId, String nomeTag) async {
    final tagId = await obterOuCriarTag(nomeTag);
    await db.insert('nota_tag', {'nota_id': notaId, 'tag_id': tagId},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removerTagDaNota(int notaId, String nomeTag) async {
    final List<Map<String, dynamic>> resultado = await db.query('tags', where: 'nome = ?', whereArgs: [nomeTag]);
    if (resultado.isEmpty) return;
    final tagId = resultado.first['id'] as int;
    await db.delete('nota_tag', where: 'nota_id = ? AND tag_id = ?', whereArgs: [notaId, tagId]);
  }
}
