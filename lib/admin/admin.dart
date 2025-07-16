import 'package:flutter/material.dart';

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
    fetchCourts();
  }

  Future<void> fetchCourts() async {
    setState(() => loadingCourts = true);
    try {
      // Aquí debes implementar la llamada a tu API para obtener las canchas
      // Ejemplo:
      // final response = await http.get(Uri.parse('http://tu-api/game/get-courts'));
      // courts = List<Map<String, dynamic>>.from(json.decode(response.body));

      // Datos de ejemplo (eliminar cuando implementes la API real)
      await Future.delayed(const Duration(seconds: 1));
      courts = [
        {'id': 1, 'name': 'Cancha Central'},
        {'id': 2, 'name': 'Cancha Norte'},
      ];
    } catch (e) {
      showNotification('Error al cargar canchas: $e', isError: true);
    } finally {
      setState(() => loadingCourts = false);
    }
  }

  Future<void> resetCourt() async {
    if (selectedCourt == null) return;

    setState(() => resetting = true);
    try {
      // Implementar llamada a la API para resetear la cancha
      // Ejemplo:
      // await http.post(Uri.parse('http://tu-api/game/cancha/$selectedCourt/reset?confirm=true'));

      // Simulación (eliminar cuando implementes la API real)
      await Future.delayed(const Duration(seconds: 2));

      showNotification('Cancha reseteada exitosamente');
      setState(() => selectedCourt = null);
    } catch (e) {
      showNotification('Error al resetear cancha: $e', isError: true);
    } finally {
      setState(() => resetting = false);
    }
  }

  Future<void> initializeCourt() async {
    // Validaciones
    if (initData['court_id'] == null ||
        (initData['court_id'] as String).isEmpty) {
      showNotification('Selecciona una cancha', isError: true);
      return;
    }

    if ((initData['team_a']!['name'] as String).isEmpty ||
        (initData['team_b']!['name'] as String).isEmpty) {
      showNotification('Ambos equipos deben tener un nombre', isError: true);
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
      showNotification('Cada equipo debe tener 2 jugadores', isError: true);
      return;
    }

    setState(() => initializing = true);
    try {
      // Preparar datos para enviar
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

      // Implementar llamada a la API para inicializar la cancha
      // Ejemplo:
      // await http.post(
      //   Uri.parse('http://tu-api/game/cancha/${initData['court_id']}/initialize'),
      //   body: json.encode(payload),
      //   headers: {'Content-Type': 'application/json'},
      // );

      // Simulación (eliminar cuando implementes la API real)
      await Future.delayed(const Duration(seconds: 2));

      showNotification('Cancha inicializada exitosamente');

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
    } catch (e) {
      showNotification('Error al inicializar cancha: $e', isError: true);
    } finally {
      setState(() => initializing = false);
    }
  }

  void showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[800] : Colors.green[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: const Text('Admin Pádel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resetear Cancha'),
            Tab(text: 'Inicializar Cancha'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña Resetear Cancha
          SingleChildScrollView(
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value:
                          initData['court_id']?.isNotEmpty == true
                              ? initData['court_id']
                              : null,
                      decoration: InputDecoration(
                        labelText: 'Seleccionar Cancha',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        if (loadingCourts)
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Cargando canchas...'),
                          )
                        else if (courts.isEmpty)
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No hay canchas disponibles'),
                          )
                        else
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Seleccione una cancha'),
                          ),
                        ...courts.map((court) {
                          return DropdownMenuItem(
                            value: court['id'].toString(),
                            child: Text(
                              'Cancha #${court['id']} - ${court['name'] ?? 'Sin nombre'}',
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => initData['court_id'] = value ?? '');
                      },
                    ),
                    if (selectedCourt != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Confirmar Reset',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '¿Estás seguro de resetear esta cancha?',
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
                                    onPressed: resetting ? null : resetCourt,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[800],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Confirmar Reset'),
                                        if (resetting)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
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
                                      setState(() => selectedCourt = null);
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
          ),

          // Pestaña Inicializar Cancha
          SingleChildScrollView(
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 1.5,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                      children: [
                        // Selección de cancha
                        DropdownButtonFormField<String>(
                          value: selectedCourt,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar Cancha',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            if (loadingCourts)
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
                                child: Text(
                                  'Cancha #${court['id']} - ${court['name'] ?? 'Sin nombre'}',
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() => selectedCourt = value);
                          },
                        ),

                        // Equipo Azul
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Equipo Azul',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Nombre',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(
                                      () => initData['team_a']!['name'] = value,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                const Text('Jugadores'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Jugador 1',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      (initData['team_a']!['players']
                                              as List)[0] =
                                          value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Jugador 2',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      (initData['team_a']!['players']
                                              as List)[1] =
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
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Equipo Rojo',
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Nombre',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(
                                      () => initData['team_b']!['name'] = value,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                const Text('Jugadores'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Jugador 1',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      (initData['team_b']!['players']
                                              as List)[0] =
                                          value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Jugador 2',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      (initData['team_b']!['players']
                                              as List)[1] =
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
                      onPressed: initializing ? null : initializeCourt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            initializing
                                ? 'Inicializando...'
                                : 'Inicializar Cancha',
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
          ),
        ],
      ),
    );
  }
}
