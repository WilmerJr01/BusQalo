import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class PlanInfoPage extends StatefulWidget {
  final bool plan;
  const PlanInfoPage({super.key, required this.plan});

  @override
  State<PlanInfoPage> createState() => _PlanInfoPageState();
}

class _PlanInfoPageState extends State<PlanInfoPage> {
  bool mostrarInfo = false;
  String _tipo = '';
  bool _esValida = false;
  DateTime? _fechaVencimiento;

  @override
  void initState() {
    super.initState();
    if (widget.plan == true) {
      _cargarFechaVencimiento();
    }
  }

  Future<void> _cargarFechaVencimiento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('Suscripciones')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null &&
        data['historial'] is List &&
        (data['historial'] as List).isNotEmpty) {
      final historial = data['historial'] as List;
      final ultimo = historial.last;
      if (ultimo['fechaDeFin'] != null) {
        setState(() {
          _fechaVencimiento = (ultimo['fechaDeFin'] as Timestamp).toDate();
        });
      }
    }
  }

  void _finalizarCompraExitosa() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Compra exitosa 🎉!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  bool validarTarjetaLuhn(String input) {
    input = input.replaceAll(' ', '');
    if (input.isEmpty || input.length < 13) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = input.length - 1; i >= 0; i--) {
      int n = int.parse(input[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  String tipoTarjeta(String input) {
    input = input.replaceAll(' ', '');
    if (input.startsWith('4')) return 'Visa';
    if (input.startsWith('5')) return 'MasterCard';
    if (input.startsWith('34') || input.startsWith('37'))
      return 'American Express';
    if (input.startsWith('6')) return 'Discover';
    return 'Desconocida';
  }

  void _mostrarDialogoPago() {
    final TextEditingController tarjetaController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                '¡Finaliza tu compra!',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tarjetaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CreditCardNumberInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Número de tarjeta',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        _tipo = tipoTarjeta(value);
                        _esValida = validarTarjetaLuhn(value);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tipo: $_tipo',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (tarjetaController.text.isNotEmpty && !_esValida)
                    const Text(
                      'Tarjeta no válida',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _esValida
                      ? () async {
                          Navigator.pop(
                            context,
                          ); // Cierra el diálogo de tarjeta
                          Future.delayed(
                            const Duration(milliseconds: 300),
                            () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final now = DateTime.now();
                                final fin = DateTime(
                                  now.year,
                                  now.month + 1,
                                  now.day,
                                );

                                final tarjetasQuery = await FirebaseFirestore
                                    .instance
                                    .collection('tarjetas')
                                    .where(
                                      'numero',
                                      isEqualTo: tarjetaController.text,
                                    )
                                    .where('usuarioId', isEqualTo: user.uid)
                                    .limit(1)
                                    .get();

                                String tarjetaUid;
                                if (tarjetasQuery.docs.isEmpty) {
                                  final tarjetaRef = await FirebaseFirestore
                                      .instance
                                      .collection('tarjetas')
                                      .add({
                                        'numero': tarjetaController.text,
                                        'usuarioId': user.uid,
                                        'tipo': _tipo,
                                        'fechaRegistro': Timestamp.now(),
                                      });
                                  tarjetaUid = tarjetaRef.id;
                                } else {
                                  tarjetaUid = tarjetasQuery.docs.first.id;
                                }

                                await FirebaseFirestore.instance
                                    .collection('Suscripciones')
                                    .doc(user.uid)
                                    .set({
                                      'plan': 'Plan Premium',
                                      'historial': FieldValue.arrayUnion([
                                        {
                                          'fechaDeInicio': Timestamp.fromDate(
                                            now,
                                          ),
                                          'fechaDeFin': Timestamp.fromDate(fin),
                                          'tarjetaUid': tarjetaUid,
                                        },
                                      ]),
                                      'activa': true,
                                    }, SetOptions(merge: true));

                                _finalizarCompraExitosa(); // ⬅️ Mostrar mensaje y redirigir
                              }
                            },
                          );
                        }
                      : null,
                  child: const Text('Pagar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tu Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset('assets/logo.png', width: 120, height: 120),
          ),
          const SizedBox(height: 10),
          if (widget.plan == false)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '¡Vuelvete un Viajero BusQalo!',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Suscripción mensual: \$9.900 pesos/mes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          SizedBox(height: 8),
                          // Ítem 1
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'Agregar tus rutas favoritas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Ítem 2
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus,
                                color: Colors.blue,
                                size: 26,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ver todas las rutas de buses',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Ítem 3
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm, color: Colors.indigo, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'Agregar recordatorios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Ítem 4
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.more_horiz,
                                color: Colors.teal,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '¡Y más funciones exclusivas!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _mostrarDialogoPago,
                      icon: Icon(
                        Icons.supervised_user_circle_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          203,
                          158,
                          24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      label: const Text(
                        'Volverse Viajero BusQalo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.plan == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '¡Ya eres un viajero Viajero BusQalo!',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_fechaVencimiento != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Tu suscripción vence el: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
