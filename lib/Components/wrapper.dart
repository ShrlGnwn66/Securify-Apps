import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:securify/Screen/homepage.dart';
import 'package:securify/Screen/login.dart';
import 'package:securify/Screen/verify_email.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.emailVerified) {
                return const Homepage();
              } else {
                return const Verify();
              }
            } else {
              return const Login();
            }
          }),
    );
  }
}
