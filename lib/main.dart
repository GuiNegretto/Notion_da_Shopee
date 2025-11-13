import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database.dart';
import 'repositories/nota_repository.dart';
import 'repositories/categoria_repository.dart';
import 'repositories/tag_repository.dart';
import 'screens/lista_notas_page.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.initDb();
  final categoriaRepository = CategoriaRepository(db);
  final tagRepository = TagRepository(db);
  final notaRepository = NotaRepository(db, categoriaRepository, tagRepository);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        notaRepository: notaRepository,
        categoriaRepository: categoriaRepository,
      ),
    ),
  );
}
// ... código anterior

class MyApp extends StatelessWidget {
  final NotaRepository notaRepository;
  final CategoriaRepository categoriaRepository;
  const MyApp({super.key, required this.notaRepository, required this.categoriaRepository});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Notion da Shopee',
      themeMode: themeProvider.themeMode,
      // Tema Escuro
      darkTheme: ThemeData(
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
        // CORREÇÃO AQUI: Use CardThemeData
        cardTheme: CardThemeData(
          color: Colors.grey[850],
        ),

    chipTheme: ChipThemeData(
    backgroundColor: Colors.blue.shade900,
    labelStyle: TextStyle(color: Colors.blue.shade100),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
      ),
      // Tema Claro
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.grey,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.grey,
        ),
        // CORREÇÃO AQUI: Use CardThemeData
        cardTheme: CardThemeData( 
          color: Colors.white,
          elevation: 2,
        ),

          chipTheme: ChipThemeData(
    backgroundColor: Colors.blue.shade50,
    labelStyle: TextStyle(color: Colors.blue.shade900),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
      ),
      home: ListaNotasPage(
        notaRepository: notaRepository,
        categoriaRepository: categoriaRepository,
      ),
    );
  }
}