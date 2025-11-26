import 'package:flutter/material.dart';

class TrackingScreen extends StatefulWidget {
  final String userName;

  const TrackingScreen({
    super.key,
    required this.userName,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isTracking = false;
  String _vehicleName = 'Veículo não carregado'; // depois vamos buscar do backend

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    // TODO: buscar veículo vinculado ao usuário via backend
    // Exemplo futuro: VehicleService().getVehicleForCurrentUser();
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _vehicleName = 'Caminhão A'; // placeholder
    });
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      // TODO: parar stream de localização + fechar websocket
      setState(() {
        _isTracking = false;
      });
    } else {
      // TODO: pedir permissão, abrir websocket e iniciar envio periódico
      setState(() {
        _isTracking = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _isTracking ? Colors.red : Colors.green;
    final buttonText = _isTracking ? 'Parar rastreamento' : 'Começar rastreamento';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreamento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Olá, ${widget.userName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                'Veículo vinculado:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _vehicleName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_isTracking)
                const Text(
                  'Rastreamento ativo, enviando localização em tempo real...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                  ),
                )
              else
                const Text(
                  'Rastreamento desativado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
