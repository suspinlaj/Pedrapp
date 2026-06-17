class Frases {
  // Frases motivadoras para la portada
  static const List<String> motivadoras = [
    "El sudor de hoy es la plaza de mañana.",
    "Un día más de entreno, un día menos para la meta.",
    "No te rindas, el casco te está esperando.",
    "La disciplina pesa onzas, el arrepentimiento toneladas.",
    "Nadie dijo que fuera fácil, pero valdrá la pena.",
    "El fuego no espera a los que no están preparados.",
    "Visualiza tu objetivo. Hoy estás un paso más cerca.",
    "Para apagar incendios mañana, tienes que quemar las ganas de rendirte hoy.",
    "Cada dominada suma, cada artículo de la ley te acerca al camión.",
    "Cuando te falte el aire subiendo la cuerda, piensa en por qué empezaste.",
    "Hacer lo que toca cuando no tienes ganas: ahí se ganan las plazas.",
    "El camino es duro, pero el destino es el mejor trabajo del mundo.",
    "Entrena como si fueras el segundo; compite como si fueras el primero.",
    "Tú pones el esfuerzo, el tiempo pondrá la plaza.",
    "No compites contra ellos, compites contra tu versión de ayer.",
    "La campana del parque sonará para ti. Sigue adelante.",
    "El miedo se combate con preparación. Estudia. Entrena. Vence.",
    "Los bomberos no nacen, se forjan a base de constancia.",
    "Que el dolor de las piernas hoy sea el orgullo de tu uniforme mañana.",
    "Menos excusas, más vueltas a la pista.",
    "Fuerza en las piernas, calma en la mente y fuego en el corazón.",
    "Nadie regala nada, cada bombero se ha ganado su casco a pulso.",
    "Si fuera fácil, todo el mundo sería bombero. Tú no eres todo el mundo.",
    "Cada simulacro fallado hoy es un error evitado el día del examen.",
    "Construye al bombero que llevas dentro, día a día, sin descanso.",
    "La oposición es una carrera de fondo. No frenes ahora.",
    "El éxito es la suma de pequeños esfuerzos repetidos día tras día.",
    "Rendirse no es una opción cuando hay vidas que dependerán de ti.",
    "Tu plaza tiene nombre y apellidos. Ve a por ella.",
    "El mejor momento para darlo todo es ahora mismo.",
    "Cabeza fría, cuerpo fuerte. Estás listo para lo que venga.",
    "Haz que valga la pena cada minuto de sacrificio."
  ];

  // Logica para que la frase cambie cada día
  static String obtenerFraseDelDia() {
    int diaActual = DateTime.now().day;
    return motivadoras[diaActual % motivadoras.length];
  }
}