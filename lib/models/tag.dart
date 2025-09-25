class Tag {
  int? id;
  String nome;

  Tag({
    this.id,
    required this.nome,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      nome: map['nome']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}