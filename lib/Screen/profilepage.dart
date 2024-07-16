import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<dynamic, dynamic>> getUserData(String uid) async {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child('Users').child(uid);
    DataSnapshot snapshot = await userRef.get();

    if (snapshot.exists) {
      return snapshot.value as Map<dynamic, dynamic>;
    } else {
      throw Exception("User not found");
    }
  }

  void signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      // ignore: avoid_print
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No user is logged in"));
    }

    return FutureBuilder<Map<dynamic, dynamic>>(
      future: getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("User profile not found"));
        }

        var userData = snapshot.data!;

        int createdAtEpoch = userData['created_at'];
        DateTime createdAt =
            DateTime.fromMillisecondsSinceEpoch(createdAtEpoch);
        String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6F94FC),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(90),
                      bottomRight: Radius.circular(90),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userData['username'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    children: [
                      ProfileInfoCard(
                        icon: Icons.email,
                        label: 'Email',
                        value: userData['email'],
                      ),
                      ProfileInfoCard(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: userData['phone'],
                      ),
                      ProfileInfoCard(
                        icon: Icons.home,
                        label: 'Code Registration',
                        value: userData['coderegistration'],
                      ),
                      ProfileInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Joined',
                        value: formattedDate,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          signOut(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F94FC),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'SIGN OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6F94FC)),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
