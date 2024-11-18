import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.0,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.send_sharp),
            label: 'Enviar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.access_time_rounded),
            label: 'Em Espera',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.share_location_rounded),
            label: 'Localizar',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: _logout,
              child: Icon(Icons.logout),
            ),
            label: 'Logout',
          ),
        ],
        currentIndex: widget.currentIndex,
        selectedItemColor: Color(0xFFFF7E26),
        unselectedItemColor: Colors.grey,
        onTap: widget.onTap,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
