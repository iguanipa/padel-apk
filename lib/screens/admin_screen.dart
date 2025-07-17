import 'package:apk/services/config_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> courts = [];
  bool loadingCourts = true;
  String? selectedCourt;
  bool resetting = false;
  bool initializing = false;
  bool showNotification = false;
  String notificationMessage = '';
  bool isNotificationSuccess = true;

  // Datos para inicialización
  final Map<String, dynamic> initData = {
    'court_id': '',
    'team_a': {
      'color': 'azul',
      'name': '',
      'players': ['', ''],
    },
    'team_b': {
      'color': 'rojo',
      'name': '',
      'players': ['', ''],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    setState(() {
      loadingCourts = true;
    });

    try {
      final apiUrl = await ConfigService.getApiUrl();
      final response = await http.get(Uri.parse('$apiUrl/game/get-courts'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          courts = List<Map<String, dynamic>>.from(data);
        });
      } else {
        _showNotification(
          'Error al cargar canchas: ${response.statusCode}',
          false,
        );
      }
    } catch (e) {
      _showNotification('Error al cargar canchas: $e', false);
    } finally {
      setState(() {
        loadingCourts = false;
      });
    }
  }

  Future<void> _resetCourt() async {
    if (selectedCourt == null) return;

    setState(() {
      resetting = true;
    });

    try {
      final apiUrl = await ConfigService.getApiUrl();
      final response = await http.post(
        Uri.parse('$apiUrl/game/cancha/$selectedCourt/reset?confirm=true'),
      );

      if (response.statusCode == 200) {
        _showNotification('Cancha reseteada exitosamente', true);
        setState(() {
          selectedCourt = null;
        });
      } else {
        _showNotification(
          'Error al resetear cancha: ${response.statusCode}',
          false,
        );
      }
    } catch (e) {
      _showNotification('Error al resetear cancha: $e', false);
    } finally {
      setState(() {
        resetting = false;
      });
    }
  }

  Future<void> _initializeCourt() async {
    // Validaciones
    if (initData['court_id'] == null ||
        (initData['court_id'] as String).isEmpty) {
      _showNotification('Selecciona una cancha', false);
      return;
    }

    if ((initData['team_a']!['name'] as String).isEmpty ||
        (initData['team_b']!['name'] as String).isEmpty) {
      _showNotification('Ambos equipos deben tener un nombre', false);
      return;
    }

    final teamAPlayers =
        (initData['team_a']!['players'] as List)
            .where((p) => p.toString().isNotEmpty)
            .toList();
    final teamBPlayers =
        (initData['team_b']!['players'] as List)
            .where((p) => p.toString().isNotEmpty)
            .toList();

    if (teamAPlayers.length < 2 || teamBPlayers.length < 2) {
      _showNotification('Cada equipo debe tener 2 jugadores', false);
      return;
    }

    setState(() {
      initializing = true;
    });

    try {
      final payload = {
        'team_a': {
          'color': initData['team_a']!['color'],
          'name': initData['team_a']!['name'],
          'players': teamAPlayers,
        },
        'team_b': {
          'color': initData['team_b']!['color'],
          'name': initData['team_b']!['name'],
          'players': teamBPlayers,
        },
      };

      final apiUrl = await ConfigService.getApiUrl();
      final response = await http.post(
        Uri.parse('$apiUrl/game/cancha/${initData['court_id']}/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        _showNotification('Cancha inicializada exitosamente', true);

        // Resetear formulario
        setState(() {
          initData['court_id'] = '';
          initData['team_a'] = {
            'name': '',
            'players': ['', ''],
            'color': 'azul',
          };
          initData['team_b'] = {
            'name': '',
            'players': ['', ''],
            'color': 'rojo',
          };
        });
      } else {
        _showNotification(
          'Error al inicializar cancha: ${response.statusCode}',
          false,
        );
      }
    } catch (e) {
      _showNotification('Error al inicializar cancha: $e', false);
    } finally {
      setState(() {
        initializing = false;
      });
    }
  }

  void _showNotification(String message, bool isSuccess) {
    setState(() {
      showNotification = true;
      notificationMessage = message;
      isNotificationSuccess = isSuccess;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showNotification = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Pádel', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'Resetear Cancha'),
            Tab(text: 'Inicializar Cancha'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // Pestaña Resetear Cancha
              _buildResetTab(),
              // Pestaña Inicializar Cancha
              _buildInitTab(),
            ],
          ),

          // Notificación flotante
          if (showNotification)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isNotificationSuccess ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notificationMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          showNotification = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Resetear Cancha',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCourt,
                decoration: InputDecoration(
                  labelText: 'Seleccionar Cancha',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                items: _buildCourtDropdownItems(),
                onChanged: (value) {
                  setState(() {
                    selectedCourt = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[800],
              ),
              if (selectedCourt != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirmar Reset',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '¿Estás seguro de resetear esta cancha?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¡Esto eliminará todos los datos de la cancha!',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: resetting ? null : _resetCourt,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[800],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Confirmar Reset'),
                                  if (resetting)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedCourt = null;
                                });
                              },
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Inicializar Cancha',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                children: [
                  // Selección de cancha
                  DropdownButtonFormField<String>(
                    value:
                        initData['court_id']?.isNotEmpty == true
                            ? initData['court_id']
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Cancha',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                    ),
                    items: _buildCourtDropdownItems(),
                    onChanged: (value) {
                      setState(() {
                        initData['court_id'] = value ?? '';
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey[800],
                  ),

                  // Equipo Azul
                  Card(
                    color: Colors.blue[900]?.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Equipo Azul',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                initData['team_a']!['name'] = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Jugadores',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Jugador 1',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                (initData['team_a']!['players'] as List)[0] =
                                    value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Jugador 2',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                (initData['team_a']!['players'] as List)[1] =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Equipo Rojo
                  Card(
                    color: Colors.red[900]?.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Equipo Rojo',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                initData['team_b']!['name'] = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Jugadores',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Jugador 1',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                (initData['team_b']!['players'] as List)[0] =
                                    value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Jugador 2',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[800],
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                (initData['team_b']!['players'] as List)[1] =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: initializing ? null : _initializeCourt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      initializing ? 'Inicializando...' : 'Inicializar Cancha',
                    ),
                    if (initializing)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCourtDropdownItems() {
    return [
      if (loadingCourts)
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Cargando canchas...',
            style: TextStyle(color: Colors.white70),
          ),
        )
      else if (courts.isEmpty)
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'No hay canchas disponibles',
            style: TextStyle(color: Colors.white70),
          ),
        )
      else
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Seleccione una cancha',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ...courts.map((court) {
        return DropdownMenuItem<String>(
          value: court['id'].toString(),
          child: Text(
            'Cancha #${court['id']} - ${court['name'] ?? 'Sin nombre'}',
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
    ];
  }
}
