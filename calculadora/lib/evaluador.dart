/// Evalúa expresiones como "12+3×4", "200+10%" o "5×−2".
///
/// Usa los símbolos que se muestran en pantalla (− × ÷) y respeta la
/// jerarquía de operaciones (× y ÷ antes que + y −).
///
/// El porcentaje funciona como en las calculadoras de teléfono:
///   50%      → 0.5
///   200+10%  → 220   (suma el 10 % de 200)
///   200−25%  → 150
///   80×50%   → 40
class Evaluador {
  Evaluador._();

  static double evaluar(String expresion) {
    final texto = expresion
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-');
    if (texto.isEmpty) throw const FormatException('Expresión vacía');

    final parser = _Parser(texto);
    final valor = parser.expresion();
    if (!parser.fin) throw const FormatException('Expresión inválida');
    return valor;
  }

  /// Convierte el número a texto: sin ".0" sobrante, sin errores de
  /// redondeo visibles (0.1+0.2 → "0.3") y con el signo − de la pantalla.
  static String formatear(double v) {
    if (v.isNaN || v.isInfinite) {
      throw const FormatException('Resultado no válido');
    }
    var s = (v == v.truncateToDouble() && v.abs() < 1e15)
        ? v.toInt().toString()
        : v.toStringAsPrecision(12);
    s = _quitarCerosSobrantes(s);
    return s.replaceAll('-', '−');
  }

  static String _quitarCerosSobrantes(String s) {
    final partes = s.split('e');
    var mantisa = partes[0];
    if (mantisa.contains('.')) {
      mantisa = mantisa
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return partes.length == 2 ? '${mantisa}e${partes[1]}' : mantisa;
  }
}

/// Analizador descendente recursivo:
///   expresion := termino (('+' | '-') termino)*
///   termino   := factor  (('*' | '/') factor)*
///   factor    := ('-' | '+') factor | numero '%'*
class _Parser {
  _Parser(this.s);

  final String s;
  int i = 0;

  // Indican si el último factor/término leído era un porcentaje "suelto",
  // para que 200+10% se interprete como 200 + (10 % de 200).
  bool _ultimoFactorPct = false;
  bool _terminoEsPct = false;

  bool get fin => i >= s.length;

  double expresion() {
    var v = termino();
    while (!fin && (s[i] == '+' || s[i] == '-')) {
      final op = s[i++];
      final d = termino();
      final base = _terminoEsPct ? v * d : d;
      v = op == '+' ? v + base : v - base;
    }
    return v;
  }

  double termino() {
    var v = factor();
    var unSoloFactor = true;
    while (!fin && (s[i] == '*' || s[i] == '/')) {
      unSoloFactor = false;
      final op = s[i++];
      final d = factor();
      if (op == '/') {
        if (d == 0) throw const FormatException('No se puede dividir entre 0');
        v /= d;
      } else {
        v *= d;
      }
    }
    _terminoEsPct = unSoloFactor && _ultimoFactorPct;
    return v;
  }

  double factor() {
    if (!fin && s[i] == '-') {
      i++;
      return -factor();
    }
    if (!fin && s[i] == '+') {
      i++;
      return factor();
    }
    var v = numero();
    var pct = false;
    while (!fin && s[i] == '%') {
      i++;
      v /= 100;
      pct = true;
    }
    _ultimoFactorPct = pct;
    return v;
  }

  double numero() {
    final inicio = i;
    while (!fin && '0123456789.'.contains(s[i])) {
      i++;
    }
    if (inicio == i) throw const FormatException('Expresión inválida');
    final valor = double.tryParse(s.substring(inicio, i));
    if (valor == null) throw const FormatException('Número inválido');
    return valor;
  }
}
