import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'role_reveal_page.dart';

class LobbyPage extends StatefulWidget {
  final String roomCode;
  final IO.Socket socket;
  final List<dynamic> initialPlayers;

  const LobbyPage({
    Key? key,
    required this.roomCode,
    required this.socket,
    required this.initialPlayers,
  }) : super(key: key);

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  // La lista de jugadores se guardará aquí y se actualizará en tiempo real
  late List<dynamic> players;

  @override
  void initState() {
    super.initState();
    players = widget.initialPlayers; // Guardamos la lista inicial de jugadores

    // Listener para actualizar la lista de jugadores cuando alguien nuevo se une
    widget.socket.on('updatePlayers', (updatedPlayers) {
      print("Recibida actualización de jugadores: $updatedPlayers");
      if (mounted) { // Nos aseguramos de que el widget todavía exista
        setState(() {
          players = updatedPlayers;
        });
      }
    });

    // Listener para cuando el anfitrión inicia el juego
    // En lobby_page.dart
    widget.socket.on('gameStarted', (data) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoleRevealPage(role: {'role': data['role']}),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Es una buena práctica dejar de escuchar eventos cuando la pantalla se destruye
    widget.socket.off('updatePlayers');
    widget.socket.off('gameStarted');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para saber si el jugador actual es el anfitrión (el primer jugador en la lista)
    final bool isHost = players.isNotEmpty && players[0]['id'] == widget.socket.id;

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Sala de Espera'),
        // centerTitle: true,
        // automaticallyImplyLeading: true, // Opcional: para quitar la flecha de "atrás"
        title: const Text('Sala de Espera'),
        centerTitle: true,
        // Añadimos un botón de "atrás" personalizado
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Le avisamos al servidor que nos vamos
            widget.socket.emit('leaveRoom', widget.roomCode);
            // Y luego retrocedemos de pantalla
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mostrar el código de la sala
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'CÓDIGO DE LA SALA:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.roomCode,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Título de la lista de jugadores
            Text(
              'Jugadores Conectados (${players.length}/8)',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Lista de jugadores
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  // Resaltamos al anfitrión
                  final bool isPlayerHost = index == 0;
                  return Card(
                    color: isPlayerHost ? Colors.blueGrey[700] : null,
                    child: ListTile(
                      leading: Icon(isPlayerHost ? Icons.star : Icons.person),
                      title: Text(player['name'] ?? 'Sin Nombre'),
                    ),
                  );
                },
              ),
            ),
            
            // Botón para empezar el juego, solo visible para el anfitrión
            if (isHost)
              ElevatedButton(
                onPressed: () {
                  // Le decimos al servidor que inicie el juego para esta sala
                  widget.socket.emit('startGame', widget.roomCode);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text('EMPEZAR JUEGO', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }
}