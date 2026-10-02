# Wealthy

[English](README.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [العربية](README.ar.md) · [Français](README.fr.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Русский](README.ru.md) · [Português](README.pt.md)

Wealthy es una aplicación para iPhone y iPad que registra gastos, ingresos y saldos de carteras. El escaneo de recibos, los resúmenes de gastos y la IA en el dispositivo ayudan a revisar tus finanzas.

## Funciones

- Registrar ingresos y gastos por cartera y categoría.
- Escanear recibos, revisar los detalles y conservar las imágenes originales.
- Consultar operaciones en un calendario y gastos por categoría.
- Aplicar movimientos mensuales recurrentes al abrir la aplicación.
- Preguntar sobre tus registros a Apple Foundation Models.
- Leer consejos breves con un toque de humor basados en ingresos, gastos y patrimonio registrados.
- Exportar y restaurar registros financieros, con imágenes de recibos opcionales.
- Registrar activos y operaciones en varias monedas, con saldos separados.


## Varias monedas

- Se admiten **155 monedas ISO 4217 activas**, según la lista de SIX publicada el 2026-09-17.
- En el primer inicio, después de elegir el idioma de la interfaz, selecciona una o más monedas para activar. En **Inicio → Ajustes**, puedes editar las monedas activas y elegir la moneda predeterminada para nuevas operaciones.
- Los activos y el historial de operaciones conservan la moneda guardada en cada registro. Los saldos se mantienen separados y Análisis permite cambiar entre las monedas activas. No se realiza conversión automática de divisas.
- Los importes se guardan en unidades menores ISO: JPY tiene 0 decimales, USD 2 y KWD 3. Los registros existentes siguen en JPY.
- El OCR de recibos no cambia: procesa texto japonés e inglés y extrae automáticamente importes enteros en JPY. Los importes en moneda extranjera deben introducirse y revisarse manualmente.

## Métodos de pago y tarjetas de puntos

El recibo propone la cartera correspondiente al método de pago impreso; sin indicación se usa Efectivo. Al confirmar se descuenta una sola vez. Si falta la cartera, se crea con saldo cero y queda negativa, por ejemplo `¥0 → ¥-1,200`. Editar o eliminar un registro ajusta el saldo. Varios métodos, puntos canjeados o varias carteras coincidentes requieren revisión manual. Son reglas sobre texto OCR; no se ha medido la precisión del método de pago en fotografías.

En **Carteras**, edita una cartera creada automáticamente para establecer su saldo actual o regístrala con un saldo inicial que se suma al saldo registrado. Las tarjetas de puntos admiten nombre, número de socio opcional, saldo y caducidad opcional. Los puntos se introducen manualmente, se separan de los activos monetarios y se incluyen en las copias financieras.

La sincronización automática con bancos y servicios de pago **no está implementada**. Las primeras integraciones propuestas son SBI Shinsei Bank y DOCOMO SMTB Net Bank (antes SBI Sumishin Net Bank). Abrir una aplicación bancaria no permite leer su saldo; se requiere un servicio aprobado de acceso a cuentas. Consulta la [evaluación de integración](Documentation/FinancialServiceIntegration.md).

## Requisitos

Se requiere **iOS o iPadOS 26.0 o posterior** y un **dispositivo compatible con Apple Intelligence**. Apple Intelligence debe estar activado y su modelo del sistema preparado para usar la aplicación.

| Dispositivo | Hardware compatible |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, modelos iPhone 16 y posteriores, o iPhone Air |
| iPad | Modelos con M1 o posterior, o iPad mini con A17 Pro |

También se aplican las restricciones de idioma y región de Apple. Wealthy comprueba la disponibilidad del modelo al iniciarse y volver al primer plano. Consulta los [requisitos actuales de Apple](https://www.apple.com/apple-intelligence/).

## Uso

1. Activa Apple Intelligence en **Ajustes → Apple Intelligence y Siri** y espera a que el modelo esté preparado.
2. Elige uno de los **11 idiomas de interfaz** en el diálogo inicial. El inglés es el predeterminado; se guarda tu elección. Puedes cambiarla en **Inicio → Ajustes → Ajustes de idioma**. La interfaz árabe se muestra de derecha a izquierda.
3. Elige una o más monedas para activar. Después puedes cambiar las monedas activas y la moneda predeterminada de nuevas operaciones en **Inicio → Ajustes**.
4. Añade una cartera y registra ingresos o escanea un recibo. Revisa los detalles antes de guardar.
5. Consulta Calendario y Análisis, o abre el asistente de IA para preguntar sobre tus registros.

Los idiomas de interfaz son inglés, japonés, chino simplificado, hindi, español, árabe, francés, indonesio, coreano, ruso y portugués. La lista corresponde a la interfaz y a estas versiones del README; no implica que el modelo de Apple instalado admita los 11 idiomas.

## IA en el dispositivo

El chat, la extracción complementaria de recibos y los comentarios breves de gastos usan **SystemLanguageModel**, integrado por Apple. El sistema operativo gestiona el modelo y sus actualizaciones. No hay modelos alternativos ni pantallas de descarga o selección, ni conexiones a Private Cloud Compute u otro proveedor de IA en la nube.

El chat solicita una respuesta en el idioma del último mensaje, independientemente de la interfaz. Si no puede determinar el idioma, usa el de la interfaz. Los idiomas admitidos dependen del modelo de Apple instalado. Un idioma de chat no compatible genera un mensaje explícito: prueba uno admitido por el modelo. Los comentarios de gastos solicitan el idioma de interfaz y combinan una broma generada por IA con una acción basada en tus registros; si la generación falla, se usa un consejo local.

## Registros, recibos y copias de seguridad

Los registros financieros y las imágenes se guardan en el dispositivo. En **Inicio → Ajustes → Gestión de datos**, exporta carteras, ingresos, gastos, movimientos recurrentes y categorías a JSON. Un diálogo muestra el tamaño de las imágenes referenciadas y permite incluirlas o exportar solo registros. Las imágenes compartidas se incluyen una sola vez. La codificación JSON aumenta el tamaño de los datos de imagen aproximadamente un **33%**.

La restauración reemplaza los registros actuales. Las copias con imágenes restauran los datos originales; las copias solo de registros no restauran imágenes. Los formatos anteriores siguen siendo legibles, pero se ignora su historial de chat. Colecciones grandes de imágenes pueden necesitar mucha memoria al exportar o restaurar.

**Ninguna exportación incluye el historial de chat.** Los mensajes caducan **24 horas** después de su creación. Wealthy borra los caducados mientras está activo y comprueba al iniciarse o volver al primer plano. Si iOS suspende o cierra la aplicación, se borran cuando vuelva a ejecutarse. Los mensajes caducados se excluyen de la pantalla y del contexto de IA.

El OCR de recibos se orienta a **texto japonés e inglés**. La extracción automática de importes admite **yenes japoneses enteros**; otras monedas requieren entrada manual. Importes y fechas proceden del analizador OCR, no de suposiciones de IA. Se usa la fecha impresa legible; en caso contrario, la del regreso del escaneo de cámara, antes del reconocimiento, marcada para revisión. Se reutiliza una categoría apropiada o se crea una nueva cuando es necesario. Todos los detalles extraídos son editables.

En una medición en un iPhone 16 Pro Max con iOS 27.2 usando las mismas **15 imágenes de desarrollo**, los totales JPY coincidieron en **6/10** casos legibles; los otros cuatro quedaron sin confirmar. Las fechas impresas coincidieron en **14/14** y las categorías híbridas en **14/14 muestras etiquetadas**; la tasa de error de caracteres de las líneas seleccionadas se mantuvo en **11.22%**. Estas imágenes también se usaron durante el desarrollo: no son resultados independientes ni estimaciones de precisión para recibos nuevos. Consulta el [informe de medición](Verification/ReceiptImageOCR/RESULTS.md) para los resultados históricos de macOS, exclusiones y detalles. Revisa siempre antes de guardar.

## Compilar desde el código fuente

Usa Xcode con el **SDK de iOS 26 o posterior**. Las compilaciones de desarrollo se comprueban con **Xcode 27.0**. Abre `Wealthy/Wealthy.xcodeproj`, selecciona el esquema **Wealthy**, configura tu equipo de firma y ejecuta en un iPhone o iPad compatible. Se usan frameworks del sistema de Apple sin dependencias externas de paquetes Swift.

Las comprobaciones en un iPhone 16 Pro Max con iOS 27.2 confirmaron las respuestas de IA en japonés e inglés, además de las operaciones locales de gastos, carteras y tarjetas de puntos, y el diálogo de copia de seguridad. Otros dispositivos y los flujos de trabajo no probados siguen sin verificarse. Consulta las [instrucciones de verificación](Verification/README.md).

La **versión preliminar v0.1.1** incluye el código fuente descrito aquí. No incluye una aplicación firmada para descargar; revise los límites de verificación antes de compilar.

## Licencia

Todos los derechos reservados. La redistribución del código fuente o de los binarios requiere permiso.
