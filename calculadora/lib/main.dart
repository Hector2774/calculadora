import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'evaluador.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CalculadoraApp());
}

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // sigue el modo claro/oscuro del teléfono
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const PantallaCalculadora(),
    );
  }
}

enum TipoTecla { numero, funcion, operador, igual }

class Tecla {
  const Tecla(
    this.etiqueta,
    this.tipo,
    this.accion, {
    this.icono,
    this.alMantener,
  });

  final String etiqueta;
  final TipoTecla tipo;
  final VoidCallback accion;
  final IconData? icono;
  final VoidCallback? alMantener;
}

class PantallaCalculadora extends StatefulWidget {
  const PantallaCalculadora({super.key});

  @override
  State<PantallaCalculadora> createState() => _PantallaCalculadoraState();
}

class _PantallaCalculadoraState extends State<PantallaCalculadora> {
  static const _operadores = ['+', '−', '×', '÷'];
  static const _maxDigitos = 15;

  String _expresion = '';
  String _vistaPrevia = '';
  bool _error = false;
  bool _recienCalculado = false;

  // ---------- Utilidades sobre la expresión ----------

  bool _esOperador(String c) => _operadores.contains(c);

  String get _ultimo =>
      _expresion.isEmpty ? '' : _expresion[_expresion.length - 1];

  /// Posición donde empieza el número que se está escribiendo.
  int get _inicioNumeroActual {
    var i = _expresion.length;
    while (i > 0 && !_esOperador(_expresion[i - 1])) {
      i--;
    }
    return i;
  }

  String get _numeroActual => _expresion.substring(_inicioNumeroActual);

  String _sinOperadoresFinales(String e) {
    var r = e;
    while (r.isNotEmpty && _esOperador(r[r.length - 1])) {
      r = r.substring(0, r.length - 1);
    }
    return r;
  }

  /// Después de "=": un número empieza una cuenta nueva y un operador
  /// continúa con el resultado.
  void _prepararEntrada({required bool continuar}) {
    if (!_recienCalculado) return;
    _recienCalculado = false;
    if (!continuar || _expresion.contains('e')) _expresion = '';
  }

  // ---------- Acciones de las teclas ----------

  void _digito(String d) {
    _prepararEntrada(continuar: false);
    if (_ultimo == '%') return;
    final n = _numeroActual;
    if (n.replaceAll('.', '').length >= _maxDigitos) return;
    if (n == '0') {
      _expresion = _expresion.substring(0, _expresion.length - 1) + d;
    } else {
      _expresion += d;
    }
  }

  void _punto() {
    _prepararEntrada(continuar: false);
    final n = _numeroActual;
    if (n.contains('.') || n.contains('%')) return;
    _expresion += n.isEmpty ? '0.' : '.';
  }

  void _operador(String op) {
    _prepararEntrada(continuar: true);
    if (_expresion.isEmpty) {
      if (op == '−') _expresion = '−';
      return;
    }
    if (_esOperador(_ultimo)) {
      // Permite números negativos después de × o ÷ (ej. 5×−2).
      if (op == '−' && (_ultimo == '×' || _ultimo == '÷')) {
        _expresion += op;
        return;
      }
      _expresion = _sinOperadoresFinales(_expresion);
      if (_expresion.isEmpty) {
        if (op == '−') _expresion = '−';
        return;
      }
    }
    _expresion += op;
  }

  void _porcentaje() {
    _prepararEntrada(continuar: true);
    final n = _numeroActual;
    if (n.isEmpty || n == '.' || n.contains('%')) return;
    _expresion += '%';
  }

  void _cambiarSigno() {
    _prepararEntrada(continuar: true);
    if (_expresion.isEmpty) {
      _expresion = '−';
      return;
    }
    final i = _inicioNumeroActual;
    if (i == _expresion.length) return; // no hay número que cambiar

    final antes = i > 0 ? _expresion[i - 1] : '';
    final esMenosUnario =
        antes == '−' && (i - 1 == 0 || _esOperador(_expresion[i - 2]));

    if (esMenosUnario) {
      _expresion = _expresion.substring(0, i - 1) + _expresion.substring(i);
    } else if (antes == '−') {
      _expresion = '${_expresion.substring(0, i - 1)}+${_expresion.substring(i)}';
    } else if (antes == '+') {
      _expresion = '${_expresion.substring(0, i - 1)}−${_expresion.substring(i)}';
    } else {
      _expresion = '${_expresion.substring(0, i)}−${_expresion.substring(i)}';
    }
  }

