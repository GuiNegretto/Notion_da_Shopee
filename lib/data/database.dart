// Arquivo: lib/data/database.dart

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class AppDatabase {
  static Future<Database> initDb() async {
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;

    final dbPath = await _getDatabasePath('notas.db');

    return await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        // Aumente a versão do banco de dados quando a estrutura mudar
        version: 2, 
        onCreate: (db, version) async {
          // Tabela 'notas' atualizada com favorito e prioridade
          await db.execute('''
            CREATE TABLE notas(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              titulo TEXT,
              conteudo TEXT,
              criado_em TEXT,
              atualizado_em TEXT,
              favorito INTEGER DEFAULT 0,
              prioridade TEXT DEFAULT 'Baixa',
              excluido INTEGER DEFAULT 0
            )
          ''');
          // Tabela para armazenar as categorias
          await db.execute('''
            CREATE TABLE categorias(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nome TEXT UNIQUE
            )
          ''');
          // Tabela para armazenar as tags
          await db.execute('''
            CREATE TABLE tags(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nome TEXT UNIQUE
            )
          ''');
          // Tabela de associação entre notas e categorias (muitos-para-muitos)
          await db.execute('''
            CREATE TABLE nota_categoria(
              nota_id INTEGER,
              categoria_id INTEGER,
              FOREIGN KEY(nota_id) REFERENCES notas(id) ON DELETE CASCADE,
              FOREIGN KEY(categoria_id) REFERENCES categorias(id) ON DELETE CASCADE,
              PRIMARY KEY(nota_id, categoria_id)
            )
          ''');
          // Tabela de associação entre notas e tags (muitos-para-muitos)
          await db.execute('''
            CREATE TABLE nota_tag(
              nota_id INTEGER,
              tag_id INTEGER,
              FOREIGN KEY(nota_id) REFERENCES notas(id) ON DELETE CASCADE,
              FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE,
              PRIMARY KEY(nota_id, tag_id)
            )
          ''');
        },
      ),
    );
  }

  static Future<String> _getDatabasePath(String dbName) async {
    final dbFolder = Directory.current.path;
    return join(dbFolder, dbName);
  }
}