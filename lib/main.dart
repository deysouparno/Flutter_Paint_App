import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

import 'package:flutter_paint_app/cubit/slider_cubit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SliderCubit>(create: (context) => SliderCubit())
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        darkTheme: ThemeData.dark(),
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var strokeWidth = 5.0;
  List<Stroke> strokes = [];
  Color selectedColor = Colors.white;
  Color backgroungColor = Colors.grey;
  ScreenshotController controller = ScreenshotController();

  void selectColor() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Choose color"),
            content: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
                Navigator.of(context).pop();
              },
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Paint App"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.image),
            tooltip: "Saved Images",
          )
        ],
      ),
      drawer: Drawer(
        elevation: 5.0,
        child: Column(
          children: [
            DrawerHeader(child: Icon(Icons.brush)),
            Text("Saved Images")
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              height: 60,
              color: Colors.teal,
              child: Row(
                children: [
                  IconButton(
                      tooltip: "Background Color",
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Choose color"),
                                content: BlockPicker(
                                  pickerColor: backgroungColor,
                                  onColorChanged: (color) {
                                    setState(() {
                                      backgroungColor = color;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            });
                      },
                      icon: Icon(
                        Icons.color_lens,
                        color: backgroungColor,
                      )),
                  IconButton(
                      tooltip: "Reverse",
                      onPressed: () {
                        setState(() {
                          strokes.removeLast();
                        });
                      },
                      icon: Icon(Icons.undo)),
                  IconButton(
                      tooltip: "Save Image",
                      onPressed: () async {
                        final img = await controller.capture();
                        await saveImage(img);
                      },
                      icon: Icon(Icons.save)),
                  IconButton(
                      tooltip: "Brush Color",
                      onPressed: () {
                        selectColor();
                      },
                      icon: Icon(
                        Icons.brush,
                        color: selectedColor,
                      )),
                  Expanded(
                    child: BlocBuilder<SliderCubit, SliderCubitState>(
                      builder: (context, state) {
                        return Slider(
                            activeColor: selectedColor,
                            value: state.strokeWidth,
                            max: 20,
                            min: 0,
                            onChanged: (val) {
                              strokeWidth = val;
                              BlocProvider.of<SliderCubit>(context)
                                  .emitSliderValue(val);
                            });
                      },
                    ),
                  ),
                  IconButton(
                      tooltip: "Clear Canvas",
                      onPressed: () {
                        setState(() {
                          strokes.clear();
                        });
                      },
                      icon: Icon(Icons.layers_clear)),
                ],
              )),
          Expanded(
              child: Screenshot(
            controller: controller,
            child: GestureDetector(
              onPanDown: (details) {
                print("pandown called");
                setState(() {
                  strokes.add(Stroke(
                      brush: Paint()
                        ..strokeCap = StrokeCap.round
                        ..isAntiAlias = true
                        ..color = selectedColor
                        ..strokeWidth = strokeWidth));
                  strokes.last.offsets.add(details.localPosition);
                });
              },
              onPanUpdate: (details) {
                print("pan update called");
                setState(() {
                  strokes.last.offsets.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                print("pan end called");
                // setState(() {
                //   strokes.add(null);
                // });
              },
              child: ClipRRect(
                child: CustomPaint(
                  painter: MyCustomPainer(
                      points: strokes, backgroundColor: backgroungColor),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 60,
                  ),
                ),
              ),
            ),
          ))
        ],
      ),
    );
  }
}

class MyCustomPainer extends CustomPainter {
  List<Stroke> points;
  Color backgroundColor;

  MyCustomPainer({
    required this.points,
    required this.backgroundColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = this.backgroundColor;
    Rect rect = Rect.fromLTRB(size.width, size.height, 0, 0);
    canvas.drawRect(rect, background);

    points.forEach((element) {
      if (element.offsets.length == 1) {
        canvas.drawPoints(PointMode.points, element.offsets, element.brush);
      } else {
        for (int i = 0; i < element.offsets.length - 1; i++) {
          canvas.drawLine(
              element.offsets[i], element.offsets[i + 1], element.brush);
        }
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Stroke {
  late List<Offset> offsets;
  Paint brush;

  Stroke({
    required this.brush,
  }) {
    this.offsets = [];
  }
}

Future<String> saveImage(Uint8List? bytes) async {
  if (bytes == null) {
    return "Something wrong";
  }
  await Permission.storage.request();
  final time = DateTime.now()
      .toIso8601String()
      .replaceAll(".", "_")
      .replaceAll(":", "_");
  final result =
      await ImageGallerySaver.saveImage(bytes, name: "screenShot$time");
  return result['filePath'];
}
