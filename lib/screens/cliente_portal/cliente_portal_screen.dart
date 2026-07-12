import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../agente/agente_screen.dart';
import '../tramite_detalle/tramite_detalle_screen.dart';


class ClientePortalScreen extends StatefulWidget {
  const ClientePortalScreen({super.key});

  @override
  State<ClientePortalScreen> createState() => _ClientePortalScreenState();
}

class _ClientePortalScreenState extends State<ClientePortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (_, p, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${p.userNombre.split(' ').first} 👋',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'Portal de Trámites',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (_, p, __) => IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: p.loadingData ? null : () => p.cargarDatos(),
              tooltip: 'Actualizar',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'Mis Trámites'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (provider.loadingData) {
            return const _LoadingView();
          }
          if (provider.dataError.isNotEmpty) {
            return _ErrorView(
              error: provider.dataError,
              onRetry: () => provider.cargarDatos(),
            );
          }
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _PoliticasTab(politicas: provider.politicas),
              _TramitesTab(tramites: provider.tramites),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgenteScreen()),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text(
          'Asistente IA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


// ── Tab: Políticas disponibles ────────────────────────────────
class _PoliticasTab extends StatelessWidget {
  final List<Politica> politicas;
  const _PoliticasTab({required this.politicas});

  @override
  Widget build(BuildContext context) {
    if (politicas.isEmpty) {
      return const _EmptyView(
        icon: '📋',
        title: 'Sin trámites disponibles',
        subtitle: 'No hay trámites activos en este momento.',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: () => context.read<AppProvider>().cargarDatos(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: politicas.length,
        itemBuilder: (_, i) => _PoliticaCard(politica: politicas[i]),
      ),
    );
  }
}

class _PoliticaCard extends StatelessWidget {
  final Politica politica;
  const _PoliticaCard({required this.politica});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con categoría
          if (politica.categoria != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    politica.categoria!.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  politica.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  politica.descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Meta info
                Row(
                  children: [
                    if (politica.organizacion != null) ...[
                      const Icon(Icons.business_outlined,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        politica.organizacion!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (politica.tiempoEstimadoDias != null) ...[
                      const Icon(Icons.schedule_outlined,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        '~${politica.tiempoEstimadoDias} días',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoSolicitar(context),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Solicitar Trámite'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoSolicitar(BuildContext context) {
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SolicitarSheet(
        politica: politica,
        descCtrl: descCtrl,
      ),
    );
  }
}

class _SolicitarSheet extends StatefulWidget {
  final Politica politica;
  final TextEditingController descCtrl;
  const _SolicitarSheet({required this.politica, required this.descCtrl});

  @override
  State<_SolicitarSheet> createState() => _SolicitarSheetState();
}

class _SolicitarSheetState extends State<_SolicitarSheet> {
  bool _enviando = false;
  String _error = '';

  Future<void> _solicitar() async {
    setState(() {
      _enviando = true;
      _error = '';
    });
    final provider = context.read<AppProvider>();
    final tramite = await provider.solicitarTramite(
      widget.politica.id,
      widget.descCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (tramite != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Trámite solicitado: ${tramite.refDisplay}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      setState(() => _error = provider.actionError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.politica.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Confirma tu solicitud de trámite',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            const Text(
              'Descripción / Motivo (opcional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Describe brevemente el motivo de tu solicitud...',
              ),
            ),

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  '❌ $_error',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enviando ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _solicitar,
                    child: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Confirmar Solicitud'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Mis Trámites ─────────────────────────────────────────
class _TramitesTab extends StatelessWidget {
  final List<Tramite> tramites;
  const _TramitesTab({required this.tramites});

  @override
  Widget build(BuildContext context) {
    if (tramites.isEmpty) {
      return const _EmptyView(
        icon: '📂',
        title: 'Sin trámites',
        subtitle: 'Aún no has solicitado ningún trámite.\nVe a "Disponibles" para comenzar.',
      );
    }

    // Separar activos y completados
    final activos = tramites
        .where((t) => t.estado != 'COMPLETADO' && t.estado != 'RECHAZADO')
        .toList();
    final finalizados = tramites
        .where((t) => t.estado == 'COMPLETADO' || t.estado == 'RECHAZADO')
        .toList();

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: () => context.read<AppProvider>().cargarDatos(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activos.isNotEmpty) ...[
            const _SectionHeader(title: 'En curso', icon: '⏳'),
            const SizedBox(height: 8),
            ...activos.map((t) => _TramiteCard(tramite: t)),
            const SizedBox(height: 16),
          ],
          if (finalizados.isNotEmpty) ...[
            const _SectionHeader(title: 'Finalizados', icon: '✅'),
            const SizedBox(height: 8),
            ...finalizados.map((t) => _TramiteCard(tramite: t)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

class _TramiteCard extends StatelessWidget {
  final Tramite tramite;
  const _TramiteCard({required this.tramite});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TramiteDetalleScreen(tramite: tramite),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barra de estado superior
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: tramite.estadoColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Referencia
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tramite.refDisplay,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Badge estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tramite.estadoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tramite.estadoEmoji,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              tramite.estadoLabel,
                              style: TextStyle(
                                color: tramite.estadoColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    tramite.nombrePolitica ?? 'Trámite',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),

                  if (tramite.descripcion != null &&
                      tramite.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tramite.descripcion!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Info row
                  Row(
                    children: [
                      if (tramite.estado == 'EN_PROCESO' &&
                          tramite.nombreNodoActual != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${tramite.departamentoActual ?? ''} · ${tramite.nombreNodoActual}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          tramite.fechaInicioFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (tramite.estado == 'COMPLETADO' &&
                            tramite.duracionMinutos != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.timer_outlined,
                              size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            tramite.duracionFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          size: 18, color: Color(0xFFCBD5E1)),
                    ],
                  ),

                  // Progreso visual para EN_PROCESO
                  if (tramite.estado == 'EN_PROCESO' &&
                      tramite.historial.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildMiniProgress(tramite),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniProgress(Tramite tramite) {
    final completados = tramite.historial.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completados paso${completados != 1 ? 's' : ''} completado${completados != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            const Text(
              'En progreso',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completados > 0 ? (completados / (completados + 2)) : 0.1,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF2563EB),
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _EmptyView(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
