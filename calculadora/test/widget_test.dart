import 'package:calculadora/evaluador.dart';
import 'package:calculadora/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String calc(String e) => Evaluador.formatear(Evaluador.evaluar(e));

  group('Evaluador', () {
    test('operaciones básicas y jerarquía', () {
      expect(calc('2+3×4'), '14');
      expect(calc('10÷4'), '2.5');
      expect(calc('0.1+0.2'), '0.3');
      expect(calc('7−10'), '−3');
      expect(calc('5×−2'), '−10');
      expect(calc('5−−3'), '8');
    });

    test('porcentaje estilo calculadora de teléfono', () {
      expect(calc('50%'), '0.5');
      expect(calc('200+10%'), '220');
      expect(calc('200−25%'), '150');
      expect(calc('80×50%'), '40');
    });

    test('errores', () {
      expect(() => Evaluador.evaluar('5÷0'), throwsFormatException);
      expect(() => Evaluador.evaluar('×5'), throwsFormatException);
    });
  });

  testWidgets('la app arranca y suma', (tester) async {
    await tester.pumpWidget(const CalculadoraApp());
    await tester.tap(find.text('7'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('8'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('15'), findsOneWidget);
  });
}
