import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/nota.dart';
import './categoria_repository.dart';
import './tag_repository.dart';

class NotaRepository {
  final Database db;
  final CategoriaRepository categoriaRepository;
  final TagRepository tagRepository;
  NotaRepository(this.db, this.categoriaRepository, this.tagRepository);

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
      'excluido': 0
    });

    // Insere as tags e categorias associadas
    await tagRepository.inserirTags(notaId, tags);
    await categoriaRepository.inserirCategorias(notaId, categorias);
  }

  // Método para listar todas as notas com suas tags e categorias
  Future<List<Map<String, dynamic>>> listarNotas() async {
    await db.rawQuery('PRAGMA read_uncommitted = 1;');
    
    final List<Map<String, dynamic>> notasRaw = await db.query('notas', where: 'excluido = ?', whereArgs: ['0'], orderBy: 'atualizado_em DESC');
    
    if (notasRaw.isEmpty) {
      return [];
    }

    // Prepara uma lista para armazenar os mapas de notas completos
    List<Map<String, dynamic>> notasCompletas = [];

    // Para cada nota, busca as tags e categorias associadas
    for (var nota in notasRaw) {
      final tags = await tagRepository.buscarTagsPorNota(nota['id'] as int);
      final categorias = await categoriaRepository.buscarCategoriasPorNota(nota['id'] as int);
      
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
        await tagRepository.inserirTags(id, tags);
      }
      if (categorias != null) {
        await db.delete('nota_categoria', where: 'nota_id = ?', whereArgs: [id]);
        await categoriaRepository.inserirCategorias(id, categorias);
      }
    }

    // Método para excluir uma nota
    Future<void> excluirNota(int id) async {
      
      await db.update('notas', {'excluido': 1}, where: 'id = ?', whereArgs: [id]);
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

    // Método para restaurar uma nota
    Future<void> restaurarNota(int id) async {
      
      await db.update('notas', {'excluido': 0}, where: 'id = ?', whereArgs: [id]);
    }

    // RF03 - Buscar Notas (implementação básica)

  Future<List<Map<String, dynamic>>> buscarNotas({
    String? termo,
    String? prioridade,
    bool? favorito,
    bool? excluido,
    String? categoria,
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

    conditions.add('excluido = ?');
    args.add(excluido != null ? 1 : 0);
    
    if (categoria != '') {
      conditions.add('EXISTS (select 1 from nota_categoria nc inner join categorias c on c.id = nc.categoria_id where nc.nota_id = n.id and c.nome = ?)');
      args.add('$categoria');
    }

    String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    
    await db.rawQuery('PRAGMA read_uncommitted = 1;');
    final List<Map<String, dynamic>> notas = await db.rawQuery('SELECT * FROM notas n $whereClause ORDER BY $ordenacao', args);
    
    return notas;
  }
}

