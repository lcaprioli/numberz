import 'dart:async';
import 'dart:math';

//import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'board_consts.dart';
import 'models/tile_model.dart';

typedef StateFunction = void Function(List<Point> points);

class BoardController {
  BoardController(
    this.width,
    this.height,
//    {
//    required this.audioCache,
    //}
  );

  final int width;
  final int height;
  // final AudioCache? audioCache;

  final burnTime = ValueNotifier<int>(BoardConsts().timeGap);
  final totalTime = ValueNotifier<int>(BoardConsts().gameTime);
  final disabled = ValueNotifier<bool>(false);

  int bonusTime = 0;

  //AudioPlayer? fryPlayer;
  //AudioPlayer? blopPlayer;

  List<Set<int>> selectedTiles = [];
  List<Set<int>> expiringTiles = [];
  List<Set<int>> burnTiles = [];
  List<Point> selectedPoints = [];
  List<ValueNotifier<List<TileModel>>> columns = [];

  final score = ValueNotifier<int>(0);
  int level = 0;
  int round = 0;
  int lastSpawn = 0;
  bool isMuted = true;

  Future<void> setInitial() async {
    for (var i = 0; i < width; i++) {
      columns.add(ValueNotifier<List<TileModel>>([]));
      final _tmplist = [];
      for (var a = 0; a < (height * 2); a++) {
        _tmplist.add(
          TileModel(
            customKey: GlobalKey(debugLabel: '$i - $a'),
            number: _randNumber(),
            point: Point(i, a),
          ),
        );
      }
      columns[i].value = List.from(_tmplist);
    }

    selectedTiles = _newEmptyColumn();
    expiringTiles = _newEmptyColumn();
    burnTiles = _newEmptyColumn();
  }

  void reduceTimer() {
    if (bonusTime > 0) {
      bonusTime = bonusTime - 1;
    } else {
      if (burnTime.value < 1) {
        disabled.value = true;
      } else if (burnTime.value > BoardConsts().timeGap - 2) {
        disabled.value = false;
      }

      if (burnTime.value == 1) {
        decrease();
        burnTime.value = BoardConsts().timeGap;
        round++;
        if (round % BoardConsts().levelScale == 0) {
          level++;
        }
      } else {
        burnTime.value = burnTime.value - 1;
      }
      if (totalTime.value == 0) {
        totalTime.value = BoardConsts().gameTime;
      } else {
        totalTime.value = totalTime.value - 1;
      }
    }
  }

  int spawnReplacement() {
    if (combinationCount() < 3) {
      return lastSpawn;
    }
    lastSpawn = _randNumber();
    return lastSpawn;
  }

  int combinationCount() {
    int _matchCount = 0;
    for (var i = 0; i < width; i++) {
      for (var a = 0; a < height - 1; a++) {
        if (columns[i].value[a].number == columns[i].value[a + 1].number) {
          _matchCount++;
        }
      }
    }
    for (var i = 0; i < height; i++) {
      for (var a = 0; a < width - 1; a++) {
        if (columns[a].value[i].number == columns[a + 1].value[i].number) {
          _matchCount++;
        }
      }
    }

    return _matchCount;
  }

  void decrease() async {
    for (var i = 0; i < width; i++) {
      for (var a = 0; a < height; a++) {
        if (columns[i].value[a].number == 5) {
          expiringTiles[i].add(a);
          columns[i].value[a] = columns[i].value[a].burn();
          if (score.value >= 10) score.value = score.value - 10;
        }
      }
    }

    for (var i = 0; i < expiringTiles.length; i++) {
      if (expiringTiles[i].length > 0) {
        columns[i].value = List.from(columns[i].value);
      }
    }

    for (var i = 0; i < expiringTiles.length; i++) {
      if (expiringTiles[i].length > 0) {
        columns[i].value = List.from(columns[i].value);
      }
    }
    //if (!isMuted) fryPlayer = await audioCache?.play('fry.mp3');
    await Future.delayed(Duration(seconds: 1));

    for (var i = 0; i < width; i++) {
      for (var a = 0; a < height; a++) {
        if (columns[i].value[a].number < 5) {
          columns[i].value[a] =
              columns[i].value[a].setNumber(columns[i].value[a].number + 1);
        }
      }
    }
    removeSelected(expiringTiles);
    for (var i = 0; i < width; i++) {
      columns[i].value = List.from(columns[i].value);
    }
    expiringTiles = _newEmptyColumn();
  }

