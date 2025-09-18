import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/nota.dart';

class NotaRepository {
  final Database db;
  NotaRepository(this.db);

  // Método para inserir uma nova nota
  Future<void> inserirNota(String titulo, String conteudo, {
    String prioridade = 'Baixa',
    bool favorito = false,
    List<String> tags = const [],
    List<String> categorias = const [],
  }) async {
    final now = DateTime.now().toIso8601String();
    final notaId = await db.insert('notas', {
      'titulo': titulo,
      'conteudo': conteudo,
      'criado_em': now,
      'atualizado_em': now,
      'favorito': favorito ? 1 : 0,
      'prioridade': prioridade,
    });
    // Insere as tags e categorias associadas
    await _inserirTags(notaId, tags);
    await _inserirCategorias(notaId, categorias);
  }

  // Método para listar todas as notas com suas tags e categorias
Future<List<Map<String, dynamic>>> listarNotas() async {
  final List<Map<String, dynamic>> notasRaw = await db.query('notas', orderBy: 'atualizado_em DESC');
  
  if (notasRaw.isEmpty) {
    return [];
  }

  // Prepara uma lista para armazenar os mapas de notas completos
  List<Map<String, dynamic>> notasCompletas = [];

  // Para cada nota, busca as tags e categorias associadas
  for (var nota in notasRaw) {
    final tags = await _buscarTagsPorNota(nota['id'] as int);
    final categorias = await _buscarCategoriasPorNota(nota['id'] as int);
    
    // Cria um novo mapa para evitar modificação do mapa original da query
    Map<String, dynamic> notaCompleta = Map.from(nota);
    notaCompleta['tags'] = tags;
    notaCompleta['categorias'] = categorias;

    notasCompletas.add(notaCompleta);
  }
  
  return notasCompletas;
}

  // Método para atualizar uma nota
  Future<void> atualizarNota(int id, String titulo, String conteudo, {
    String? prioridade,
    bool? favorito,
    List<String>? tags,
    List<String>? categorias,
  }) async {
    final now = DateTime.now().toIso8601String();
    final Map<String, dynamic> dados = {
      'titulo': titulo,
      'conteudo': conteudo,
      'atualizado_em': now,
    };
    if (prioridade != null) dados['prioridade'] = prioridade;
    if (favorito != null) dados['favorito'] = favorito ? 1 : 0;
    
    await db.update('notas', dados, where: 'id = ?', whereArgs: [id]);
    
    // Atualiza as tags e categorias (remover e reinserir para simplificar)
    if (tags != null) {
      await db.delete('nota_tag', where: 'nota_id = ?', whereArgs: [id]);
      await _inserirTags(id, tags);
    }
    if (categorias != null) {
      await db.delete('nota_categoria', where: 'nota_id = ?', whereArgs: [id]);
      await _inserirCategorias(id, categorias);
    }
  }

  // Método para excluir uma nota
  Future<void> excluirNota(int id) async {
    // ON DELETE CASCADE nas tabelas de associação cuida da exclusão de tags/categorias
    await db.delete('notas', where: 'id = ?', whereArgs: [id]);
  }

  // --- Novos Métodos para Requisitos Funcionais ---
  
  // RF04 - Marcar Nota como Favorita
  Future<void> marcarNotaComoFavorita(int id, bool isFavorite) async {
    await db.update('notas', {'favorito': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  // RF06 - Definir Prioridade da Nota
  Future<void> definirPrioridade(int id, String prioridade) async {
    await db.update('notas', {'prioridade': prioridade}, where: 'id = ?', whereArgs: [id]);
  }

  // RF03 - Buscar Notas (implementação básica)

Future<List<Map<String, dynamic>>> buscarNotas({
  String? termo,
  String? prioridade,
  bool? favorito,
  String? ordenacao = 'atualizado_em DESC',
}) async {
  List<String> conditions = [];
  List<dynamic> args = [];
  
  if (termo != null && termo.isNotEmpty) {
    conditions.add('(titulo LIKE ? OR conteudo LIKE ?)');
    args.add('%$termo%');
    args.add('%$termo%');
  }

  if (prioridade != null) {
    conditions.add('prioridade = ?');
    args.add(prioridade);
  }

  if (favorito != null) {
    conditions.add('favorito = ?');
    args.add(favorito ? 1 : 0);
  }

  String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
  
  final List<Map<String, dynamic>> notas = await db.rawQuery('SELECT * FROM notas $whereClause ORDER BY $ordenacao', args);
  
  return notas;
}
// Em lib/data/nota_repository.dart
// Adicione estes métodos para gerenciar Categorias (RF02) e Tags (RF02)
Future<List<String>> listarTodasCategorias() async {
  final List<Map<String, dynamic>> resultado = await db.query('categorias');
  return resultado.map((e) => e['nome'] as String).toList();
}

Future<List<String>> listarTodasTags() async {
  final List<Map<String, dynamic>> resultado = await db.query('tags');
  return resultado.map((e) => e['nome'] as String).toList();
}
  
  // --- Métodos Privados para Gerenciamento de Tags e Categorias ---

  Future<void> _inserirTags(int notaId, List<String> tags) async {
    for (var nomeTag in tags) {
      final tagId = await _obterOuCriarTag(nomeTag);
      await db.insert('nota_tag', {'nota_id': notaId, 'tag_id': tagId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<int> _obterOuCriarTag(String nome) async {
    final List<Map<String, dynamic>> resultado = await db.query('tags', where: 'nome = ?', whereArgs: [nome]);
    if (resultado.isNotEmpty) {
      return resultado.first['id'];
    } else {
      return await db.insert('tags', {'nome': nome});
    }
  }

  Future<List<String>> _buscarTagsPorNota(int notaId) async {
    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT t.nome FROM tags t
      INNER JOIN nota_tag nt ON t.id = nt.tag_id
      WHERE nt.nota_id = ?
    ''', [notaId]);
    return resultado.map((e) => e['nome'] as String).toList();
  }
  
  Future<void> _inserirCategorias(int notaId, List<String> categorias) async {
    for (var nomeCategoria in categorias) {
      final categoriaId = await _obterOuCriarCategoria(nomeCategoria);
      await db.insert('nota_categoria', {'nota_id': notaId, 'categoria_id': categoriaId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<int> _obterOuCriarCategoria(String nome) async {
    final List<Map<String, dynamic>> resultado = await db.query('categorias', where: 'nome = ?', whereArgs: [nome]);
    if (resultado.isNotEmpty) {
      return resultado.first['id'];
    } else {
      return await db.insert('categorias', {'nome': nome});
    }
  }
  
  Future<List<String>> _buscarCategoriasPorNota(int notaId) async {
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

Future<void> excluirCategoria(String id) async {
  // A exclusão de notas associadas será gerenciada pelas chaves estrangeiras
  await db.delete(
    'categorias',
    where: 'id = ?',
    whereArgs: [id],
  );
}
}

