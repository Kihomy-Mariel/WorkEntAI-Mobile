import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        return Stack(
          children: [
            child,
            if (!syncService.isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Modo Offline. Los cambios se sincronizarán al conectar.',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