  void _borrar() {
    if (_recienCalculado) {
      _recienCalculado = false;
      if (_expresion.contains('e')) _expresion = '';
    }
    if (_expresion.isNotEmpty) {
      _expresion = _expresion.substring(0, _expresion.length - 1);
    }
  }

  void _limpiarTodo() {
    _expresion = '';
    _recienCalculado = false;
  }

  void _igual() {
    HapticFeedback.selectionClick();
    final limpia = _sinOperadoresFinales(_expresion);
    if (limpia.isEmpty || _recienCalculado) return;
    setState(() {
      try {
        _expresion = Evaluador.formatear(Evaluador.evaluar(limpia));
        _vistaPrevia = '';
        _error = false;
        _recienCalculado = true;
      } on FormatException catch (e) {
        _vistaPrevia = e.message;
        _error = true;
      }
    });
  }

  /// Muestra el resultado mientras se escribe.
  void _actualizarVistaPrevia() {
    _error = false;
    _vistaPrevia = '';
    if (_recienCalculado || _expresion.isEmpty) return;
    final hayOperacion = _expresion.contains(RegExp('[+×÷%]')) ||
        _expresion.lastIndexOf('−') > 0;
    if (!hayOperacion) return;
    final limpia = _sinOperadoresFinales(_expresion);
    if (limpia.isEmpty) return;
    try {
      _vistaPrevia = Evaluador.formatear(Evaluador.evaluar(limpia));
    } on FormatException {
      // Expresión incompleta o división entre 0: no se muestra nada aún.
    }
  }

  void _pulsar(VoidCallback accion) {
    HapticFeedback.selectionClick();
    setState(() {
      accion();
      _actualizarVistaPrevia();
    });
  }

  void _copiar() {
    final texto = (!_error && _vistaPrevia.isNotEmpty) ? _vistaPrevia : _expresion;
    if (texto.isEmpty) return;
    Clipboard.setData(ClipboardData(text: texto.replaceAll('−', '-')));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Copiado: $texto'),
        duration: const Duration(seconds: 1),
      ));
  }

  // ---------- Interfaz ----------

  List<List<Tecla>> get _teclado {
    Tecla n(String d) => Tecla(d, TipoTecla.numero, () => _pulsar(() => _digito(d)));
    Tecla op(String o) =>
        Tecla(o, TipoTecla.operador, () => _pulsar(() => _operador(o)));

    return [
      [
        Tecla('AC', TipoTecla.funcion, () => _pulsar(_limpiarTodo)),
        Tecla('borrar', TipoTecla.funcion, () => _pulsar(_borrar),
            icono: Icons.backspace_outlined,
            alMantener: () => _pulsar(_limpiarTodo)),
        Tecla('%', TipoTecla.funcion, () => _pulsar(_porcentaje)),
        op('÷'),
      ],
      [n('7'), n('8'), n('9'), op('×')],
      [n('4'), n('5'), n('6'), op('−')],
      [n('1'), n('2'), n('3'), op('+')],
      [
        Tecla('±', TipoTecla.numero, () => _pulsar(_cambiarSigno)),
        n('0'),
        Tecla('.', TipoTecla.numero, () => _pulsar(_punto)),
        Tecla('=', TipoTecla.igual, _igual),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 3, child: _pantalla(cs)),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  children: [
                    for (final fila in _teclado)
                      Expanded(
                        child: Row(
                          children: [
                            for (final t in fila)
                              Expanded(child: BotonTecla(tecla: t)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pantalla(ColorScheme cs) {
    return GestureDetector(
      onLongPress: _copiar, // mantener presionado para copiar
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _expresion.isEmpty ? '0' : _expresion,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 68,
                  fontWeight: FontWeight.w300,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _vistaPrevia.isEmpty ? ' ' : _vistaPrevia,
                maxLines: 1,
                style: TextStyle(
                  fontSize: _error ? 22 : 32,
                  color: _error ? cs.error : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BotonTecla extends StatelessWidget {
  const BotonTecla({super.key, required this.tecla});

  final Tecla tecla;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, texto) = switch (tecla.tipo) {
      TipoTecla.numero => (cs.surfaceContainerHighest, cs.onSurface),
      TipoTecla.funcion => (cs.secondaryContainer, cs.onSecondaryContainer),
      TipoTecla.operador => (cs.primaryContainer, cs.onPrimaryContainer),
      TipoTecla.igual => (cs.primary, cs.onPrimary),
    };
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: fondo,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tecla.accion,
          onLongPress: tecla.alMantener,
          child: Center(
            child: tecla.icono != null
                ? Icon(tecla.icono, color: texto, size: 28,
                    semanticLabel: tecla.etiqueta)
                : Text(
                    tecla.etiqueta,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: texto,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
