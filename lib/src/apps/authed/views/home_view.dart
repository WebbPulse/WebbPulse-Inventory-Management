import 'package:flutter/material.dart';
import '../../../shared/widgets.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: AuthedDrawer(),
      body: ListView(
        children: <Widget>[
          Image.asset('assets/saber.gif'),
          const SizedBox(height: 8),
          const Column(
            children: [
              Header("I am a god!"),
              Paragraph(
                'I am the one who will destroy the world!',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
