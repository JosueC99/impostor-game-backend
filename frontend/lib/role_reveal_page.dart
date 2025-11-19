import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RoleRevealPage extends StatefulWidget {
  final Map<String, dynamic> role;
  final String category;
  final IO.Socket socket;
  final bool isHost;
  final String roomCode;

  const RoleRevealPage({
    Key? key,
    required this.role,
    required this.category,
    required this.socket,
    required this.isHost,
    required this.roomCode,
  }) : super(key: key);

  @override
  _RoleRevealPageState createState() => _RoleRevealPageState();
}

class _RoleRevealPageState extends State<RoleRevealPage> {
  bool _isWaiting = false;

  // Mapa de íconos para cada categoría
  final Map<String, IconData> _categoryIcons = {
    'Cosas cotidianas': Icons.lightbulb_outline,
    'Videojuegos': Icons.gamepad_outlined,
    'Deportes': Icons.sports_soccer_outlined,
    'Vehículos': Icons.directions_car_outlined,
    'Películas y Series': Icons.movie_outlined,
    'Personajes Históricos y de Ciencia': Icons.science_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final bool isImpostor = widget.role['name'] == 'IMPOSTOR';

    if (isImpostor) {
      return buildImpostorView(context);
    } else {
      // Decidimos qué vista construir en función de la categoría
      if (widget.category == 'Jugadores de Fútbol') {
        return buildPlayerView(context);
      } else {
        return buildItemView(context);
      }
    }
  }

  // Widget para la vista del Impostor
  Widget buildImpostorView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ERES',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w300),
              ),
              SizedBox(height: 20),
              Text(
                'IMPOSTOR',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 60, color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              SizedBox(height: 80),
              if (_isWaiting)
                const Center( // <-- 1. Añades el widget Center
                  child: Text( // <-- 2. El Text ahora es el 'hijo'
                    'Esperando al anfitrión...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              if (!_isWaiting)
                ElevatedButton(
                  onPressed: () {
                    if (widget.isHost) {
                      print('>>> BOTÓN ANFITRIÓN: Enviando evento "playAgain" para la sala ${widget.roomCode}');
                      widget.socket.emit('playAgain', widget.roomCode);
                    } else {
                      // El no anfitrión ahora emite 'playerReady'
                      widget.socket.emit('playerReady', widget.roomCode);
                      setState(() {
                        _isWaiting = true;
                      });
                    }
                  },
                  child: const Text('JUGAR DE NUEVO'),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 20)),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Notificamos al servidor que ya no estamos listos
                  widget.socket.emit('playerUnready', widget.roomCode);
                  // Usamos popUntil para volver a la pantalla del Lobby
                  Navigator.of(context).popUntil((route) => route.settings.name == '/lobby');
                },
                child: const Text('Regresar al Lobby'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la vista del Futbolista con Bandera
  Widget buildPlayerView(BuildContext context) {
    final String playerName = widget.role['name'] ?? 'N/A';
    final String playerCountryCode = widget.role['countryCode'] ?? 'AR';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TU JUGADOR ES',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: Colors.white70, fontWeight: FontWeight.w300),
              ),
              SizedBox(height: 40),
              
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: const Color(0xFF28252B),
                    padding: const EdgeInsets.all(8),
                    child: CountryFlag.fromCountryCode(
                      playerCountryCode,
                      height: 80,
                      width: 120,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
                playerName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 50, color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 80),

              _buildPlayAgainButton(),
              const SizedBox(height: 20),
              _buildReturnToLobbyButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Nuevo Widget para la vista de Ítem con Ícono genérico
  Widget buildItemView(BuildContext context) {
    final String itemName = widget.role['name'] ?? 'N/A';
    final IconData icon = _categoryIcons[widget.category] ?? Icons.help_outline;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TU PALABRA ES',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: Colors.white70, fontWeight: FontWeight.w300),
              ),
              SizedBox(height: 40),

              Icon(icon, size: 100, color: Colors.white),

              SizedBox(height: 20),

              Text(
                itemName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 50, color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 80),

              _buildPlayAgainButton(),
              const SizedBox(height: 20),
              _buildReturnToLobbyButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Botón "Jugar de Nuevo" refactorizado
  Widget _buildPlayAgainButton() {
    if (_isWaiting) {
      return const Text('Esperando al anfitrión...', style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center);
    }
    return ElevatedButton(
      onPressed: () {
        if (widget.isHost) {
          widget.socket.emit('playAgain', widget.roomCode);
        } else {
          widget.socket.emit('playerReady', widget.roomCode);
          setState(() {
            _isWaiting = true;
          });
        }
      },
      child: const Text('JUGAR DE NUEVO'),
      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 20)),
    );
  }

  // Botón "Regresar al Lobby" refactorizado
  Widget _buildReturnToLobbyButton() {
    return TextButton(
      onPressed: () {
        widget.socket.emit('playerUnready', widget.roomCode);
        Navigator.of(context).popUntil((route) => route.settings.name == '/lobby');
      },
      child: const Text('Regresar al Lobby'),
    );
  }
}