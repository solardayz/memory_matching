import 'package:flutter/material.dart';
import 'dart:math';

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
  int score = 0;

  @override
  void initState() {
    super.initState();
    initializeCards();
  }

  // 8쌍의 카드(총 16개)를 생성 후 무작위로 섞습니다.
  void initializeCards() {
    List<String> values = ['🐶', '🐱', '🐰', '🦊', '🐼', '🐨', '🐯', '🦁'];
    List<String> allValues = [...values, ...values];
    allValues.shuffle();
    cards = allValues.map((value) => MemoryCardData(value: value)).toList();
  }

  // 카드 탭 시 처리 (이미 뒤집혔거나 매칭된 카드면 무시)
  void onCardTap(int index) {
    if (cards[index].isFlipped || cards[index].isMatched) return;

    setState(() {
      cards[index].isFlipped = true;
      flippedIndices.add(index);
    });

    // 두 장 뒤집혔을 때 매칭 여부 확인
    if (flippedIndices.length == 2) {
      Future.delayed(Duration(milliseconds: 500), () {
        int firstIndex = flippedIndices[0];
        int secondIndex = flippedIndices[1];
        if (cards[firstIndex].value == cards[secondIndex].value) {
          setState(() {
            cards[firstIndex].isMatched = true;
            cards[secondIndex].isMatched = true;
            score += 10;
          });
        } else {
          setState(() {
            cards[firstIndex].isFlipped = false;
            cards[secondIndex].isFlipped = false;
          });
        }
        flippedIndices.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Matching Game'),
      ),
      body: Padding(
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
            // key에 상태값을 포함시켜 재빌드 유도
            return MemoryCard(
              key: ValueKey('${card.value}-${card.isFlipped}-${card.isMatched}'),
              value: card.value,
              isFlipped: card.isFlipped,
              isMatched: card.isMatched,
              onTap: () => onCardTap(index),
            );
          },
        ),
      ),
      // 하단 전광판 스타일의 점수판
      bottomNavigationBar: Container(
        height: 80,
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
          child: Text(
            'Score: $score',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
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

// 카드 위젯 (개별 애니메이션 포함)
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
  void initState(){
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: pi).animate(_controller);
    // 초기 상태에 따른 애니메이션 진행
    if (widget.isFlipped) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // isFlipped 값이 변경되면 애니메이션을 실행합니다.
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
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

  // 앞면 (카드가 뒤집혀서 보일 때)
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

  // 뒷면 (초기 상태)
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
