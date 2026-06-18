import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedrapp/core/colores.dart';
import 'package:pedrapp/servicios/lugar_service.dart';
import 'package:pedrapp/widgets/dialog_general.dart';

class DialogRecuperarDatos extends StatefulWidget {
  const DialogRecuperarDatos({super.key});

  @override
  State<DialogRecuperarDatos> createState() => _DialogRecuperarDatosState();
}

class _DialogRecuperarDatosState extends State<DialogRecuperarDatos> {
  final TextEditingController _restoreController = TextEditingController();
  String _miId = "Cargando...";
  bool _isCopied = false; // <-- 1. Variable de estado para controlar el mensaje

  @override
  void initState() {
    super.initState();
    _cargarId();
  }

  // Obtenemos el ID público que definimos en LugarService
  Future<void> _cargarId() async {
    final id = await LugarService.getDeviceId();
    setState(() => _miId = id);
  }

  @override
  Widget build(BuildContext context) {
    return DialogGeneral(
      title: 'Copia Seguridad',
      saveText: 'Restaurar',
      onSave: () async {
        if (_restoreController.text.isNotEmpty) {
          // ID viejo para recuperar datos
          await LugarService.setDeviceId(_restoreController.text);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Listooo! Reinicia la app para ver tus datos awa"),
                backgroundColor: Colores.rojo, 
              ),
            );
          }
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tu código secreto, recuérdalo eh", style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: SelectableText(_miId, style: const TextStyle(fontSize: 16, color: Colores.rojo))),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _miId));
                  // --- 2. Lógica para mostrar el mensaje temporalmente ---
                  setState(() => _isCopied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _isCopied = false);
                  });
                },
              )
            ],
          ),
          
          // --- 3. El mensajito que aparece solo si _isCopied es true ---
          if (_isCopied)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "¡Código copiado!",
                style: TextStyle(
                  color: Colores.rojo,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Divider(color: Colores.rojo, thickness: 1, height: 40),
          const Text("Aquí para recuperar tus datitos:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,)),
          const SizedBox(height: 10),
          TextField(
            controller: _restoreController,
            decoration: const InputDecoration(
              hintText: "Por lo que sea el código va aquí",
              
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colores.rojo, width: 2.0),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colores.rojo, width: 2.0),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}