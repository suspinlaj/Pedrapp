import 'package:flutter/material.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/modelos/bloque_horario.dart';
import 'package:pedrapp/servicios/horario_service.dart';

// Gestionar la lógica y el estado de la pantalla del horario
class HorarioController extends ChangeNotifier {
  final HorarioService _horarioService = HorarioService();
  
  List<BloqueHorario> bloques = [];
  bool cargando = true;

  // Cargar datos iniciales al arrancar la pantalla
  Future<void> inicializar() async {
    final datosNube = await _horarioService.cargarHorario();

    if (datosNube.isEmpty) {
      // Cargar plantilla por defecto si es nuevo usuario
      bloques = [
        BloqueHorario(id: '1', diaSemana: 1, horaInicio: const TimeOfDay(hour: 15, minute: 30), horaFin: const TimeOfDay(hour: 17, minute: 0), titulo: 'Estudio General', colorEtiqueta: Colores.rojo),
        BloqueHorario(id: '2', diaSemana: 1, horaInicio: const TimeOfDay(hour: 17, minute: 0), horaFin: const TimeOfDay(hour: 17, minute: 30), titulo: 'Descanso / Merienda', colorEtiqueta: Colores.amarillo),
        BloqueHorario(id: '3', diaSemana: 2, horaInicio: const TimeOfDay(hour: 18, minute: 0), horaFin: const TimeOfDay(hour: 20, minute: 0), titulo: 'A VER A SUSI', colorEtiqueta: Colors.green),
      ];
      // Guardar plantilla en la nube
      for (var bloque in bloques) {
        _horarioService.guardarBloque(bloque);
      }
    } else {
      bloques = datosNube;
    }

    cargando = false;
    notifyListeners(); // Avisar a la interfaz de que ya puede dibujarse
  }

  // Guardar un bloque nuevo o actualizado
  void guardarBloque(BloqueHorario bloque, bool isEditing) {
    if (!isEditing) {
      bloques.add(bloque);
    } else {
      final index = bloques.indexWhere((b) => b.id == bloque.id);
      if (index != -1) bloques[index] = bloque;
    }
    
    _horarioService.guardarBloque(bloque);
    notifyListeners();
  }

  // Borrar un bloque existente
  void eliminarBloque(String idBloque) {
    bloques.removeWhere((b) => b.id == idBloque);
    _horarioService.borrarBloque(idBloque);
    notifyListeners();
  }

  // Filtrar y ordenar bloques por día
  List<BloqueHorario> obtenerBloquesDelDia(int diaSemana) {
    return bloques.where((b) => b.diaSemana == diaSemana).toList()
      ..sort((a, b) => _timeToMinutes(a.horaInicio).compareTo(_timeToMinutes(b.horaInicio)));
  }

  // Convertir TimeOfDay a minutos totales (Uso interno)
  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;
}