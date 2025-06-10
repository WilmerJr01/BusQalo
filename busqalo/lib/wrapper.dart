import 'package:busqalo/admin/ruta_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home/home_page.dart';

import 'login/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          // No está logueado → mostrar login
          return const LoginPage();
        }

        // Usuario logueado → obtener permisos desde Firestore con StreamBuilder
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Si no hay datos de usuario, mostramos HomePage normal (o alguna pantalla de error)
              return const HomePage();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>?;

            final permiso = data?['permisos'] ?? 0;

            if (permiso == 1) {
              return const RutaAdminPage();
            } else {
              return const HomePage();
            }
          },
        );
      },
    );
  }
}
