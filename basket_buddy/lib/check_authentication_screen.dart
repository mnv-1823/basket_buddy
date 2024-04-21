import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class CheckAuthenticationScreen extends StatelessWidget {
  const CheckAuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context,snapshot){
            if (snapshot.hasData){
              return const HomeScreen();
            }else{
              return const LoginScreen();
            }
          }
      ),
    );
  }
}
