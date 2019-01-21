import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class CompressScreen extends StatefulWidget {
  @override
  _CompressScreenState createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comprimir vídeo"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: OutlineButton(
          onPressed: () async {
            try {
              String path = await getFile();
              _processarVideo(context, path);
            } catch (e) {}
          },
          child: Text("Escolher Vídeo"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          borderSide: BorderSide(color: Colors.purple.withOpacity(0.7)),
          textColor: Colors.purple,
        ),
      ),
    );
  }

  Future getFile() async {
    return await FilePicker.getFilePath(
      type: FileType.CUSTOM,
      fileExtension: 'mp4',
    );
  }

  Future<void> _processarVideo(BuildContext context, String path) async {
    String _title = "Processando o vídeo...";
    Widget _content;
    List<Widget> _actions;

    try {
      File file = File(path);

      if (!file.existsSync()) {
        throw Exception("Nenhum arquivo foi encontrado!");
      }

      String newFileName = "${DateTime.now().millisecondsSinceEpoch}_";

      newFileName += "h264_${withoutExtension(basename(path))}";

      newFileName += extension(path);

      File newFile = File(join(file.parent.path, newFileName));

      _content = Text(newFile.path);

      final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

      List<String> arguments = [
        "-i", //Entrada
        file.path,
        "-c:v", //Codec
        "libx264",
        "-crf", //Perda de taxas, quanto maior, mais perda. variar entre 18 e 28
        "25",
        "-pix_fmt", //Formato dos pixels, não entendi muito bem mas ajudou na compressão
        "yuv420p",
        /**
         * As 3 linhas abaixo servem para tornar o vídeo compatível com mais versões do android.
         * **/
//        "-profile:v",
//        "baseline",
//        "-level",
//        "3.0",
        "-movflags",
        "+faststart",
        /**
         * As 2 linhas abaixo servem para tornar o codec h.265 compatível com ios
         * **/
//        "-vtag",
//        "hvc1",
        "-preset", //Velocidade X Tamanho do arquivo
        "veryfast",
        "-threads", //Threads para compressão, 0 significa automatico
        "0",
        "-vf", //Escalar o tamanho do vídeo
        "scale=w=640:h=640:force_original_aspect_ratio=decrease",
//        "-r",
//        "30",
        "-b:a",
        "96k",
        newFile.path,
      ];

      _flutterFFmpeg.getExternalLibraries();

      _content = FutureBuilder(
        future: Future(() async {
          Stopwatch stopwatch = new Stopwatch()..start();

          await _flutterFFmpeg.executeWithArguments(arguments);

          int output = await _flutterFFmpeg.getLastReturnCode();

          Duration time = stopwatch.elapsed;

          if (output != 0) {
            throw Exception(await _flutterFFmpeg.getLastCommandOutput());
          }

          return time.inSeconds;
        }),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          OutlineButton fechar = OutlineButton(
            child: Text("Fechar"),
            onPressed: () {
              Navigator.pop(context);
            },
          );

          if (snapshot.hasData) {
            return Column(
              children: <Widget>[
                Text("O tempo de compressão durou ${snapshot.data} segundos."),
                fechar,
              ],
            );
          } else if (snapshot.hasError) {
            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(snapshot.error.toString()),
                  fechar,
                ],
              ),
            );
          } else {
            return SizedBox(
              height: 70.0,
              width: 70.0,
              child: Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
    } catch (e) {
      _title = e.message;
      _actions = <Widget>[
        FlatButton(
          child: Text("Fechar"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ];
    } finally {
      AlertDialog alertDialog = AlertDialog(
        title: Text(_title),
        content: _content,
        actions: _actions,
      );

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => alertDialog,
      );
    }
  }
}
