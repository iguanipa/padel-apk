import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  runApp(const RouteApp());
}

class RouteApp extends StatelessWidget {
  const RouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pádel Pro Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/select-court': (context) => const SelectCourtScreen(),
        '/scoreboard': (context) {
          final courtId = ModalRoute.of(context)!.settings.arguments as int;
          return ScoreboardScreen(courtId: courtId);
        },
      },
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PÁDEL PRO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/select-court');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'VER MARCADOR',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    fetchCourts();
  }

  Future<void> fetchCourts() async {
    setState(() => loading = true);
    try {
      // Implementar llamada real a la API aquí
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        courts = [
          {'id': 1, 'name': 'Cancha Central'},
          {'id': 2, 'name': 'Cancha Norte'},
          {'id': 3, 'name': 'Cancha Sur'},
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar canchas: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              items: [
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
              ],
              onChanged: (value) {
                setState(() => selectedCourt = value);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  selectedCourt == null
                      ? null
                      : () {
                        Navigator.pushNamed(
                          context,
                          '/scoreboard',
                          arguments: int.parse(selectedCourt!),
                        );
                      },
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
}

class ScoreboardScreen extends StatefulWidget {
  final int courtId;

  const ScoreboardScreen({super.key, required this.courtId});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late io.Socket socket;

  // Datos del marcador
  String bluePoints = '0';
  String redPoints = "0";
  int blueGames = 0;
  int redGames = 0;
  int blueSets = 0;
  int redSets = 0;
  int currentSet = 1;
  int currentGame = 1;
  String servingTeam = 'azul';
  String matchStatus = 'En juego';

  @override
  void initState() {
    super.initState();
    connectToSocket();
  }

  void connectToSocket() {
    socket = io.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Conectado al servidor WebSocket');
      socket.emit('unirse_cancha', {'cancha_id': widget.courtId});
    });

    socket.on('actualizar_marcador', (data) {
      print('Datos recibidos: $data');
      setState(() {
        bluePoints = data['puntos']['azul'].toString();
        redPoints = data['puntos']['rojo'].toString();
        blueGames = data['juegos']['azul'];
        redGames = data['juegos']['rojo'];
        blueSets = data['sets']['azul'];
        redSets = data['sets']['rojo'];
        currentSet = data['setActual'];
        currentGame = data['juegoActual'];
        servingTeam = data['servicio'];
        matchStatus = data['estadoPartido'];
      });
    });

    socket.onDisconnect((_) => print('Desconectado del servidor WebSocket'));
    socket.onError((error) => print('Error de WebSocket: $error'));
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final bool isPortrait = orientation == Orientation.portrait;

          return Column(
            children: [
              // Header
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PÁDEL PRO',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Cancha #${widget.courtId} | Set $currentSet | Juego $currentGame',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Row(
                      children: [
                        const Text('Saque: '),
                        Text(
                          servingTeam == 'azul' ? 'AZUL' : 'ROJO',
                          style: TextStyle(
                            color:
                                servingTeam == 'azul'
                                    ? Colors.blueAccent
                                    : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (servingTeam == 'azul')
                          const ServingIndicator(color: Colors.blueAccent),
                        if (servingTeam == 'rojo')
                          const ServingIndicator(color: Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child:
                    isPortrait
                        ? _buildPortraitLayout()
                        : _buildLandscapeLayout(),
              ),

              // Barra de estado
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  matchStatus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Equipo Azul
        Expanded(
          child: Container(
            color:
                servingTeam == 'azul'
                    ? Colors.blue[900]!.withOpacity(0.3)
                    : Colors.grey[800],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'EQUIPO AZUL',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Indicadores de sets
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            blueSets > index ? Colors.green : Colors.grey[700],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                // Puntos
                Text(
                  bluePoints,
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                // Juegos
                Text(
                  'Juegos: $blueGames',
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // Divisor
        Container(
          width: 2,
          color: Colors.grey[800],
          margin: const EdgeInsets.symmetric(vertical: 40),
        ),

        // Equipo Rojo
        Expanded(
          child: Container(
            color:
                servingTeam == 'rojo'
                    ? Colors.red[900]!.withOpacity(0.3)
                    : Colors.grey[800],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'EQUIPO ROJO',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Indicadores de sets
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            redSets > index ? Colors.green : Colors.grey[700],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                // Puntos
                Text(
                  redPoints,
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                // Juegos
                Text(
                  'Juegos: $redGames',
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Expanded(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 120,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Equipo Azul
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color:
                    servingTeam == 'azul'
                        ? Colors.blue[900]!.withOpacity(0.3)
                        : Colors.grey[800],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'EQUIPO AZUL',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Indicadores de sets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                blueSets > index
                                    ? Colors.green
                                    : Colors.grey[700],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),
                    // Puntos
                    Text(
                      bluePoints,
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Juegos
                    Text(
                      'Juegos: $blueGames',
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Divisor
              Container(
                height: 2,
                color: Colors.grey[800],
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),

              // Equipo Rojo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color:
                    servingTeam == 'rojo'
                        ? Colors.red[900]!.withOpacity(0.3)
                        : Colors.grey[800],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'EQUIPO ROJO',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Indicadores de sets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                redSets > index
                                    ? Colors.green
                                    : Colors.grey[700],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),
                    // Puntos
                    Text(
                      redPoints,
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Juegos
                    Text(
                      'Juegos: $redGames',
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServingIndicator extends StatefulWidget {
  final Color color;

  const ServingIndicator({super.key, required this.color});

  @override
  State<ServingIndicator> createState() => _ServingIndicatorState();
}

class _ServingIndicatorState extends State<ServingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.3);
        final opacity = 1.0 - (_controller.value * 0.3);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
