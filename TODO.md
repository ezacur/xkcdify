# TODO: ideas abiertas

Ideas para llevar `xkcdify` más allá de MATLAB. Están libres: si te apetece hacer alguna, adelante (un issue o un pull request avisando ayuda a no duplicar trabajo).

## 1. Una herramienta independiente de MATLAB

`plt.xkcd()` (matplotlib), el paquete `xkcd` de R, [rough.js](https://roughjs.com) o [chart.xkcd](https://timqian.com/chart.xkcd/) dan el aspecto "dibujado a mano", pero **dentro** de su propia librería de gráficas: hay que hacer la figura con ellos. Lo que falta es una herramienta que acepte **cualquier figura ya hecha** (MATLAB, Excel, Origin, PowerPoint, el PDF de un artículo...) y la convierta en un dibujo de servilleta.

### 1.1 Entrada SVG (la más interesante)

Deformar la **geometría**, no los píxeles: aplicar el mismo campo de desplazamiento suave que usa `xkcdify` a las coordenadas de los trazos.

- El resultado sigue siendo vectorial: nítido a cualquier tamaño, exportable a PDF.
- El texto sigue siendo texto: cambiar la fuente es cambiar `font-family`, sin OCR. Se puede reutilizar la elección automática de fuente según los caracteres.
- Un único campo para toda la figura mantiene la coherencia: dos curvas que se cruzan siguen cruzándose en el mismo punto, y ejes, marcas y rejilla se mueven juntos. (`plt.xkcd()` hace temblar cada trazo por separado y esa coherencia se pierde).

Dificultades conocidas:

- **Subdividir** los trazos antes de deformarlos: un eje es un segmento de dos puntos y, si solo se desplazan los extremos, sigue recto.
- **Aplanar** el SVG: transformaciones anidadas, grupos, `clipPath`.
- **Texto convertido en trazos**: matplotlib lo hace por defecto (`svg.fonttype='path'`). Ahí no hay texto que cambiar; avisar al usuario de que exporte el texto como texto.
- **Imágenes incrustadas** (mapas de color, `imagesc`): deformarlas como imagen.
- **Marcadores** (círculos, cruces): mejor desplazarlos enteros que deformarlos.

### 1.2 Entrada PNG

- **Deformar:** ya funciona con el algoritmo actual (campo de ruido suavizado + `interp2`). Es portarlo.
- **Cambiar las fuentes con OCR** (opcional, más adelante): detectar el texto (p. ej. Tesseract), borrarlo rellenando el fondo (*inpainting*) y volver a escribirlo con una fuente cómic. Problemas: etiquetas en vertical, superíndices, texto sobre la rejilla o las curvas.

### 1.3 Forma: mejor web que ejecutable

- **Página web estática** (p. ej. en GitHub Pages): el navegador maneja SVG de forma nativa, los sliders en vivo son triviales y la deformación de PNG con WebGL es instantánea. Sin instalación: arrastrar el fichero y descargar el resultado. Todo se procesa en el navegador, sin subir la figura a ningún servidor.
- **Línea de comandos** para procesar en lote, compartiendo la lógica (Node), o en Python (`svgelements`, `numpy`, `Pillow`), empaquetable como ejecutable con PyInstaller.
- La función de MATLAB se mantiene para quien trabaje dentro de MATLAB.

**Licencias de las fuentes:** una web pública que sirva las fuentes las está redistribuyendo. xkcd Script es CC BY-NC 3.0 (no comercial); por defecto, mejor fuentes SIL OFL (Patrick Hand, Comic Neue...), que permiten redistribuirlas.

### Orden sugerido

1. Prototipo web con SVG (lo más incierto), probado con figuras exportadas desde MATLAB y matplotlib.
2. PNG en la misma web (portar el algoritmo actual).
3. Versión de línea de comandos.
4. OCR para PNG, solo si hace falta.

## 2. Pendientes de la versión de MATLAB

- **Probar en Octave.** La interfaz clásica y el procesado están preparados para Octave (sin `RandStream`, sin toolboxes, sin `obj.Prop` en handles), pero no se han probado.
- **Resolución de exportación:** ahora es la de la figura en pantalla. Capturar con `print -RGBImage -rN` y escalar Sigma y Amplitud en proporción.
- **Licencia** del repositorio.