  void pointerDown(PointerMoveEvent event) async {
    for (var i = 0; i < width; i++) {
      for (var a = 0; a < columns[i].value.length; a++) {
        final box = columns[i]
            .value[a]
            .customKey
            .currentContext
            ?.findRenderObject() as RenderBox;
        final result = BoxHitTestResult();
        Offset localRed = box.globalToLocal(event.position);
        if (box.hitTest(result, position: localRed)) {
          var _columnLength = selectedTiles[i].length;
          selectedTiles[i].add(a);
          if (selectedTiles[i].length > _columnLength) {
            selectedPoints.add(Point(i, a));
          }
          columns[i].value[a] = columns[i].value[a].hit();
        }
      }
    }
    for (var i = 0; i < selectedTiles.length; i++) {
      if (selectedTiles[i].length > 0) {
        columns[i].value = List.from(columns[i].value);
      }
    }
  }

  void pointerUp(PointerUpEvent event) async {
    if (selectedPoints.length > 1) {
      var sequenceCount = 0;
      var match = true;

      for (var i = 0; i < selectedPoints.length - 1; i++) {
        var pos = selectedPoints[i];

        var num = columns[pos.column].value[pos.row].number;
        var pos2 = selectedPoints[i + 1];
        var next = columns[pos2.column].value[pos2.row].number;

        if (num == next + 1) {
          sequenceCount++;
        }
      }
      if (sequenceCount != selectedPoints.length - 1) {
        sequenceCount = 0;
        for (var i = 0; i < selectedPoints.length - 1; i++) {
          var pos = selectedPoints[i];
          var num = columns[pos.column].value[pos.row].number;
          var pos2 = selectedPoints[i + 1];
          var next = columns[pos2.column].value[pos2.row].number;

          if (num == next - 1) {
            sequenceCount++;
          }
        }
      }
      for (var i = 0; i < selectedPoints.length - 1; i++) {
        var pos = selectedPoints[i];
        var num = columns[pos.column].value[pos.row].number;
        var pos2 = selectedPoints[i + 1];
        var next = columns[pos2.column].value[pos2.row].number;

        if (num != next) {
          match = false;
        }
      }

      if (match || sequenceCount == selectedPoints.length - 1) {
        removeSelected(selectedTiles);
        //  if (!isMuted) blopPlayer = await audioCache?.play('blop.mp3');
      }

      if (match) {
        score.value += (BoardConsts().matchScore * selectedPoints.length);
      } else if (sequenceCount == BoardConsts().sequenceBonus) {
        score.value +=
            (BoardConsts().sequenceBonusScore * selectedPoints.length);
        bonusTime = BoardConsts().bonusGap;
      } else if (sequenceCount == selectedPoints.length - 1) {
        score.value += (BoardConsts().sequenceScore * selectedPoints.length);
      }
    }

    selectedPoints = [];
    selectedTiles = _newEmptyColumn();
    for (var a = 0; a < width; a++) {
      for (var x = 0; x < columns[a].value.length; x++) {
        columns[a].value[x] = columns[a].value[x].unHit();
      }
    }
    for (var i = 0; i < selectedTiles.length; i++) {
      columns[i].value = List.from(columns[i].value);
    }
  }

  void removeSelected(List<Set<int>> list) {
    for (var i = 0; i < list.length; i++) {
      final _deleteList = list[i].toList();
      _deleteList.sort((a, b) => b.compareTo(a));

      var _newList = columns[i].value;

      for (var a = 0; a < _deleteList.length; a++) {
        _newList.removeAt(_deleteList[a]);
        _newList.add(
          TileModel(
            customKey: GlobalKey(),
            number: spawnReplacement(),
            point: Point(
                i,
                columns[i]
                        .value
                        .where((element) => element.disposed == false)
                        .length -
                    1),
          ),
        );
      }
      columns[i].value = List.from(_newList);
    }
  }

  List<Set<int>> _newEmptyColumn() => List.generate(width, (index) => <int>{});
  int _randNumber() => Random().nextInt(5) + 1;
}
