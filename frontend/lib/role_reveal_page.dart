import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';

class RoleRevealPage extends StatelessWidget {
  // Ahora podemos volver a decir que 'role' es siempre un Map, lo que es más seguro
  final Map<String, dynamic> role;

  const RoleRevealPage({
    Key? key,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // La comprobación vuelve a ser simple y directa
    final bool isImpostor = role['name'] == 'IMPOSTOR';

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