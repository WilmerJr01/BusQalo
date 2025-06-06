import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroDeActividad {
  static Future<void> registrarActividad(String actividad) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final actividadRef = FirebaseFirestore.instance
          .collection('actividad')
          .doc(user.uid);

      final now = DateTime.now(); // Usamos timestamp local

      await actividadRef.set({
        'actividades': FieldValue.arrayUnion([
          {
            'accion': actividad,
            'timestamp': now,
            'email': user.email,
          },
        ]),
      }, SetOptions(merge: true));
    }
  }

  
}
