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
    // Verificamos si es un impostor o un jugador por la estructura del objeto
    final bool isImpostor = role['name'] == 'IMPOSTOR';

    if (isImpostor) {
      // Si es impostor, mostramos la vista clásica
      return buildImpostorView(context);
    } else {
      // Si no, mostramos la nueva vista de futbolista con bandera
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
  Widget buildPlayerView(BuildContext context) {
    final String playerName = role['name'] ?? 'N/A';
    final String playerCountryCode = role['countryCode'] ?? 'AR'; // 'AR' como fallback por si acaso

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