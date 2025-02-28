import 'package:flutter/material.dart';

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
            return Card(
              elevation: 4,
              color: Colors.lightBlueAccent,
              child: InkWell(
                onTap: () {
                  // 추후 카드 뒤집기 기능 추가 예정
                },
                child: Center(
                  child: Text(
                    '', // 추후 카드 이미지 또는 텍스트 삽입
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
