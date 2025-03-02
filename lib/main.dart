import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
        fontFamily: 'poorStory', // 커스텀 폰트 적용
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
  final int gridSize = 4; // 4x4 격자 (총 16개 카드 = 8쌍)
  late List<MemoryCardData> cards;
  final List<int> flippedIndices = [];
  int secondsElapsed = 60;
  Timer? timer;
  bool isGameOver = false;
  bool gameStarted = false;

  // AudioPlayer 생성 (사운드 재생용)
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 게임 시작 및 재시작
  void startGame() async {
    timer?.cancel();
    setState(() {
      gameStarted = true;
      secondsElapsed = 60;
      isGameOver = false;
      flippedIndices.clear();
      cards = []; // 초기화
    });
    await initializeCards(); // 포켓몬 데이터를 비동기 호출로 가져옴
    startTimer();
  }

  // 타이머 시작
  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (!isGameOver) {
        setState(() {
          secondsElapsed--;
        });
        if (secondsElapsed == 0 && !cards.every((card) => card.isMatched)) {
          endGame(failed: true);
        }
      }
    });
  }

  // 게임 종료 처리
  void endGame({required bool failed}) {
    setState(() {
      isGameOver = true;
    });
    timer?.cancel();
    _audioPlayer.play(
      AssetSource(failed ? 'sounds/failure.mp3' : 'sounds/success.mp3'),
    );
  }

  // 포켓몬 8종 데이터를 PokeAPI에서 가져와 카드 리스트를 생성
  Future<void> initializeCards() async {
    final random = Random();
    // 예를 들어, 1~150 범위에서 8개의 서로 다른 포켓몬 ID 선택
    final Set<int> ids = {};
    while (ids.length < 8) {
      ids.add(random.nextInt(150) + 1);
    }
    List<MemoryCardData> fetchedCards = [];
    for (int id in ids) {
      final response = await http.get(Uri.parse("https://pokeapi.co/api/v2/pokemon/$id"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data["sprites"]["front_default"];
        final name = data["name"];
        if (imageUrl != null) {
          // 한 포켓몬당 두 장의 카드 생성
          fetchedCards.add(MemoryCardData(value: name, imageUrl: imageUrl));
          fetchedCards.add(MemoryCardData(value: name, imageUrl: imageUrl));
        }
      }
    }
    // 카드 순서 섞기
    fetchedCards.shuffle();
    setState(() {
      cards = fetchedCards;
    });
  }

  // 카드 탭 이벤트 처리
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
        _checkForMatch();
      });
    }
  }

  // 매칭 확인
  void _checkForMatch() {
    int firstIndex = flippedIndices[0];
    int secondIndex = flippedIndices[1];

    if (cards[firstIndex].value == cards[secondIndex].value) {
      setState(() {
        cards[firstIndex].isMatched = true;
        cards[secondIndex].isMatched = true;
      });
      _audioPlayer.play(AssetSource('sounds/match.mp3'));
    } else {
      setState(() {
        cards[firstIndex].isFlipped = false;
        cards[secondIndex].isFlipped = false;
      });
      _audioPlayer.play(AssetSource('sounds/mismatch.mp3'));
    }
    flippedIndices.clear();

    if (cards.every((card) => card.isMatched)) {
      endGame(failed: false);
    }
  }

  // 상태 메시지
  String get statusMessage {
    if (cards.isNotEmpty && cards.every((card) => card.isMatched)) {
      return secondsElapsed > 0 ? "축하합니다" : "시간 초과했습니다";
    } else if (secondsElapsed == 0) {
      return "시간 초과했습니다";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('포켓몬 기억력 게임'),
      ),
      body: gameStarted
          ? Column(
        children: [
          // 카드 그리드 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: cards.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : GridView.builder(
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemBuilder: (context, index) {
                  return MemoryCard(
                    key: ValueKey(
                        '${cards[index].value}-${cards[index].isFlipped}-${cards[index].isMatched}'),
                    value: cards[index].value,
                    imageUrl: cards[index].imageUrl,
                    isFlipped: cards[index].isFlipped,
                    isMatched: cards[index].isMatched,
                    onTap: () => onCardTap(index),
                  );
                },
              ),
            ),
          ),
          // "다시 시작하기" 버튼
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
          // 점수판 영역 (상태 메시지 및 남은 시간)
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
                    '남은 시간: ${secondsElapsed}s',
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

// 포켓몬 데이터를 포함한 카드 데이터 모델
class MemoryCardData {
  final String value; // 포켓몬 이름
  final String imageUrl; // 포켓몬 스프라이트 URL
  bool isFlipped;
  bool isMatched;
  MemoryCardData({
    required this.value,
    required this.imageUrl,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

// 카드 위젯 (애니메이션 포함)
// 카드가 뒤집혔을 때 포켓몬 이미지와 이름을 보여줍니다.
class MemoryCard extends StatefulWidget {
  final String value;
  final String imageUrl;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;

  MemoryCard({
    Key? key,
    required this.value,
    required this.imageUrl,
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
    // 카드가 뒤집혔을 때: 포켓몬 이미지와 이름 표시
    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              widget.imageUrl,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error, size: 60);
              },
            ),
            // SizedBox(height: 8),
            // Text(
            //   widget.value.toUpperCase(),
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    // 카드가 닫힌 상태: 뒤집힌 카드 디자인
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '',
          style: TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
