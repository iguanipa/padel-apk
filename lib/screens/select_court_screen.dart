import 'package:apk/services/config_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para jsonDecode

class SelectCourtScreen extends StatefulWidget {
  const SelectCourtScreen({super.key});

  @override
  State<SelectCourtScreen> createState() => _SelectCourtScreenState();
}

class _SelectCourtScreenState extends State<SelectCourtScreen> {
  List<Map<String, dynamic>> courts = [];
  bool loading = true;
  String? selectedCourt;

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    setState(() => loading = true);

    try {
      // Obtener la URL base desde ConfigService
      final apiUrl = await ConfigService.getApiUrl();
      final url = Uri.parse('$apiUrl/game/get-courts');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            courts = List<Map<String, dynamic>>.from(data);
          });
        } else if (data['courts'] != null) {
          setState(() {
            courts = List<Map<String, dynamic>>.from(data['courts']);
          });
        } else {
          throw Exception('Formato de respuesta inválido');
        }
      } else {
        throw Exception('Error al cargar canchas: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar canchas: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Opcional: Mostrar datos de prueba si hay error
      setState(() {
        courts = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Cancha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCourt,
              decoration: InputDecoration(
                labelText: 'Seleccionar Cancha',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _buildCourtDropdownItems(),
              onChanged: (value) {
                setState(() => selectedCourt = value);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedCourt == null ? null : _navigateToScoreboard,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Ver Marcador'),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCourtDropdownItems() {
    return [
      if (loading)
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Cargando canchas...'),
        )
      else if (courts.isEmpty)
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No hay canchas disponibles'),
        )
      else
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Seleccione una cancha'),
        ),
      ...courts.map((court) {
        return DropdownMenuItem<String>(
          value: court['id'].toString(),
          child: Text('Cancha #${court['id']} - ${court['name']}'),
        );
      }).toList(),
    ];
  }

  void _navigateToScoreboard() {
    Navigator.pushNamed(
      context,
      '/scoreboard',
      arguments: int.parse(selectedCourt!),
    );
  }
}
