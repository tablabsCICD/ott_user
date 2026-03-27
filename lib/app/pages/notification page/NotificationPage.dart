import 'package:flutter/material.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedNotifications = prefs.getStringList('notifications');

    if (savedNotifications != null && savedNotifications.isNotEmpty) {
      setState(() {
        notifications = savedNotifications.map((notif) {
          return {
            "message": notif,
            "time": DateTime.now().toLocal().toString(),
            "isRead": false, // Initially unread
            "movieId": 1 // Dummy movie ID, change as needed
          };
        }).toList();
      });
    } else {
      // Dummy notifications if there are none in storage
      setState(() {
        notifications = [];
      });
    }
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    setState(() {
      notifications.clear();
    });
  }

  void _markAsReadAndNavigate(int index) {
    setState(() {
      notifications[index]["isRead"] = true;
    });

    // Navigate to movie detail page (Assuming you have a MovieDetailsPage)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MovieDetailsPage(movieId: notifications[index]["movieId"]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    final lang = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: selectedThemeData.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          lang.notification,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _clearNotifications,
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No Notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                bool isRead = notifications[index]["isRead"];

                return GestureDetector(
                  onTap: () => _markAsReadAndNavigate(index),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    color: isRead
                        ? selectedThemeData.cardColor.withOpacity(0.6)
                        : selectedThemeData.cardColor,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead
                            ? selectedThemeData.primaryColor.withOpacity(0.5)
                            : selectedThemeData.primaryColor,
                        backgroundImage:
                            NetworkImage(notifications[index]["posterURL"]),
                      ),
                      title: Text(
                        notifications[index]["message"],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isRead
                              ? selectedThemeData.canvasColor.withOpacity(0.4)
                              : selectedThemeData.canvasColor,
                        ),
                      ),
                      subtitle: Text(
                        notifications[index]["time"],
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
