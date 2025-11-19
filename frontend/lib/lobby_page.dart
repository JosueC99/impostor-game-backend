import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para el portapapeles
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
  late List<dynamic> players;
  String _selectedCategory = 'Jugadores de Fútbol'; // Categoría por defecto
  final List<String> _categories = [
    'Jugadores de Fútbol',
    'Cosas cotidianas',
    'Videojuegos',
    'Deportes',
    'Vehículos',
    'Películas y Series',
    'Personajes Históricos y de Ciencia',
  ];

  @override
  void initState() {
    super.initState();
    players = (widget.initialPlayers.isNotEmpty && widget.initialPlayers[0] is List)
        ? widget.initialPlayers[0]
        : widget.initialPlayers;

    widget.socket.on('updatePlayers', (data) {
      if (mounted) {
        final List<dynamic> updatedPlayers = (data is List && data.isNotEmpty && data[0] is List) ? data[0] : (data as List? ?? []);
        print("Jugadores actualizados (corregido): $updatedPlayers");
        setState(() {
          players = updatedPlayers;
        });
      }
    });

    // Listener para cuando el anfitrión inicia el juego
    widget.socket.on('gameStarted', (data) {
      if (mounted) {
        final bool isHost = players.isNotEmpty && players[0]['id'] == widget.socket.id;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoleRevealPage(
              role: data['role'],
              category: data['category'], // Pasamos la categoría
              socket: widget.socket,
              isHost: isHost,
              roomCode: widget.roomCode,
            ),
          ),
        );
      }
    });

    widget.socket.on('roomDisbanded', (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El anfitrión ha disuelto la sala.')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });

    // Nuevo listener para la categoría
    widget.socket.on('categoryUpdated', (category) {
      if (mounted) {
        setState(() {
          _selectedCategory = category;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.socket.off('updatePlayers');
    widget.socket.off('gameStarted');
    widget.socket.off('roomDisbanded');
    widget.socket.off('categoryUpdated'); // Dejamos de escuchar
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.roomCode,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.roomCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('¡Código copiado!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Selector de Categoría (solo para el anfitrión)
            if (isHost)
              _buildCategorySelector(),
            if (!isHost)
              _buildCategoryDisplay(),

            const SizedBox(height: 24),

            Text(
              'Jugadores Conectados (${players.length}/8)',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  final bool isPlayerHost = index == 0;
                  final bool isReady = player['isReady'] ?? false;
                  return Card(
                    color: isPlayerHost ? Colors.blueGrey[700] : null,
                    child: ListTile(
                      leading: Icon(isPlayerHost ? Icons.star : Icons.person),
                      title: Text(player['name'] ?? 'Sin Nombre'),
                      trailing: isReady ? const Icon(Icons.check, color: Colors.greenAccent) : null,
                    ),
                  );
                },
              ),
            ),
            
            if (isHost)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.socket.emit('startGame', widget.roomCode);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('EMPEZAR JUEGO', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      widget.socket.emit('disbandRoom', widget.roomCode);
                      Navigator.pop(context);
                    },
                    child: const Text('Disolver Sala', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            if (!isHost)
              TextButton(
                onPressed: () {
                  widget.socket.emit('leaveRoom', widget.roomCode);
                  Navigator.pop(context);
                },
                child: const Text('Salir de la Sala', style: TextStyle(color: Colors.redAccent)),
              ),
          ],
        ),
      ),
    );
  }

  // Widget para que el anfitrión elija la categoría
  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          underline: const SizedBox(), // Sin línea debajo
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
              // Emitir el evento al servidor
              widget.socket.emit('selectCategory', {
                'roomCode': widget.roomCode,
                'category': newValue,
              });
            }
          },
          items: _categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, textAlign: TextAlign.center),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Widget para que los demás jugadores vean la categoría seleccionada
  Widget _buildCategoryDisplay() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'CATEGORÍA ACTUAL:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}