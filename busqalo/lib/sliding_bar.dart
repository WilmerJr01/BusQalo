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

  bool _isMinimized = true;

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
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.directions_bus,
                    color: Colors.green,
                  ),
                  title: const Text('Ver rutas de buses'),
                  onTap: () => debugPrint('Ver rutas tapped'),
                ),
                ListTile(
                  leading: const Icon(Icons.place, color: Colors.green),
                  title: const Text('Paradas cercanas'),
                  onTap: () => debugPrint('Paradas tapped'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.green),
                  title: const Text('Configuración'),
                  onTap: () => debugPrint('Configuración tapped'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
