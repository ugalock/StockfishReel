import 'package:flutter/material.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../feed/main_feed_screen.dart';
import '../video/create_video_screen.dart';
// Import other screens as needed

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const MainFeedScreen(),
    const Scaffold(body: Center(child: Text('Discover'))), // TODO: Implement DiscoverScreen
    const CreateVideoScreen(),
    const Scaffold(body: Center(child: Text('Inbox'))), // TODO: Implement InboxScreen
    const Scaffold(body: Center(child: Text('Profile'))), // TODO: Implement ProfileScreen
  ];

  void _onNavBarTap(int index) {
    if (index == 2) {
      // Show CreateVideoScreen as a modal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateVideoScreen(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
