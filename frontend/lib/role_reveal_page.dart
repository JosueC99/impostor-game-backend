import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RoleRevealPage extends StatefulWidget {
  final Map<String, dynamic> role;
  final IO.Socket socket;
  final bool isHost;
  final String roomCode;

  const RoleRevealPage({
    Key? key,
    required this.role,
    required this.socket,
    required this.isHost,
    required this.roomCode,
  }) : super(key: key);

  @override
  _RoleRevealPageState createState() => _RoleRevealPageState();
}

class _RoleRevealPageState extends State<RoleRevealPage> {
  bool _isWaiting = false;

  @override
  Widget build(BuildContext context) {
    // La comprobación vuelve a ser simple y directa
    final bool isImpostor = widget.role['name'] == 'IMPOSTOR';

    if (isImpostor) {
      return buildImpostorView(context);
    } else {
      return buildPlayerView(context);
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
                const Text('Esperando al anfitrión...', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                onPressed: () => Navigator.of(context).pop(),
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
                    color: Colors.blue[900], // Azul oscuro
                    padding: const EdgeInsets.all(8), // Un poco de espacio
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

              if (_isWaiting)
                const Text('Esperando al anfitrión...', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Regresar al Lobby'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}