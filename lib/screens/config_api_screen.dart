// lib/screens/config_api_screen.dart
import 'package:flutter/material.dart';
import 'package:apk/services/config_service.dart';

class ConfigApiScreen extends StatefulWidget {
  const ConfigApiScreen({super.key});

  @override
  State<ConfigApiScreen> createState() => _ConfigApiScreenState();
}

class _ConfigApiScreenState extends State<ConfigApiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final currentUrl = await ConfigService.getApiUrl();
    _urlController.text = currentUrl;
    setState(() => _isLoading = false);
  }

  Future<void> _saveUrl() async {
    if (_formKey.currentState!.validate()) {
      await ConfigService.setApiUrl(_urlController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL guardada correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar URL de API')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de la API',
                          hintText: 'Ej: http://mi-servidor:5000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una URL';
                          }

                          // Elimina espacios en blanco al inicio y final
                          final trimmedValue = value.trim();

                          // Intenta parsear la URL
                          final uri = Uri.tryParse(trimmedValue);

                          // Verifica si el parsing fue exitoso y si tiene esquema (http/https)
                          if (uri == null ||
                              (!uri.hasScheme ||
                                  (uri.scheme != 'http' &&
                                      uri.scheme != 'https'))) {
                            return 'Ingrese una URL válida (ej: http://servidor:5000)';
                          }

                          // Verifica que tenga host
                          if (uri.host.isEmpty) {
                            return 'La URL debe incluir un host o dirección';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveUrl,
                        child: const Text('Guardar URL'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
