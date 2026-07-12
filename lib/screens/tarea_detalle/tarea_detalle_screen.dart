import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../services/app_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

/// Pantalla de detalle de tarea con formularios dinámicos.
/// Principio SRP: cada widget privado tiene una responsabilidad única.
/// Principio OCP: nuevos tipos de campo se agregan sin modificar la lógica principal.
class TareaDetalleScreen extends StatefulWidget {
  final Tarea tarea;
  final VoidCallback onCompletado;

  const TareaDetalleScreen({
    super.key,
    required this.tarea,
    required this.onCompletado,
  });

  @override
  State<TareaDetalleScreen> createState() => _TareaDetalleScreenState();
}

class _TareaDetalleScreenState extends State<TareaDetalleScreen> {
  // Controladores para campos de texto dinámicos (clave: nombre del campo)
  final Map<String, TextEditingController> _textControllers = {};
  // Valores para campos boolean y select
  final Map<String, dynamic> _fieldValues = {};

  bool _guardando = false;
  bool _loadingIA = false;
  String _iaResultado = '';
  String _exito = '';
  String _error = '';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  /// Inicializa controladores para cada campo del formulario dinámico.
  void _initControllers() {
    for (final campo in widget.tarea.camposFormulario) {
      if (_isTextType(campo.tipo)) {
        _textControllers[campo.nombre] = TextEditingController();
      } else if (campo.tipo == 'boolean') {
        _fieldValues[campo.nombre] = '';
      } else if (campo.tipo == 'select') {
        _fieldValues[campo.nombre] = '';
      } else {
        _initSpecialField(campo);
      }
    }
    // Si no hay campos dinámicos, mantener el campo legacy de observación
    if (widget.tarea.camposFormulario.isEmpty) {
      _textControllers['observacion'] = TextEditingController();
      _fieldValues['aprobado'] = '';
    }
  }

  bool _isTextType(String tipo) =>
      tipo == 'text' || tipo == 'textarea' || tipo == 'number';

  /// Inicializa el valor por defecto para tipos especiales.
  void _initSpecialField(CampoFormulario campo) {
    switch (campo.tipo) {
      case 'fecha':
        _fieldValues[campo.nombre] = ''; // ISO date string
        break;
      case 'hora':
        _fieldValues[campo.nombre] = ''; // HH:mm string
        break;
      case 'checkbox':
        _fieldValues[campo.nombre] = <String>[]; // lista de seleccionados
        break;
      case 'radio':
        _fieldValues[campo.nombre] = '';
        break;
      case 'grid':
        _fieldValues[campo.nombre] = <Map<String, String>>[]; // [{descripcion, valor}]
        break;
    }
  }

