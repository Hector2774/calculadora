# Calculadora (Flutter)

Calculadora sencilla para Android: sin anuncios, sin internet y sin permisos.

**Funciones:** suma, resta, multiplicación y división con jerarquía de operaciones,
porcentaje (200+10% = 220), cambio de signo, vista previa del resultado mientras
escribes, modo claro/oscuro automático.

- Mantén presionado **⌫** para borrar todo.
- Mantén presionada la **pantalla** para copiar el número.

## Estructura

```
lib/main.dart        Interfaz y lógica de las teclas
lib/evaluador.dart   Cálculo de las expresiones
test/widget_test.dart Pruebas
.github/workflows/   Compilación automática del APK en GitHub
```

La carpeta `android/` no se incluye: se genera con `flutter create` (paso 2 abajo).

---

## Opción A: compilar el APK en GitHub (no necesitas instalar nada)

1. Crea una cuenta gratis en github.com y un repositorio nuevo (puede ser privado).
2. Sube todos estos archivos, incluida la carpeta `.github` (botón *Add file → Upload files*,
   arrastra el contenido de la carpeta).
3. Ve a la pestaña **Actions**. La compilación arranca sola y tarda unos 5 minutos.
4. Al terminar (palomita verde), entra a la ejecución y descarga **calculadora-apk**
   en la sección *Artifacts*. Es un .zip que contiene `app-release.apk`.

## Opción B: compilar en tu computadora

1. Instala Flutter siguiendo https://docs.flutter.dev/get-started/install
   (incluye Android Studio). Verifica con `flutter doctor`.
2. Abre una terminal en esta carpeta y ejecuta:
   ```
   flutter create --platforms=android --org com.personal --project-name calculadora .
   flutter pub get
   flutter build apk --release
   ```
3. El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

Para probarla directamente con el teléfono conectado por USB (con depuración USB
activada): `flutter run`.

Opcional: para que el nombre bajo el ícono sea "Calculadora" con mayúscula, en
`android/app/src/main/AndroidManifest.xml` cambia `android:label="calculadora"`
por `android:label="Calculadora"`.

## Instalar el APK en el teléfono

1. Pasa el archivo `app-release.apk` al teléfono (cable, Drive, WhatsApp a ti mismo…).
2. Ábrelo desde el administrador de archivos.
3. Android te pedirá permitir **instalar apps de origen desconocido** para esa app;
   acéptalo y pulsa *Instalar*. Si Play Protect muestra un aviso, elige
   *Instalar de todas formas* (sale porque la app no viene de la Play Store).
