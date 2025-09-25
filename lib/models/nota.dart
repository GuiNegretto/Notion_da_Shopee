class Nota {
  int? id;
  String titulo;
  String conteudo;
  DateTime criadoEm;
  DateTime atualizadoEm;
  bool favorito;
  String prioridade;
  List<String> tags;
  List<String> categorias;
  bool excluido;

  Nota({
    this.id,
    required this.titulo,
    required this.conteudo,
    required this.criadoEm,
    required this.atualizadoEm,
    this.favorito = false,
    this.prioridade = 'Baixa',
    this.tags = const [],
    this.categorias = const [],
    this.excluido = false
  });

  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      id: map['id'],
      titulo: map['titulo'],
      conteudo: map['conteudo'],
      criadoEm: DateTime.parse(map['criado_em']),
      atualizadoEm: DateTime.parse(map['atualizado_em']),
      favorito: map['favorito'] == 1,
      prioridade: map['prioridade'] ?? 'Baixa',
      // Agora, o construtor lê as listas de tags e categorias do mapa
      tags: List<String>.from(map['tags'] ?? []),
      categorias: List<String>.from(map['categorias'] ?? []),
      excluido: map['excluido'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'favorito': favorito ? 1 : 0,
      'prioridade': prioridade,
      'excluido': excluido ? 1 : 0,
    };
  }
}