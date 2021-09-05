import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  List<PaintBrush?> points = [];
  Color selectedColor = Colors.white;
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
                      onPressed: () {
                        setState(() {});
                      },
                      icon: Icon(Icons.undo)),
                  IconButton(
                      onPressed: () async {
                        final img = await controller.capture();
                      },
                      icon: Icon(Icons.save)),
                  IconButton(
                      onPressed: () {
                        selectColor();
                      },
                      icon: Icon(
                        Icons.brush,
                        color: selectedColor,
                      )),
                  Expanded(
                    child: Slider(
                        activeColor: selectedColor,
                        value: strokeWidth,
                        max: 20,
                        min: 0,
                        onChanged: (val) {
                          setState(() {
                            strokeWidth = val;
                          });
                        }),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          points.clear();
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
                  points.add(PaintBrush(
                      offset: details.localPosition,
                      area: Paint()
                        ..strokeCap = StrokeCap.round
                        ..isAntiAlias = true
                        ..color = selectedColor
                        ..strokeWidth = strokeWidth));
                });
              },
              onPanUpdate: (details) {
                print("pan update called");
                setState(() {
                  points.add(PaintBrush(
                      offset: details.localPosition,
                      area: Paint()
                        ..strokeCap = StrokeCap.round
                        ..isAntiAlias = true
                        ..color = selectedColor
                        ..strokeWidth = strokeWidth));
                });
              },
              onPanEnd: (details) {
                print("pan end called");
                setState(() {
                  points.add(null);
                });
              },
              child: CustomPaint(
                painter: MyCustomPainer(points: points),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 60,
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
  List<PaintBrush?> points;

  MyCustomPainer({required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.grey;
    Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);

    for (int i = 0; i < points.length - 1; i++) {
      if (shouldPaintLine(i)) {
        canvas.drawLine(
            points[i]!.offset, points[i + 1]!.offset, points[i]!.area);
      } else if (shouldPaintPoint(i)) {
        canvas.drawPoints(
            PointMode.points, [points[i]!.offset], points[i]!.area);
      }
    }
  }

  bool shouldPaintLine(int i) => points[i] != null && points[i + 1] != null;
  bool shouldPaintPoint(int i) => points[i] != null && points[i + 1] == null;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PaintBrush {
  Offset offset;
  Paint area;

  PaintBrush({
    required this.offset,
    required this.area,
  });
}
