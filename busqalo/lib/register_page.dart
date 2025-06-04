import 'package:busqalo/post_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedCity;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Image.asset('assets/logo.png', height: 50)],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrate',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField(nameController, 'Nombre')),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildTextField(lastNameController, 'Apellido'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Ciudad de residencia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                value: selectedCity,
                items: const [
                  DropdownMenuItem(
                    value: 'Puerto Colombia',
                    child: Text('Puerto Colombia'),
                  ),
                  DropdownMenuItem(
                    value: 'Barranquilla',
                    child: Text('Barranquilla'),
                  ),
                  DropdownMenuItem(value: 'Soledad', child: Text('Soledad')),
                ],
                onChanged: (value) => setState(() => selectedCity = value),
              ),
            ),
            _buildTextField(idController, 'Cédula'),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
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
            ),
            _buildTextField(emailController, 'Correo electrónico'),
            _buildTextField(passwordController, 'Contraseña', isPassword: true),
            _buildTextField(
              confirmPasswordController,
              'Confirmar contraseña',
              isPassword: true,
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 250,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_validateFields()) {
                      await registerUser(
                        emailController.text,
                        passwordController.text,
                      );
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("o"),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 250,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await signInWithGoogle(context);
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.blue,
                  ),
                  label: const Text(
                    'Registrarse con Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }

  Future<void> registerUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user != null) {
        await saveUserData(user);
      }

      print("Usuario registrado: ${user?.email}");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('La contraseña es muy débil.');
      } else if (e.code == 'email-already-in-use') {
        print('El correo ya está registrado.');
      } else {
        print('Error: ${e.message}');
      }
    }
  }

  Future<void> saveUserData(User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userDoc.set({
      'nombre': nameController.text,
      'apellido': lastNameController.text,
      'ciudad': selectedCity,
      'cedula': idController.text,
      'fechaNacimiento': selectedDate?.toIso8601String(),
      'email': user.email,
      'uid': user.uid,
      'photoURL': '',
      'permisos':0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  

  Future<void> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      // Usuario nuevo → mostrar formulario extra
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExtraUserInfoPage(user: userCredential.user!),
        ),
      );
    }

    // Ya con eso, lo mandas a home o donde sea
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  bool _validateFields() {
    if (nameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        idController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        selectedCity == null ||
        selectedDate == null) {
      _showErrorDialog(
        'Por favor, completa todos los campos antes de continuar.',
      );
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog('Las contraseñas no coinciden.');
      return false;
    }

    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
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
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    idController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
