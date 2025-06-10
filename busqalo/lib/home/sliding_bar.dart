import 'package:busqalo/home/premium_page.dart';
import 'package:busqalo/home/recordatorios.dart';
import 'package:busqalo/home/rutas_favoritas.dart';
import 'package:busqalo/home/todas_las_rutas.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class SlidingOptionsPanel extends StatefulWidget {
  final TextEditingController searchController;
  final List<AutocompletePrediction> suggestions;
  final Function(String) onSearchChanged;
  final Function(AutocompletePrediction) onSuggestionTap;
  const SlidingOptionsPanel({
    super.key,
    required this.searchController,
    required this.suggestions,
    required this.onSearchChanged,
    required this.onSuggestionTap,
  });

  @override
  State<SlidingOptionsPanel> createState() => SlidingOptionsPanelState();
}

class SlidingOptionsPanelState extends State<SlidingOptionsPanel> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  static const double minSize = 0.1;
  static const double maxSize = 0.4;

  String _plan = 'Plan Invitado';
  bool switch_plan = false;

  bool _isMinimized = true;
  @override
  void initState() {
    super.initState();
    _cargarPlan();
    _controller.addListener(_handlePanelSizeChange);
  }

  Future<void> _cargarPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Suscripciones')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (doc.exists && data != null && data['activa'] is bool) {
      setState(() {
        switch_plan = data['activa'];
        if (switch_plan == true) {
          _plan = '¡Eres un Viajero BusQalo!';
        } else {
          _plan = 'Plan Invitado';
        }
      });
    } else {
      setState(() {
        switch_plan = false;
        _plan = 'Plan Invitado';
      });
    }
  }

  Future<void> minimizePanel() async {
    setState(() {
      _isMinimized = true;
    });
    await _controller.animateTo(
      minSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handlePanelSizeChange() {
    final extent = _controller.size;
    if (extent > 0.15 && _isMinimized) {
      // El panel fue expandido
      _cargarPlan();
      setState(() {
        _isMinimized = false;
      });
    } else if (extent <= 0.15 && !_isMinimized) {
      // El panel fue minimizado
      setState(() {
        _isMinimized = true;
      });
    }
  }

  void _onDragStart() {}

  void _onDragEnd() async {
    final extent = _controller.size;
    final targetSize = (extent - minSize) < (maxSize - extent)
        ? minSize
        : maxSize;
    setState(() {
      _isMinimized = targetSize == minSize;
    });
    await _controller.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onDragStart(),
      onPointerUp: (_) => _onDragEnd(),
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: minSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isMinimized)
                  const Text(
                    '¿A dónde quieres ir hoy?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                if (_isMinimized) const SizedBox(height: 40),
                TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: 'Busca un lugar, p.ej. Buenavista',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearchChanged('');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
                if (widget.suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = widget.suggestions[index];
                        return ListTile(
                          title: Text(suggestion.fullText),
                          onTap: () => widget.onSuggestionTap(suggestion),
                        );
                      },
                    ),
                  ),
                if (switch_plan == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextButton.icon(
                          icon: const Icon(
                            Icons.alarm,
                            color: Colors.teal,
                            size: 25,
                          ), // icono más grande
                          label: const Text(
                            'Recordatorios',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ), // texto más grande
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecordatoriosPage(),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 25,
                          ),
                          label: const Text(
                            'Rutas Favoritas',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RutasFavoritasPage(),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.directions_bus,
                            color: Colors.blue,
                            size: 25,
                          ),
                          label: const Text(
                            'Todas las rutas',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TodasLasRutasPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlanInfoPage(plan: switch_plan),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: switch_plan == true
                          ? Color.fromARGB(255, 203, 158, 24)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _plan,
                        style: TextStyle(
                          color: switch_plan == true
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
