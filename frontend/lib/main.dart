  import 'package:flutter/material.dart';
  import 'package:socket_io_client/socket_io_client.dart' as IO;
  import 'lobby_page.dart'; // Asegúrate de que este archivo exista en tu carpeta lib
  // import 'role_reveal_page.dart';

  void main() {
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Impostor Game',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomePage(),
      );
    }
  }

  class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _roomCodeController = TextEditingController();
    late IO.Socket _socket;
    bool _isLoading = false;

    @override
    void initState() {
      super.initState();
      _connectToServer();
    }

    void _connectToServer() {
      // IMPORTANTE: Usa 10.0.2.2 para el emulador de Android
      _socket = IO.io('https://impostor-game-definitivo.onrender.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket.connect();
      
      _socket.onConnect((_) => print('✅ Conectado al servidor'));

      // Listener para cuando CREAS una sala
      _socket.on('roomCreated', (roomCode) {
        print('Sala creada con éxito. Código: $roomCode');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/lobby'),
              builder: (context) => LobbyPage(
                roomCode: roomCode,
                socket: _socket,
                initialPlayers: [ {'id': _socket.id, 'name': _nameController.text} ],
              ),
            ),
          ).then((_) {
            // Verificación explícita para reiniciar el estado de carga
            if (mounted && _isLoading) {
              setState(() => _isLoading = false);
            }
          });
        }
      });

      // Listener para cuando te UNES a una sala con éxito
      _socket.on('joinSuccess', (data) {
        final String roomCode = data['roomCode'];
        final List<dynamic> players = data['players'];
        print('Te has unido con éxito a $roomCode. Jugadores: $players');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/lobby'),
              builder: (context) => LobbyPage(
                roomCode: roomCode,
                socket: _socket,
                initialPlayers: players,
              ),
            ),
          ).then((_) {
            // Verificación explícita para reiniciar el estado de carga
            if (mounted && _isLoading) {
              setState(() => _isLoading = false);
            }
          });
        }
      });

      // Listener para manejar errores del servidor
      _socket.on('error', (errorMessage) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      // Listener para cuando ya estás unido (para reconectar)
      _socket.on('alreadyJoined', (data) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/lobby'),
              builder: (context) => LobbyPage(
                roomCode: data['roomCode'],
                socket: _socket,
                initialPlayers: data['players'],
              ),
            ),
          ).then((_) {
            // Verificación explícita para reiniciar el estado de carga
            if (mounted && _isLoading) {
              setState(() => _isLoading = false);
            }
          });
        }
      });
    }

    void _createRoom() {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, introduce tu nombre')),
        );
        return;
      }
      setState(() => _isLoading = true);
      _socket.emit('createRoom', _nameController.text);
    }

    void _joinRoom() {
      if (_nameController.text.isEmpty || _roomCodeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, introduce tu nombre y el código de la sala')),
        );
        return;
      }
      setState(() => _isLoading = true);
      _socket.emit('joinRoom', {
        'playerName': _nameController.text,
        'roomCode': _roomCodeController.text.toUpperCase(),
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bienvenido al Juego'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.sports_soccer, size: 150, color: Colors.white70),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Tu Nombre',
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _createRoom,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('CREAR SALA', style: TextStyle(fontSize: 18)),
                        ),
                  
                  const SizedBox(height: 40),

                  TextField(
                    controller: _roomCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Código de la Sala',
                    ),
                  ),
                  const SizedBox(height: 20),

                  _isLoading
                      ? const SizedBox.shrink()
                      : ElevatedButton(
                          onPressed: _joinRoom,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('UNIRSE A LA SALA', style: TextStyle(fontSize: 18)),
                        ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }