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

class MemoryGameScreen extends StatelessWidget {
  final int gridSize = 4; // 4x4 격자

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Matching Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            // 각 카드에 flip 애니메이션 적용
            return MemoryCard(
              frontText: '😀', // 앞면에 표시할 내용 (예: 이미지, 텍스트)
              backText: '',    // 뒷면 (기본 디자인용)
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '메모리 게임',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MemoryCard extends StatefulWidget {
  final String frontText;
  final String backText;

  MemoryCard({required this.frontText, required this.backText});

  @override
  _MemoryCardState createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> with SingleTickerProviderStateMixin {
  bool isFrontVisible = false; // 초기에는 뒷면 표시
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 400ms 동안 카드가 뒤집히도록 애니메이션 컨트롤러 설정
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 카드 탭 시 flip 애니메이션 실행
  void flipCard() {
    if (isFrontVisible) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    isFrontVisible = !isFrontVisible;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // 애니메이션 값에 따라 0 ~ pi 라디안까지 회전
          double angle = _animation.value * pi;
          // 0.5를 기준으로 앞면/뒷면을 교체
          bool showFront = _animation.value >= 0.5;
          return Transform(
            transform: Matrix4.identity()..rotateY(angle),
            alignment: Alignment.center,
            child: showFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  // 앞면 (뒤집힌 후 보이는 면)
  Widget _buildFront() {
    return Transform(
      // 앞면은 뒤집힌 상태로 보이게 하기 위해 추가 회전
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.frontText,
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
        child: Text(
          widget.backText,
          style: TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}
