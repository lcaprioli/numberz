import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class Tile {
  Tile({
    required this.key,
    required this.number,
    this.hasHit = false,
    this.disposed = false,
  });

  final GlobalKey key;
  final int number;
  final bool hasHit;
  final bool disposed;

  Tile hit() {
    return Tile(
      key: key,
      number: number,
      hasHit: true,
      disposed: disposed,
    );
  }

  Tile setNumber(int newNumber) {
    return Tile(
      key: key,
      number: newNumber,
      hasHit: hasHit,
      disposed: disposed,
    );
  }

  Tile unHit() {
    return Tile(
      key: key,
      number: number,
      hasHit: false,
      disposed: disposed,
    );
  }

  Tile dispose() {
    return Tile(
      key: key,
      number: number,
      hasHit: hasHit,
      disposed: true,
    );
  }

  Tile unDispose() {
    return Tile(
      key: key,
      number: number,
      hasHit: hasHit,
      disposed: false,
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
  static const _width = 5;
  static const _height = 7;
  List<Tile> _tiles = [];
  Set<int> _selectedTiles = {};
  int _lastSpawn = Random().nextInt(6);
  int _score = 0;
  Timer? _refresh;

  @override
  void initState() {
    _tiles = List.generate(
      _width * _height,
      (index) => Tile(
        key: GlobalKey(),
        number: Random().nextInt(6),
      ),
    );
    setInitial();
    _refresh = Timer.periodic(Duration(milliseconds: 150), moveDown);
    super.initState();
  }

  void setInitial() {
    for (var i = 0; i < _width * _height; i++) {
      _tiles[i] = _tiles[i].setNumber(_spawnReplacement());
    }
  }

  void moveDown(Timer t) {
    setState(() {
      for (var i = 0; i < _width * _height; i++) {
        if (i > _width - 1) {
          if (_tiles[i].disposed) {
            _tiles[i] = _tiles[i].setNumber(_tiles[i - _width].number);
            _tiles[i] = _tiles[i].unDispose();
            _tiles[i - _width] = _tiles[i - _width].dispose();
            /*     _tiles[i] = _tiles[i - _width];
            _tiles[i - _width] = _tiles[i - _width].dispose(); */
          }
        } else {
          if (_tiles[i].disposed) {
            _tiles[i] = _tiles[i].setNumber(_spawnReplacement());
            _tiles[i] = _tiles[i].unDispose();
            /*  _tiles[i] = Tile(key: GlobalKey(), number: Random().nextInt(6)); */
          }
        }
      }
    });
  }

  int _spawnReplacement() {
    if (_combinationCount() < 3) {
      return _lastSpawn;
    }
    _lastSpawn = Random().nextInt(6);
    return _lastSpawn;
  }

  int _combinationCount() {
    int _matchCount = 0;
    for (var i = 0; i < _width; i++) {
      for (var a = 0; a < _height - 1; a++) {
        if (_tiles[(i * _width) + a].number == _tiles[((i + 1) * _width) + a].number) {
          _matchCount++;
        }
      }
    }
    for (var i = 0; i < _height; i++) {
      for (var a = 0; a < _width - 2; a++) {
        if (_tiles[(i * _width) + a].number == _tiles[((i * _width) + a) + 1].number) {
          _matchCount++;
        }
      }
    }

    return _matchCount;
  }

  @override
  Widget build(BuildContext context) {
    print(_combinationCount());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Listener(
        onPointerMove: (a) {
          for (var i = 0; i < _width * _height; i++) {
            final box = _tiles[i].key.currentContext?.findRenderObject() as RenderBox;
            final result = BoxHitTestResult();
            Offset localRed = box.globalToLocal(a.position);
            if (box.hitTest(result, position: localRed)) {
              _tiles[i] = _tiles[i].hit();
              _selectedTiles.add(i);
            }
          }
        },
        onPointerUp: (a) {
          var sequence = true;
          var sequenceInverse = true;
          var match = true;
          for (var i = 0; i < _selectedTiles.length - 1; i++) {
            var num = _tiles[_selectedTiles.elementAt(i)].number;
            var next = _tiles[_selectedTiles.elementAt(i + 1)].number;

            if (num != next + 1) {
              sequence = false;
            }
          }
          for (var i = 0; i < _selectedTiles.length - 1; i++) {
            var num = _tiles[_selectedTiles.elementAt(i)].number;
            var next = _tiles[_selectedTiles.elementAt(i + 1)].number;

            if (num != next - 1) {
              sequenceInverse = false;
            }
          }
          if (!sequence && !sequenceInverse) {
            for (var i = 0; i < _selectedTiles.length - 1; i++) {
              var num = _tiles[_selectedTiles.elementAt(i)].number;
              var next = _tiles[_selectedTiles.elementAt(i + 1)].number;

              if (num != next) {
                match = false;
              }
            }
          } else {
            match = false;
          }

          if (match || sequence || sequenceInverse) {
            for (var i = 0; i < _selectedTiles.length; i++) {
              _tiles[_selectedTiles.elementAt(i)] = _tiles[_selectedTiles.elementAt(i)].dispose();
            }
          }
          _selectedTiles = {};
          /*  if ((num + 1) == next) {
              match = true;
              sequence = true;
              if (sequence) print('sequencia');
            } else if (_tiles[i].number == _tiles[i + 1].number && !sequence) {
              match = true;
            }
            if (match) _tiles[i] = _tiles[i].dispose(); */ /*  if ((num + 1) == next) {
              match = true;
              sequence = true;
              if (sequence) print('sequencia');
            } else if (_tiles[i].number == _tiles[i + 1].number && !sequence) {
              match = true;
            }
            if (match) _tiles[i] = _tiles[i].dispose(); */
          /* 
          _selectedTiles.sort((a, b) => a.number.compareTo(b.number));
          for (var i = 0; i < _selectedTiles.length - 1; i++) {
            if (!match) _tiles[i] = _tiles[i].unHit();
          }
          for (var i = 0; i < _width * _height; i++) {
            if (_tiles[i].hasHit) _tiles[i] = _tiles[i].dispose();
          } */
          for (var i = 0; i < _width * _height; i++) {
            _tiles[i] = _tiles[i].unHit();
          }
        },
        child: Container(
          width: 400,
          height: 750,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: _width,
            children: List.generate(_width * _height, (index) {
              return AnimatedContainer(
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _tiles[index].hasHit
                      ? Colors.pink
                      : Colors.black.withOpacity(_tiles[index].number / 30),
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(color: Colors.grey),
                ),
                key: _tiles[index].key,
                duration: Duration(milliseconds: 250),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      '${_tiles[index].disposed ? '' : _tiles[index].number}',
                      style:
                          Theme.of(context).textTheme.bodyText2?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}