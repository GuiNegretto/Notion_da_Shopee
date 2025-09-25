import 'package:flutter/material.dart';
import 'data/database.dart';
import 'repositories/nota_repository.dart';
import 'screens/lista_notas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.initDb();
  final notaRepository = NotaRepository(db);

  runApp(MyApp(notaRepository: notaRepository));
}

class MyApp extends StatelessWidget {
  final NotaRepository notaRepository;
  const MyApp({super.key, required this.notaRepository});

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
      home: ListaNotasPage(notaRepository: notaRepository),
    );
  }
}
