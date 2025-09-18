import 'package:flutter/material.dart';
import 'data/database.dart';
import 'data/nota_repository.dart';
import 'screens/lista_notas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.initDb();
  final repo = NotaRepository(db);

  runApp(MyApp(repo: repo));
}

class MyApp extends StatelessWidget {
  final NotaRepository repo;
  const MyApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas com SQLite',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[850],
        scaffoldBackgroundColor: Colors.grey[900],
        // Removendo 'const' daqui para permitir o uso de Colors.grey[850]
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
        ),
      ),
      home: ListaNotasPage(repo: repo),
    );
  }
}
