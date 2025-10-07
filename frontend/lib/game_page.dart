import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GamePage extends StatefulWidget {
  final String role;
  final IO.Socket socket;

  const GamePage({
    Key? key,
    required this.role,
    required this.socket,
  }) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool get isImpostor => widget.role == 'IMPOSTOR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partida en Curso'),
        automaticallyImplyLeading: false, // No se puede retroceder de aquí
        backgroundColor: isImpostor ? Colors.red[900] : Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Vista superior (depende del rol)
            _buildRoleSpecificView(),

            // Botones de acción para todos
            _buildCommonActions(),
          ],
        ),
      ),
    );
  }

  // Widget que muestra la vista específica para cada rol
  Widget _buildRoleSpecificView() {
    if (isImpostor) {
      // VISTA DEL IMPOSTOR
      return Column(
        children: [
          Text('Eres el IMPOSTOR', style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text('Tu misión: Eliminar a los tripulantes sin ser descubierto.'),
          SizedBox(height: 40),
          ElevatedButton.icon(
            icon: Icon(Icons.warning),
            label: Text('SABOTEAR'),
            onPressed: () {}, // Lógica de sabotaje futura
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      );
    } else {
      // VISTA DEL TRIPULANTE
      return Column(
        children: [
          Text('Eres TRIPULANTE', style: TextStyle(fontSize: 24, color: Colors.cyan, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text('Tu misión: Completar las tareas y descubrir al impostor.'),
          SizedBox(height: 20),
          // Lista de tareas de ejemplo
          Card(child: ListTile(title: Text('Tarea 1: Calibrar motor'))),
          Card(child: ListTile(title: Text('Tarea 2: Vaciar basura'))),
        ],
      );
    }
  }

  // Widget para los botones que todos los jugadores ven
  Widget _buildCommonActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.report),
          label: Text('REUNIÓN'),
          onPressed: () {}, // Lógica para llamar a reunión
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}