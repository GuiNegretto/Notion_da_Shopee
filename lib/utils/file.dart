import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/database.dart';
import '../models/nota.dart';
import '../repositories/nota_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/categoria_repository.dart';

Future<void> salvarJsonComDialogo(List<Nota> notas) async {
  String jsonString = jsonEncode(
    notas.map((nota) => nota.toMap(toView: false)).toList()
  );
  
  String? caminhoSelecionado = await FilePicker.platform.saveFile(
    dialogTitle: 'Exportar Dados',
    fileName: 'minhas_notas.json',
    allowedExtensions: ['json'],
    type: FileType.custom,
  );

  if (caminhoSelecionado == null) {
    return;
  }

  try {
    if (!caminhoSelecionado.toLowerCase().endsWith('.json')) {
      caminhoSelecionado = '$caminhoSelecionado.json';
    }
    
    final File arquivo = File(caminhoSelecionado);
    await arquivo.writeAsString(jsonString);

  } catch (e) {
    print('Erro ao salvar o JSON: $e');
  }
}

Future<void> lerJsonComDialogo() async {
  FilePickerResult? resultado = await FilePicker.platform.pickFiles(
    dialogTitle: 'Selecione o arquivo JSON de Lista',
    type: FileType.custom,
    allowedExtensions: ['json'],
    allowMultiple: false,
  );

  if (resultado == null) {
    return;
  }

  try {
    String? caminhoArquivo = resultado.files.single.path;
    
    if (caminhoArquivo == null) {
        return;
    }

    final File arquivo = File(caminhoArquivo);
    
    String conteudoJson = await arquivo.readAsString();

    dynamic dadosDecodificados = jsonDecode(conteudoJson);

    if (dadosDecodificados is List) {

      final db = await AppDatabase.initDb();
      final categoriaRepository = CategoriaRepository(db);
      final tagRepository = TagRepository(db);
      final notaRepository = NotaRepository(db, categoriaRepository, tagRepository);

      dadosDecodificados.forEach((dado) async {
        await notaRepository.inserirNota(
          dado["titulo"],
          dado["conteudo"],
          prioridade: dado["prioridade"]
        );
      });
      
    } else {
      print(conteudoJson);
    }    

  } catch (e) {
    print("ERRO ao ler ou processar o arquivo JSON: $e");
  }
}