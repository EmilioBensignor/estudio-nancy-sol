# Design System: Estudio Nancy Sol

## 1. Overview

**Creative North Star:** *"El Registro" — la precisión de un cuaderno de arquitectura profesional, donde cada cifra tiene peso y cada decisión está asentada.*

Sistema de gestión para dos socias que operan todos los días. La interfaz es un utensilio de trabajo, no un producto de marketing. Cada elemento existe porque resuelve algo: información clara, números legibles, acciones obvias. Lo que no aporta se remove. Lo que queda es confianza.

La calidez viene del color terracota sobre fondo crema, no de decorations. La estructura viene de la tipografía y el espaciado, no de sombras ni bordes decorativos. La jerarquía viene del peso y tamaño, no del color.

### Key Characteristics:

- **Números primero.** Los montos son el producto. Formato correcto, alineación impecable, jerarquía clara entre importe y label.
- **Contexto visual constante.** Badges de color para tipos de movimiento, iconos para estados, peso tipográfico para jerarquía de datos.
- **Nada de Excel.** La app no parece una hoja de cálculo. Tablas con personalidad, no filas idénticas sin jerarquía.
- **Superficies planas.** Sin sombras decorativas. La profundidad viene de bordes, capas tonales y espaciado.

## 2. Colors

**La paleta es crema + ink + terracota. Sin más.** Tres roles, tres colores. El terracota es la voz activa de la interfaz; el ink es la estructura; el crema es el aire.

### Primary

- **Terracota activo** (`#C45C26`): Acciones principales, elementos seleccionados, énfasis. Toda interacción que requiere atención del usuario usa este color.
- **Terracota hover** (`#A84B1E`): Estado hover del primario. Transición suave.
- **Terracota sutil** (`#FBF0EB`): Background de superficies que承载 información destacada. Tint areal, no bulk.

### Neutral

- **Crema base** (`#FAFAF8`): Background principal de la app. No blanco puro, no gris.
- **Surface** (`#FFFFFF`): Tarjetas, tablas, inputs. Blanco sobre crema.
- **Surface raised** (`#F5F4F0`): Áreas elevadas dentro de componentes. Alternancia sutil de filas.
- **Border** (`#E5E2DA`): Bordes de componentes. Más visible que el sutil.
- **Border subtle** (`#EEECE6`): Divisores dentro de componentes, separaciones ligeras.
- **Ink** (`#1C1B19`): Texto principal, números, títulos. No negro puro — tiene calidez.
- **Ink muted** (`#6B6860`): Labels secundarios, metadata, hints.
- **Ink faint** (`#A8A59D`): Placeholders, texto deshabilitado.

### Semantic

- **Positive** (`#2D7D46`): Ingresos, cobrado, disponible. Texto sobre fondo `positive-bg`.
- **Positive bg** (`#EDFAF2`): Background para badges y filas positivas.
- **Negative** (`#C4281E`): Egresos, pagos, montos negativos. Texto sobre fondo `negative-bg`.
- **Negative bg** (`#FEF0EE`): Background para alertas de pago.
- **Warning** (`#92640A`): Retiros, alertas, estados que requieren atención.
- **Warning bg** (`#FEF9EC`): Background para advertencias suaves.

**The Three-Color Rule.** Terracota / Ink / Cream. No hay más. Si algo necesita un cuarto color, está mal diseñado.

## 3. Typography

**Fonts:** DM Sans (body, UI) + DM Mono (cifras, números, montos). La combinación es profesional pero cálida — el mono no parece código, parece cifra contable.

### Display / App Title

- **Font:** DM Sans, 700 weight
- **Size:** 20px, letter-spacing: -0.3px
- **Purpose:** Títulos de página, nombres de obra en header

### Headline / Section

- **Font:** DM Sans, 600 weight
- **Size:** 13px, uppercase, letter-spacing: 0.06em
- **Purpose:** Labels de sección, badges de estado

### Body / UI Text

- **Font:** DM Sans, 400 weight
- **Size:** 14px, line-height: 1.5
- **Purpose:** Texto de interfaz, labels de form, contenido de celdas

### Label / Meta

- **Font:** DM Sans, 500 weight
- **Size:** 12px, uppercase, letter-spacing: 0.05em
- **Purpose:** Labels de campos de formulario, metadata

### Numeric / Mono

- **Font:** DM Mono, 500 weight (valores), 400 weight (labels)
- **Size:** 13px
- **Purpose:** Todos los montos de dinero, TC, percentages. Siempre monospace para alineación de decimales.

**The Clarity Rule.** La jerarquía entre título, label y valor es por peso y tamaño, no por color. El ink muted se usa solo para texto que no es el dato principal.

## 4. Elevation

**Flat by default.** Sin sombras en estado de reposo. La profundidad se construye con:

1. **Bordes** — los componentes tienen border de 1px en `border`. Cuando algo se eleva, el borde se hace más presente.
2. **Capas tonales** — la alternancia de `surface` y `surface-raised` crea ritmo sin sombras.
3. **Espaciado** — la distancia entre elementos comunica jerarquía mejor que cualquier sombra.

