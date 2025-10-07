import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart'; // Asegúrate de tener este paquete en pubspec.yaml

class RoleRevealPage extends StatelessWidget {
  // El rol sigue siendo un objeto (Map) que viene del servidor
  final Map<String, dynamic> role;

  const RoleRevealPage({
    Key? key,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraemos el rol real, que está anidado dentro del mapa.
    final dynamic roleData = role['role'];

    // Comprobamos si el rol es un String y si es "IMPOSTOR".
    final bool isImpostor = roleData is String && roleData == 'IMPOSTOR';

    if (isImpostor) {
      // Si es impostor, mostramos la vista de impostor.
      return buildImpostorView(context);
    } else if (roleData is Map<String, dynamic>) {
      // Si es un mapa, es un futbolista. Pasamos los datos del futbolista.
      return buildPlayerView(context, roleData);
    } else {
      // Fallback por si los datos no tienen el formato esperado.
      return Scaffold(
        body: Center(
          child: Text('Error: Rol desconocido'),
        ),
      );
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
                style: TextStyle(fontSize: 70, color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              SizedBox(height: 80),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text('JUGAR DE NUEVO'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la vista del Futbolista con Bandera
  Widget buildPlayerView(BuildContext context, Map<String, dynamic> playerData) {
    final String playerName = playerData['name'] ?? 'N/A';
    final String playerCountryCode = playerData['countryCode'] ?? 'AR'; // 'AR' como fallback por si acaso

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
              
              // Bandera del País
              Center(
                child: CountryFlag.fromCountryCode(
                  playerCountryCode,
                  height: 80,
                  width: 120,
                  borderRadius: 12,
                ),
              ),
              SizedBox(height: 20),

              // Nombre del Jugador
              Text(
                playerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 50,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 80),

              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text('JUGAR DE NUEVO'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 20)),
              )
            ],
          ),
        ),
      ),
    );
  }
}