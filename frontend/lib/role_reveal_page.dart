import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';

class RoleRevealPage extends StatelessWidget {
  // 1. Cambiamos el tipo a 'dynamic' para que acepte tanto String como Map
  final dynamic role;

  const RoleRevealPage({
    Key? key,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. Hacemos una comprobación segura del tipo de dato
    // Si 'role' es un String y además es igual a 'IMPOSTOR', entonces es el impostor.
    final bool isImpostor = role is String && role == 'IMPOSTOR';

    if (isImpostor) {
      // Si es impostor, mostramos la vista clásica
      return buildImpostorView(context);
    } else {
      // Si no, es un objeto de jugador, y mostramos la vista de futbolista
      return buildPlayerView(context);
    }
  }

  // Widget para la vista del Impostor (sin cambios)
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
    // 3. Ahora que sabemos que 'role' no es un String, podemos tratarlo como un Map
    final String playerName = role['name'] ?? 'N/A';
    final String playerCountryCode = role['countryCode'] ?? 'AR';

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
                child: CountryFlag.fromCountryCode(
                  playerCountryCode,
                  height: 80,
                  width: 120,
                  borderRadius: 12,
                ),
              ),
              SizedBox(height: 20),

              Text(
                playerName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 50, color: Colors.greenAccent, fontWeight: FontWeight.bold),
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