### Shadow Vocabulary

- **Shadow sm** (`0 1px 2px rgba(28,27,25,0.06)`): Solo para elementos que necesitan浮抬 ephemeral (dropdowns, tooltips).
- **Shadow** (`0 2px 8px rgba(28,27,25,0.08)`): Cards con interacción que requiere relieve (obra cards con hover).

**The Flat Rule.** Ningún componente tiene sombra en estado default. Hover es el único momento donde la elevación aparece, y es leve.

## 5. Components

### Buttons

- **Shape:** Radius 6px (`var(--radius-sm)`). Sin bordes redondeados excesivos.
- **Primary:** Background terracota, texto blanco, height 38px, padding 0 16px. Font 13px, weight 600. Hover: background terracota hover.
- **Ghost:** Background transparent, border 1px `border`, color `ink-muted`. Hover: background `surface-raised`.
- **Text:** Sin background, color terracota, height auto. Para acciones dentro de contenido (no como CTA).
- **Disabled:** Opacity 0.45. Sin otras modificaciones.

### Cards / Containers

- **Corner Style:** Radius 10px (`var(--radius)`) para cards, 14px (`var(--radius-lg)`) para forms.
- **Background:** `surface` (blanco) o `surface-raised` (alternancia).
- **Border:** 1px `border` en todos los casos. No hay card sin borde.
- **Internal Padding:** 16px–22px según densidad de información.

### Table

- **Header:** Background `surface-raised`, texto `ink-muted`, uppercase, 11px, weight 600, letter-spacing 0.05em. Border-bottom 1px `border`.
- **Row:** Padding 10px 14px, border-bottom 1px `border-subtle`. Hover: background rgba(28,27,25,0.015).
- **Cells:** Texto 13px, alineación según tipo (números a derecha, texto a izquierda).
- **Badge cells:** El badge no tiene borde, tiene background de color semantic con texto del mismo color.

### Badges

- **Shape:** Radius 99px (completamente redondeado).
- **Size:** 11px, weight 600, padding 2px 8px.
- **Variants:** `cobro` (positive-bg/positive), `pago` (negative-bg/negative), `retiro` (warning-bg/warning).

### Form Inputs

- **Style:** Height 38px, padding 0 10px, border 1px `border`, radius 6px. Background `surface`.
- **Focus:** Border terracota, box-shadow 0 0 0 3px rgba(196,92,38,0.1). Sin outline default.
- **Placeholder:** Color `ink-faint`.
- **Select:** Mismo estilo, appearance none, flecha nativa removida.

### KPI Strip

- **Layout:** 4 columnas iguales, gap 10px. Responsive: 2 columnas en mobile.
- **Card:** Background `surface`, border 1px `border`, radius `var(--radius)`, padding 16px 18px.
- **Label:** 11px, uppercase, letter-spacing 0.06em, color `ink-muted`.
- **Value:** 22px, weight 700, letter-spacing -0.5px. Color según sémana (positive/negative/accent).

### Progress Bar

- **Track:** Height 6px, background `border`, radius 99px.
- **Fill:** Height 100%, radius 99px, background según owner (ink para Nancy, terracota para Sol). Transition width 500ms ease-out-quint.

### Info Callout

- **Shape:** Radius `var(--radius)`, padding 10px 14px.
- **Background:** `surface-raised`.
- **Border:** 1px `border`.
- **Content:** Icono SVG 16px + texto 13px, color `ink-muted`.

## 6. Do's and Don'ts

### Do:

- **Do** usar DM Mono para todo monto de dinero. Siempre. Sin excepciones.
- **Do** alinear los números a derecha en tablas y KPI strips. El ojo debe encontrar la columna de un vistazo.
- **Do** usar badges de color para tipos de movimiento (cobro/pago/retiro). Son el primer nivel de escaneo de la tabla.
- **Do** mantener el header de la app simple: nombre de la obra, nombre del cliente, estado. Nada de tabs ni navegación compleja.
- **Do** usar el crema (#FAFAF8) como background de la app. No blanco puro.
- **Do** mantener las acciones primarias a la derecha en layouts de formulario.
- **Do** mostrar el TC cuando es relevante: al lado del monto USD, no solo en el detalle.

### Don't:

- **Don't** usar gradientes de color en backgrounds ni texto.
- **Don't** usar glassmorphism ni blur effects decorativos.
- **Don't** usar shadow en estado default de ningún componente.
- **Don't** hacer grids de cards idénticas con icono + título + texto repetidos.
- **Don't** usar modales para errores o confirmaciones simples — usar inline warnings.
- **Don't** mostrar más de 4 KPIs en una strip sin jerarquía clara de importancia.
- **Don't** usar labels de columna en uppercase mezclados con valores en sentence case — consistencia en todo.
- **Don't** dejar espacios vacíos que no significan nada — si no hay dato, se muestra vacío con propósito, no como placeholder.
- **Don't** usar bordes de 2px o más como decoration — borders son 1px máximo.
- **Don't** hacer que la UI parezca Excel — sin filas sin color, sin celdas sin espaciado, sin Headers en mayúscula sin contexto.