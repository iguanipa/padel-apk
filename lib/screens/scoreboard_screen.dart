import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/serving_indicator.dart';

class ScoreboardScreen extends StatefulWidget {
  final int courtId;

  const ScoreboardScreen({super.key, required this.courtId});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late io.Socket socket;
  bool isLoading = true;
  String errorMessage = '';

  // Datos del marcador
  String bluePoints = '0';
  String redPoints = '0';
  int blueGames = 0;
  int redGames = 0;
  int blueSets = 0;
  int redSets = 0;
  int currentSet = 1;
  int currentGame = 1;
  String servingTeam = 'azul';
  String matchStatus = 'Cargando...';
  String blueTeamName = '';
  String redTeamName = '';
  List<String> bluePlayers = [];
  List<String> redPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _updatePoint(String color, int signal) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/game/cancha/${widget.courtId}/punto'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'color': color, 'signal': signal}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar punto: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Cargar datos iniciales desde la API
      final response = await http.get(
        Uri.parse('http://localhost:5000/game/cancha/${widget.courtId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 2. Actualizar el estado con los datos iniciales
        setState(() {
          bluePoints = data['puntos']['azul'].toString();
          redPoints = data['puntos']['rojo'].toString();
          blueGames = data['juegos']['azul'];
          redGames = data['juegos']['rojo'];
          blueSets = data['sets']['azul'];
          redSets = data['sets']['rojo'];
          currentSet = data['set_actual'];
          currentGame = data['juego_actual'];
          servingTeam = data['servicio'];
          matchStatus = data['estado_partido'] ?? 'En juego';
          blueTeamName = data['teams']['azul']['name'];
          redTeamName = data['teams']['rojo']['name'];
          bluePlayers = List<String>.from(data['teams']['azul']['players']);
          redPlayers = List<String>.from(data['teams']['rojo']['players']);
          isLoading = false;
        });

        // 3. Conectar al WebSocket después de cargar los datos iniciales
        _connectToSocket();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Error al cargar datos iniciales',
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        matchStatus = 'Error: $errorMessage';
        isLoading = false;
      });
    }
  }

  void _connectToSocket() {
    socket = io.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Conectado al WebSocket - Cancha ${widget.courtId}');
      socket.emit('unirse_cancha', {'cancha_id': widget.courtId});
    });

    socket.on('actualizar_marcador', (data) {
      if (mounted) {
        setState(() {
          bluePoints = data['puntos']['azul'].toString();
          redPoints = data['puntos']['rojo'].toString();
          blueGames = data['juegos']['azul'];
          redGames = data['juegos']['rojo'];
          blueSets = data['sets']['azul'];
          redSets = data['sets']['rojo'];
          currentSet = data['set_actual'];
          currentGame = data['juego_actual'];
          servingTeam = data['servicio'];
          matchStatus = data['estado_partido'] ?? 'En juego';

          // Actualizar nombres si vienen en la actualización
          if (data['teams'] != null) {
            blueTeamName = data['teams']['azul']['name'] ?? blueTeamName;
            redTeamName = data['teams']['rojo']['name'] ?? redTeamName;
            bluePlayers = List<String>.from(
              data['teams']['azul']['players'] ?? bluePlayers,
            );
            redPlayers = List<String>.from(
              data['teams']['rojo']['players'] ?? redPlayers,
            );
          }
        });
      }
    });

    socket.onDisconnect((_) => print('Desconectado del WebSocket'));
    socket.onError((error) => print('Error de WebSocket: $error'));
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Cargando marcador...',
                style: TextStyle(color: Colors.white),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child:
                    orientation == Orientation.portrait
                        ? _buildPortraitLayout()
                        : _buildLandscapeLayout(),
              ),
              _buildStatusBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            'Set $currentSet | Juego $currentGame',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          Row(
            children: [
              const Text('Saque: ', style: TextStyle(color: Colors.white)),
              Text(
                servingTeam == 'azul'
                    ? blueTeamName.toUpperCase()
                    : redTeamName.toUpperCase(),
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
    );
  }

  Widget _buildStatusBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        matchStatus,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        _buildTeamSection(
          team: 'azul',
          color: Colors.blueAccent,
          points: bluePoints,
          games: blueGames,
          sets: blueSets,
          teamName: blueTeamName,
          players: bluePlayers,
        ),
        Container(
          width: 2,
          color: Colors.grey[800],
          margin: const EdgeInsets.symmetric(vertical: 40),
        ),
        _buildTeamSection(
          team: 'rojo',
          color: Colors.redAccent,
          points: redPoints,
          games: redGames,
          sets: redSets,
          teamName: redTeamName,
          players: redPlayers,
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTeamSection(
            team: 'azul',
            color: Colors.blueAccent,
            points: bluePoints,
            games: blueGames,
            sets: blueSets,
            teamName: blueTeamName,
            players: bluePlayers,
          ),
          Container(
            height: 2,
            color: Colors.grey[800],
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          _buildTeamSection(
            team: 'rojo',
            color: Colors.redAccent,
            points: redPoints,
            games: redGames,
            sets: redSets,
            teamName: redTeamName,
            players: redPlayers,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection({
    required String team,
    required Color color,
    required String points,
    required int games,
    required int sets,
    required String teamName,
    required List<String> players,
  }) {
    return Expanded(
      child: Container(
        color: servingTeam == team ? color.withOpacity(0.1) : Colors.grey[800],
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'EQUIPO ${team.toUpperCase()}',
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(teamName, style: TextStyle(color: color, fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              players.join(' & '),
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildSetIndicators(sets),
            const SizedBox(height: 30),
            Text(
              points,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Juegos: $games',
              style: const TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            // Botones para sumar/restar puntos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _updatePoint(team, -1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.remove, size: 24),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _updatePoint(team, 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetIndicators(int setsWon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: setsWon > index ? Colors.green : Colors.grey[700],
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
    );
  }
}
