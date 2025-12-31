import 'package:flutter/material.dart';
import 'package:local_app_tt/widgets/bottom_tab_nav.dart';
import 'package:local_app_tt/widgets/responsive_button.dart';

class ExternalServices extends StatelessWidget {
  final List<String> services = [
    'Find File',
    'Scan File',
    'Forms',
    'Report an Issue',
    'Software Bugs',
  ];

  ExternalServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Internal Services'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: FlutterLogo(size: 80)),
            // Add any drawer items here
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation or action based on index
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,          
          children: [
            Text(
              'External Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...services.map((service) => Container(
              width: double.maxFinite,
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ResponsiveButton(
                label: (service.toUpperCase()),
                onPressed: () {
                  // Add specific navigation logic here
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}