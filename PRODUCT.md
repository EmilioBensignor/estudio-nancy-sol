# Product

## Register

product

## Users

**Nancy y Sol**, dos socias de un estudio de arquitectura/construcción. Usan la app en escritorio (Excel actual) y eventualmente celu. Contexto: gestión real de obras, no marketing. Van a operar la herramienta todos los días para registrar ingresos, gastos, retiros y seguimiento de rentabilidad. No son técnicas, pero tampoco novatas — manejan Excel hace años.

## Product Purpose

Reemplazar un Excel Workbook de gestión de obras de construcción/renovación. La app debe:
- Gestionar múltiples obras simultáneamente (multi-obra desde el día 1)
- Soportar bimoneda ARS/USD con tipo de cambio por transacción
- Calcular ganancia cobrada y distribución 50/50 entre socias
- Registrar retiros y mostrar convergencia hacia el target
- Exportar columnas F-K para clientes (formato imprimible)
- Ser robusta: cero fragilidad de fórmulas (todo Postgres views)

## Brand Personality

Profesional y cálido. No frío-corporativo ni startup-tech. El nombre del estudio es "Nancy Sol" — proyecto compartido entre dos personas, no una empresa grande.

Palabras clave: **orden, claridad, confianza, calidez**.

Tono de interfaz: directo, sin adornos innecesarios. Cada elemento justifica su lugar.

## Anti-references

- No landing pages ni hero metrics
- No dashboards con 15 cards iguales en grid
- No gradientes de colores ni glassmorphism
- No modales como primera opción
- No "AI slop" — interfaces que se notan generadas
- No Excel-feel: la app no debe parecer una hoja de cálculo
- No filas de tabla sin jerarquía visual clara

## Design Principles

1. **Claridad sobre decoración** — cada elemento existe porque resuelve algo, no porque "queda bien". Si no aporta info, no está.

2. **Autoexplicarse sin instrucciones** — la UI debe guiarse por contexto visual (badges, color, posición, peso). No tooltips largos ni textos explicativos redundantes.

3. **Confianza numérica** — los números son el producto. El formatting de moneda, la alineación de decimales y la jerarquía de importes deben ser impecables. Error unacceptable: un número que parece otra cosa.

4. **Progresión natural** — el flujo va de lo más usado (caja, movimientos) a lo menos (configuración, exportación). Las acciones del día a día son inmediatas; las secundarias requieren un clic más.

5. **Fallas visibles y claras** — si falta un TC, si un retiro excede disponible, si una obra no tiene rubro, se ve. No silencios.

## Accessibility & Inclusion

- Contraste AA mínimo en todos los textos
- Interacciones reachable con teclado
- No animaciones que dificulten lectura para personas con sensibilidades al movimiento
- Soporte para lectores de pantalla en labels y estructura de tablas