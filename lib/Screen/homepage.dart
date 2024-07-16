import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:securify/Screen/details.dart';
import 'package:securify/Screen/profilepage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  User? user;
  bool isloading = false;
  late DatabaseReference _databaseReference;
  List<dynamic> _entries = [];
  String? _coderegistration;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _databaseReference = FirebaseDatabase.instance.ref();
    _getCoderegistration();

    setupNotificationListeners();
  }

  Future<void> _getCoderegistration() async {
    if (user != null) {
      DatabaseReference userRef =
          _databaseReference.child('Users').child(user!.uid);

      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _coderegistration = userData['coderegistration'];
        });
        if (_coderegistration != null) {
          await getDataFromFirebase();
          setupNotificationListeners();
        }
      }
    }
  }

  void setupNotificationListeners() {
    if (_coderegistration == null) return;

    _databaseReference.child(_coderegistration!).onChildAdded.listen(
      (event) {
        if (event.snapshot.value != null) {
          _showLocalNotification(event.snapshot.value as Map);
          getDataFromFirebase(); // Refresh data ketika terdapat data baru
        }
      },
    );
    _databaseReference.child(_coderegistration!).onChildRemoved.listen(
      (event) {
        getDataFromFirebase(); // Refresh data ketika data dihapus
      },
    );
  }

  void _showLocalNotification(Map<dynamic, dynamic> notification) async {
    String message = notification['keterangan'] ?? 'No message';
    String waktu = notification['waktu'] ?? 'No time';
    String tanggal = notification['Tanggal'] ?? 'No date';

    List<String> waktuKomponen = waktu.split(':');
    String time = '${waktuKomponen[0]}:${waktuKomponen[1]}';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'Securify',
      'High Priority Notifications',
      channelDescription: 'High and Priority Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message,
      '$tanggal - $time',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> signout() async {
    setState(() {
      isloading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error Msg", e.code);
    } catch (e) {
      Get.snackbar("Error Msg", e.toString());
    }
    setState(() {
      isloading = false;
    });
  }

  Future<void> getDataFromFirebase() async {
    if (_coderegistration == null) return;

    DataSnapshot snapshot =
        await _databaseReference.child(_coderegistration!).get();
    if (snapshot.value != null) {
      Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<dynamic, dynamic>> entries = data.entries
            .map((entry) =>
                {'key': entry.key, ...Map<dynamic, dynamic>.from(entry.value)})
            .toList();
        entries.sort((a, b) {
          DateTime dateTimeA = DateTime.parse(
              '${a['Tanggal'].substring(6, 10)}-${a['Tanggal'].substring(3, 5)}-${a['Tanggal'].substring(0, 2)} ${a['waktu']}');
          DateTime dateTimeB = DateTime.parse(
              '${b['Tanggal'].substring(6, 10)}-${b['Tanggal'].substring(3, 5)}-${b['Tanggal'].substring(0, 2)} ${b['waktu']}');

          return dateTimeB.compareTo(dateTimeA);
        });

        setState(() {
          _entries = entries;
        });
      }
    } else {
      setState(() {
        _entries = [];
      });
    }
  }

  Uint8List decodeImage(String base64String) {
    return base64Decode(base64String);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = <Widget>[
      _buildHomePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F94FC),
        title: const Text(
          "",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
        ),
        toolbarHeight: 50,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6F94FC),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomePage() {
    return isloading
        ? const Center(
            child: CircularProgressIndicator.adaptive(),
          )
        : RefreshIndicator(
            onRefresh: getDataFromFirebase,
            child: _entries.isEmpty
                ? Center(
                    child: SvgPicture.asset(
                      'assets/images/No_data.svg',
                      width: 400,
                      height: 400,
                    ),
                  )
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPage(entry: _entries[index]),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: _entries[index]['img'] != null
                                        ? DecorationImage(
                                            image: MemoryImage(decodeImage(
                                                _entries[index]['img']!)),
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage(
                                            image: AssetImage(
                                                'assets/images/No_image.png'),
                                            fit: BoxFit.cover)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _entries[index]['keterangan'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Waktu: ${_entries[index]['Tanggal'] ?? '-'}  ${_entries[index]['waktu'] ?? '-'}",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }
}
