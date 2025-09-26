import 'package:flutter/material.dart';
import 'data/database.dart';
import 'repositories/nota_repository.dart';
import 'repositories/categoria_repository.dart';
import 'repositories/tag_repository.dart';
import 'screens/lista_notas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.initDb();
  final categoriaRepository = CategoriaRepository(db);
  final tagRepository = TagRepository(db);
  final notaRepository = NotaRepository(db, categoriaRepository, tagRepository);

  runApp(MyApp(notaRepository: notaRepository, categoriaRepository: categoriaRepository));
}

class MyApp extends StatelessWidget {
  final NotaRepository notaRepository;
  final CategoriaRepository categoriaRepository;
  const MyApp({super.key, required this.notaRepository, required this.categoriaRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notion da Shopee',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[850],
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
        ),
      ),
      home: ListaNotasPage(notaRepository: notaRepository, categoriaRepository: categoriaRepository),
    );
  }
}