  @override
  void dispose() {
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _completarTarea() async {
    // Validar campos requeridos
    for (final campo in widget.tarea.camposFormulario) {
      if (campo.requerido) {
        final valor = _getFieldValue(campo);
        if (valor == null || valor.toString().isEmpty) {
          setState(() => _error = 'Campo requerido: ${campo.etiqueta}');
          return;
        }
      }
    }

    // Si no hay campos dinámicos, validar el campo legacy
    if (widget.tarea.camposFormulario.isEmpty &&
        (_fieldValues['aprobado'] ?? '').isEmpty) {
      setState(() => _error = 'Selecciona un resultado antes de completar');
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    final datos = _buildFormData();
    final ok =
        await context.read<AppProvider>().completarTarea(widget.tarea.id, datos);

    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        setState(() =>
            _exito = '✅ Tarea completada. El sistema enrutó el trámite automáticamente.');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) widget.onCompletado();
      } else {
        setState(() => _error = '❌ Error al completar la tarea.');
      }
    }
  }

  /// Construye el mapa de datos del formulario para enviar al backend.
  Map<String, dynamic> _buildFormData() {
    final datos = <String, dynamic>{};

    if (widget.tarea.camposFormulario.isEmpty) {
      // Modo legacy: observación + aprobado
      datos['observacion'] = _textControllers['observacion']?.text ?? '';
      datos['aprobado'] = _fieldValues['aprobado'] ?? '';
    } else {
      for (final campo in widget.tarea.camposFormulario) {
        datos[campo.nombre] = _getFieldValue(campo);
      }
    }
    return datos;
  }

  dynamic _getFieldValue(CampoFormulario campo) {
    if (_isTextType(campo.tipo)) {
      return _textControllers[campo.nombre]?.text ?? '';
    }
    return _fieldValues[campo.nombre] ?? '';
  }

  Future<void> _consultarIA() async {
    setState(() {
      _loadingIA = true;
      _iaResultado = '';
    });
    try {
      final respuesta = await _apiService.preguntarAsistente(
          'Estoy en la tarea del nodo ${widget.tarea.nodoId}. '
          'El trámite es ${widget.tarea.tramiteId.substring(0, 8)}. '
          '¿Qué debo hacer y qué datos debo registrar?');
      setState(() => _iaResultado = respuesta);
    } catch (_) {
      setState(() => _iaResultado = '❌ Error al consultar la IA.');
    }
    setState(() => _loadingIA = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.bgColor),
      appBar: AppBar(
        backgroundColor: const Color(AppConfig.cardColor),
        elevation: 0,
        title: const Text('Detalle de Tarea', style: TextStyle(fontSize: 16)),
        actions: [
          EstadoBadge(estado: widget.tarea.estado),
          const SizedBox(width: 12)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (widget.tarea.instrucciones != null &&
                widget.tarea.instrucciones!.isNotEmpty) ...[
              _buildInstruccionesCard(),
              const SizedBox(height: 16),
            ],
            if (widget.tarea.estado != 'COMPLETADO')
              _buildFormularioCard()
            else
              _buildCompletadoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 Información de la Tarea',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            _buildInfoRow('ID Trámite',
                '${widget.tarea.tramiteId.substring(0, 16)}...'),
            _buildInfoRow('Nodo', widget.tarea.nombreNodo ?? widget.tarea.nodoId),
            if (widget.tarea.departamento != null)
              _buildInfoRow('Departamento', widget.tarea.departamento!),
            _buildInfoRow('Asignada', _formatFecha(widget.tarea.fechaAsignacion)),
            if (widget.tarea.prioridad != null)
              _buildInfoRow('Prioridad', widget.tarea.prioridad!),
          ],
        ),
      );

  Widget _buildInstruccionesCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📌 Instrucciones',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(widget.tarea.instrucciones!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.5)),
          ],
        ),
      );

  Widget _buildFormularioCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📝 Formulario',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Campos dinámicos o modo legacy
            if (widget.tarea.camposFormulario.isNotEmpty)
              ...widget.tarea.camposFormulario
                  .map((campo) => _buildCampo(campo))
            else ...[
              _buildLegacyObservacion(),
              const SizedBox(height: 14),
              _buildLegacyAprobado(),
            ],

            const SizedBox(height: 16),
            _buildBotonIA(),
            if (_iaResultado.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildIAResultado(),
            ],
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13)),
              ),
            if (_exito.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_exito,
                    style: const TextStyle(
                        color: Color(0xFF22C55E), fontSize: 13)),
              ),
            _buildBotonCompletar(),
          ],
        ),
      );

  /// Renderiza un campo dinámico según su tipo. Principio OCP: extensible sin modificar.
  Widget _buildCampo(CampoFormulario campo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(campo.etiqueta,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (campo.requerido)
                const Text(' *',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          _buildCampoInput(campo),
        ],
      ),
    );
  }

  Widget _buildCampoInput(CampoFormulario campo) {
    switch (campo.tipo) {
      case 'text':
        return _buildTextField(campo.nombre, maxLines: 1);
      case 'textarea':
        return _buildTextField(campo.nombre, maxLines: 3);
      case 'number':
        return _buildTextField(campo.nombre,
            maxLines: 1, keyboardType: TextInputType.number);
      case 'boolean':
        return _buildBooleanField(campo.nombre);
      case 'select':
        return _buildSelectField(campo.nombre, campo.opciones);
      case 'fecha':
        return _buildFechaField(campo.nombre);
      case 'hora':
        return _buildHoraField(campo.nombre);
      case 'checkbox':
        return _buildCheckboxField(campo.nombre, campo.opciones);
      case 'radio':
        return _buildRadioGroupField(campo.nombre, campo.opciones);
      case 'grid':
        return _buildGridField(campo.nombre);
      default:
        // file y otros: campo de texto simple como fallback
        return _buildTextField(campo.nombre, maxLines: 1);
    }
  }

  // ── Builders: Fecha y Hora ────────────────────────────────────────

  Widget _buildFechaField(String nombre) {
    final valor = (_fieldValues[nombre] ?? '') as String;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: valor.isNotEmpty
              ? DateTime.tryParse(valor) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3B82F6), surface: Color(0xFF1E293B)),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _fieldValues[nombre] =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Text(
              valor.isNotEmpty ? valor : 'Seleccionar fecha...',
              style: TextStyle(
                color: valor.isNotEmpty ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoraField(String nombre) {
    final valor = (_fieldValues[nombre] ?? '') as String;
    return GestureDetector(
      onTap: () async {
        final parts = valor.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: valor.isNotEmpty && parts.length == 2
              ? TimeOfDay(
                  hour: int.tryParse(parts[0]) ?? 0,
                  minute: int.tryParse(parts[1]) ?? 0)
              : TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3B82F6), surface: Color(0xFF1E293B)),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _fieldValues[nombre] =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Text(
              valor.isNotEmpty ? valor : 'Seleccionar hora...',
              style: TextStyle(
                color: valor.isNotEmpty ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Builders: Checkbox y Radio ────────────────────────────────────

  Widget _buildCheckboxField(String nombre, List<String> opciones) {
    final seleccionados = (_fieldValues[nombre] ?? <String>[]) as List<String>;
    if (opciones.isEmpty) return _buildTextField(nombre, maxLines: 1);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: opciones.map((op) {
        final activo = seleccionados.contains(op);
        return FilterChip(
          label: Text(op,
              style: TextStyle(
                color: activo ? Colors.white : Colors.grey,
                fontSize: 12,
              )),
          selected: activo,
          selectedColor: const Color(0xFF3B82F6),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          checkmarkColor: Colors.white,
          side: BorderSide(
              color: activo
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withValues(alpha: 0.15)),
          onSelected: (v) {
            setState(() {
              final List<String> nuevos = List.from(seleccionados);
              v ? nuevos.add(op) : nuevos.remove(op);
              _fieldValues[nombre] = nuevos;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRadioGroupField(String nombre, List<String> opciones) {
    final seleccionado = (_fieldValues[nombre] ?? '') as String;
    if (opciones.isEmpty) return _buildTextField(nombre, maxLines: 1);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: opciones.map((op) {
        final activo = seleccionado == op;
        return ChoiceChip(
          label: Text(op,
              style: TextStyle(
                color: activo ? Colors.white : Colors.grey,
                fontSize: 12,
              )),
          selected: activo,
          selectedColor: const Color(0xFF3B82F6),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          side: BorderSide(
              color: activo
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withValues(alpha: 0.15)),
          onSelected: (_) => setState(() => _fieldValues[nombre] = op),
        );
      }).toList(),
    );
  }

  // ── Builder: Grid/Tabla ───────────────────────────────────────────────

  Widget _buildGridField(String nombre) {
    // ignore: avoid_dynamic_calls
    final filas = List<Map<String, dynamic>>.from(
        (_fieldValues[nombre] as List?) ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(filas.length, (i) {
          final fila = filas[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _gridDecoration('Descripción'),
                    onChanged: (v) => setState(() {
                      fila['descripcion'] = v;
                      filas[i] = fila;
                      _fieldValues[nombre] = filas;
                    }),
                    controller: TextEditingController(
                        text: fila['descripcion']?.toString() ?? ''),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _gridDecoration('Valor'),
                    onChanged: (v) => setState(() {
                      fila['valor'] = v;
                      filas[i] = fila;
                      _fieldValues[nombre] = filas;
                    }),
                    controller: TextEditingController(
                        text: fila['valor']?.toString() ?? ''),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
                  onPressed: () => setState(() {
                    filas.removeAt(i);
                    _fieldValues[nombre] = filas;
                  }),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() {
            filas.add({'descripcion': '', 'valor': ''});
            _fieldValues[nombre] = filas;
          }),
          icon: const Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
          label: const Text('Agregar fila',
              style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
        ),
      ],
    );
  }

  InputDecoration _gridDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      );

  Widget _buildTextField(String nombre,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: _textControllers[nombre],
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildBooleanField(String nombre) {
    return Row(
      children: [
        _buildRadioBtn(nombre, 'true', '✅ Sí', const Color(0xFF22C55E)),
        const SizedBox(width: 10),
        _buildRadioBtn(nombre, 'false', '❌ No', const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _buildSelectField(String nombre, List<String> opciones) {
    if (opciones.isEmpty) return _buildTextField(nombre, maxLines: 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (_fieldValues[nombre] ?? '').isEmpty
              ? null
              : _fieldValues[nombre],
          hint: const Text('Seleccionar...',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          dropdownColor: const Color(AppConfig.cardColor),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          isExpanded: true,
          items: opciones
              .map((op) => DropdownMenuItem(value: op, child: Text(op)))
              .toList(),
          onChanged: (val) => setState(() => _fieldValues[nombre] = val ?? ''),
        ),
      ),
    );
  }

  // ── Modo legacy (sin camposFormulario) ────────────────────────

  Widget _buildLegacyObservacion() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Observaciones',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          _buildTextField('observacion', maxLines: 3),
        ],
      );

  Widget _buildLegacyAprobado() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resultado',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildRadioBtn(
                  'aprobado', 'true', '✅ Aprobado', const Color(0xFF22C55E)),
              const SizedBox(width: 10),
              _buildRadioBtn(
                  'aprobado', 'false', '❌ Rechazar', const Color(0xFFEF4444)),
            ],
          ),
        ],
      );

  Widget _buildRadioBtn(
      String campo, String valor, String label, Color color) {
    final selected = (_fieldValues[campo] ?? '') == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fieldValues[campo] = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? color : Colors.grey, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildBotonIA() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _loadingIA ? null : _consultarIA,
          icon: _loadingIA
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.purple))
              : const Text('✨', style: TextStyle(fontSize: 16)),
          label: Text(_loadingIA ? 'Consultando IA...' : 'Consultar Asistente IA'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple,
            side: const BorderSide(color: Colors.purple),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Widget _buildIAResultado() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🤖 Asistente IA:',
                style: TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_iaResultado,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, height: 1.5)),
          ],
        ),
      );

  Widget _buildBotonCompletar() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _guardando ? null : _completarTarea,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('✅ Completar Tarea',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildCompletadoCard() => _buildCard(
        child: Column(
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('Tarea Completada',
                style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              widget.tarea.fechaCompletado != null
                  ? 'El ${_formatFecha(widget.tarea.fechaCompletado!)}'
                  : '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(AppConfig.cardColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );

  Widget _buildInfoRow(String label, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
                width: 100,
                child: Text(label,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12))),
            Expanded(
                child: Text(valor,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13))),
          ],
        ),
      );

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
    }
  }
}
