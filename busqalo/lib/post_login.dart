import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExtraUserInfoPage extends StatefulWidget {
  final User user;
  const ExtraUserInfoPage({super.key, required this.user});

  @override
  State<ExtraUserInfoPage> createState() => _ExtraUserInfoPageState();
}

class _ExtraUserInfoPageState extends State<ExtraUserInfoPage> {
  final idController = TextEditingController();
  String? selectedCity;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 50),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Completa esta información adicional para continuar',
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Ciudad de residencia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Puerto Colombia', child: Text('Puerto Colombia')),
                  DropdownMenuItem(value: 'Barranquilla', child: Text('Barranquilla')),
                  DropdownMenuItem(value: 'Soledad', child: Text('Soledad')),
                ],
                onChanged: (val) => setState(() => selectedCity = val),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: TextEditingController(
                  text: selectedDate == null
                      ? ''
                      : '${selectedDate!.toLocal()}'.split(' ')[0],
                ),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 250,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_validateFields()) {
                      await saveExtraUserData(widget.user);
                      if (!mounted) return; // Verifica si el widget sigue montado
                        Navigator.pushReplacementNamed(context, '/home');
                      
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateFields() {
    if (selectedCity == null || selectedDate == null || idController.text.isEmpty) {
      _showErrorDialog('Por favor completa todos los campos.');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('OK'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> saveExtraUserData(User user) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  final displayName = user.displayName ?? '';
  final nameParts = displayName.split(' ');
  final nombre = nameParts.isNotEmpty ? nameParts.first : '';
  final apellido = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  await userDoc.set({
    'nombre': nombre,
    'apellido': apellido,
    'ciudad': selectedCity,
    'fechaNacimiento': selectedDate?.toIso8601String(),
    'cedula': idController.text,
    'email': user.email,
    'uid': user.uid,
    'photoURL': user.photoURL,
    'permisos':0,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}


  void _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime minDate = DateTime(today.year - 100, today.month, today.day);
    final DateTime maxDate = DateTime(today.year - 16, today.month, today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
    );

    if (picked != null && picked != selectedDate) {
      if (!mounted) return; 
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    idController.dispose();
    super.dispose();
  }
}
