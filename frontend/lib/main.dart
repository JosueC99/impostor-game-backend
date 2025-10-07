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

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() {
    // IMPORTANTE: Usa 10.0.2.2 para el emulador de Android
    _socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
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
            builder: (context) => LobbyPage(
              roomCode: roomCode,
              socket: _socket,
              initialPlayers: [ {'id': _socket.id, 'name': _nameController.text} ],
            ),
          ),
        );
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
            builder: (context) => LobbyPage(
              roomCode: roomCode,
              socket: _socket,
              initialPlayers: players,
            ),
          ),
        );
      }
    });

    // Listener para manejar errores del servidor
    _socket.on('error', (errorMessage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _createRoom() {
    if (_nameController.text.isNotEmpty) {
      _socket.emit('createRoom', _nameController.text);
    } else {
      // Opcional: Mostrar error si el nombre está vacío
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce tu nombre')),
      );
    }
  }

  // void _createRoom() {
  //   if (_nameController.text.isNotEmpty) {
  //     // 1. Comentamos la línea original que se conecta al servidor
  //     // _socket.emit('createRoom', _nameController.text);

  //     // 2. AÑADIMOS NAVEGACIÓN DE PRUEBA:
  //     // Cambia 'IMPOSTOR' por 'MESSI' para probar la otra vista
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => RoleRevealPage(role: 'IMPOSTOR'),
  //       ),
  //     );

  //   } else {
  //     // El mensaje de error si el nombre está vacío se queda igual
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Por favor, introduce tu nombre')),
  //     );
  //   }
  // }

  void _joinRoom() {
    if (_nameController.text.isNotEmpty && _roomCodeController.text.isNotEmpty) {
      _socket.emit('joinRoom', {
        'playerName': _nameController.text,
        'roomCode': _roomCodeController.text.toUpperCase(),
      });
    } else {
      // Opcional: Mostrar error si algún campo está vacío
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce tu nombre y el código de la sala')),
      );
    }
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
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tu Nombre',
                  ),
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: _createRoom,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CREAR SALA', style: TextStyle(fontSize: 18)),
                ),
                
                const SizedBox(height: 40),

                TextField(
                  controller: _roomCodeController,
                  textCapitalization: TextCapitalization.characters, // Para que sea más fácil escribir códigos
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Código de la Sala',
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
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