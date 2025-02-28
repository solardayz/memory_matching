import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MemoryMatchingGameApp());
}

class MemoryMatchingGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Matching Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MemoryGameScreen(),
    );
  }
}

class MemoryGameScreen extends StatefulWidget {
  @override
  _MemoryGameScreenState createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final int gridSize = 4; // 4x4 격자
  late List<MemoryCardData> cards;
  List<int> flippedIndices = [];
  int secondsElapsed = 0;
  Timer? timer;
  bool isGameOver = false;
  bool gameStarted = false;

  // audioplayers 6.2.0의 AudioPlayer 생성
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 게임 시작 및 재시작: 상태 초기화, 카드 초기화, 타이머 시작
  void startGame() {
    timer?.cancel();
    setState(() {
      gameStarted = true;
      secondsElapsed = 0;
      isGameOver = false;
      flippedIndices.clear();
      initializeCards();
    });

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (!isGameOver) {
        setState(() {
          secondsElapsed++;
        });
        // 60초가 넘었는데 모든 카드가 매칭되지 않았으면 게임 종료 및 실패 사운드 재생
        if (secondsElapsed >= 60 && !cards.every((card) => card.isMatched)) {
          setState(() {
            isGameOver = true;
          });
          timer?.cancel();
          _audioPlayer.play(AssetSource('sounds/failure.mp3'));
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 8쌍의 카드(총 16개)를 생성 후 무작위로 섞음
  void initializeCards() {
    List<String> values = ['🐶', '🐱', '🐰', '🦊', '🐼', '🐨', '🐯', '🦁'];
    List<String> allValues = [...values, ...values];
    allValues.shuffle();
    cards = allValues.map((value) => MemoryCardData(value: value)).toList();
  }

  // 카드 탭 처리 (게임 종료 상태이거나 이미 뒤집혔거나 매칭된 카드면 무시)
  void onCardTap(int index) {
    if (isGameOver ||
        cards[index].isFlipped ||
        cards[index].isMatched ||
        flippedIndices.length == 2) return;

    setState(() {
      cards[index].isFlipped = true;
      flippedIndices.add(index);
    });

    if (flippedIndices.length == 2) {
      Future.delayed(Duration(milliseconds: 500), () {
        int firstIndex = flippedIndices[0];
        int secondIndex = flippedIndices[1];

        if (cards[firstIndex].value == cards[secondIndex].value) {
          setState(() {
            cards[firstIndex].isMatched = true;
            cards[secondIndex].isMatched = true;
          });
          // 매칭 성공 사운드 재생
          _audioPlayer.play(AssetSource('sounds/match.mp3'));
        } else {
          setState(() {
            cards[firstIndex].isFlipped = false;
            cards[secondIndex].isFlipped = false;
          });
          // 매칭 실패(미스매칭) 사운드 재생
          _audioPlayer.play(AssetSource('sounds/mismatch.mp3'));
        }
        flippedIndices.clear();

        // 모든 카드가 매칭되면 게임 종료 및 성공/실패 사운드 재생
        if (cards.every((card) => card.isMatched)) {
          setState(() {
            isGameOver = true;
          });
          timer?.cancel();
          if (secondsElapsed <= 60) {
            _audioPlayer.play(AssetSource('sounds/success.mp3'));
          } else {
            _audioPlayer.play(AssetSource('sounds/failure.mp3'));
          }
        }
      });
    }
  }

  // 게임 종료 후 상태 메시지 (60초 이내 완성 시 "축하합니다", 아니면 "시간 초과했습니다")
  String get statusMessage {
    if (cards.every((card) => card.isMatched)) {
      return secondsElapsed <= 60 ? "축하합니다" : "시간 초과했습니다";
    } else if (secondsElapsed >= 60) {
      return "시간 초과했습니다";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Matching Game'),
      ),
      body: gameStarted
          ? Column(
        children: [
          // 그리드 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemBuilder: (context, index) {
                  MemoryCardData card = cards[index];
                  return MemoryCard(
                    key: ValueKey(
                        '${card.value}-${card.isFlipped}-${card.isMatched}'),
                    value: card.value,
                    isFlipped: card.isFlipped,
                    isMatched: card.isMatched,
                    onTap: () => onCardTap(index),
                  );
                },
              ),
            ),
          ),
          // "다시 시작하기" 버튼 (그리드와 점수판 사이)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: startGame,
              child: Text(
                '다시 시작하기',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          // 점수판 영역 (상태 메시지 및 경과 시간)
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent, Colors.orangeAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (statusMessage.isNotEmpty)
                    Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    'Time: ${secondsElapsed}s',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : Center(
        child: ElevatedButton(
          onPressed: startGame,
          child: Text(
            '시작하기',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

// 각 카드의 데이터 모델
class MemoryCardData {
  final String value;
  bool isFlipped;
  bool isMatched;
  MemoryCardData({
    required this.value,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

// 카드 위젯 (애니메이션 포함)
class MemoryCard extends StatefulWidget {
  final String value;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;

  MemoryCard({
    Key? key,
    required this.value,
    required this.isFlipped,
    required this.isMatched,
    required this.onTap,
  }) : super(key: key);

  @override
  _MemoryCardState createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: pi).animate(_controller);
    if (widget.isFlipped) {
      _controller.forward();
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          double angle = _animation.value;
          bool showFront = angle >= (pi / 2);
          return Transform(
            transform: Matrix4.identity()..rotateY(angle),
            alignment: Alignment.center,
            child: showFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.value,
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(''),
      ),
    );
  }
}
