import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:datazen/pages/sp_home.dart';
import 'package:flutter/material.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    HomePage(),
    Scaffold(),
    Scaffold(),
    Scaffold(),
    Scaffold(),
    Scaffold(),
    // WatchListPage(),

    //RecommendationPage(),
    //TechnicalAnalysisPage(),
    //FinanceAdvisorChat()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).focusColor,
              width: 1,
            ),
          ),
        ),
        child: ConvexAppBar(
          style: TabStyle.react,
          items: const [
            //TabItem(icon: Icons.list, title: 'Watchlist'),
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(
              icon: Icons.record_voice_over_outlined,
              title: 'Recommend',
            ),
            TabItem(icon: Icons.analytics, title: 'Analyze'),
            TabItem(icon: Icons.chat, title: 'Chat Help'),
          ],
          initialActiveIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Theme.of(context).canvasColor,
          activeColor: Theme.of(context).focusColor,
          shadowColor: Theme.of(context).focusColor,
          color: Colors.white,
        ),
      ),
    );
  }
}
