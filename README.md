# xkcdify

Efecto "dibujado a mano", al estilo de los cómics de [xkcd](https://xkcd.com), para figuras de MATLAB.

**Antes → después**

![Antes → después](doc/antes_despues.png)

La figura original no se modifica: `xkcdify` aplica unos retoques temporales (fuente cómic, grosores), captura la figura, la deja como estaba y deforma la captura con un campo de ruido suave.

## ¿Por qué?

A veces lo que queremos contar de un fenómeno no es su fórmula, sino su comportamiento: que algo crece y luego se satura, que tiene un máximo, que dos efectos compiten. Es una idea deliberadamente vaga, y en muchas ocasiones esa idea vaga importa más que cualquier expresión matemática concreta.

El problema es que una gráfica limpia, de líneas perfectas, sugiere justo lo contrario: que detrás hay una fórmula evaluada o unos datos medidos, y que los valores exactos significan algo. Transmite una precisión que no existe.

En esos casos creo que la figura debe ser *claramente* imprecisa. Lo que importa son la forma y las tendencias, no los números. Una curva temblorosa, más cerca de un dibujo en una servilleta que del `plot` de una fórmula, deja claro desde el primer vistazo que estamos hablando de una idea, no de una medida.

Por lo mismo, no es una herramienta para datos: si tienes medidas, enséñalas tal cual, con su precisión y sus barras de error. Disfrazar datos reales de dibujo a mano sería el error contrario, quitarles la precisión que sí tienen.

Ese es el objetivo de este repositorio, inspirado en los cómics "científicos" de [xkcd](https://xkcd.com): romper la idea de que toda curva es la materialización de una fórmula. Espero que te resulte útil, y que compartas la idea.

## Uso

```matlab
hFig = figure('Color', 'w');
x = linspace(0, 10, 200);
plot(x, sin(x), x, 0.5*cos(1.5*x));
xlabel('tiempo'); ylabel('valor'); legend('sin', 'cos'); title('Demo');

xkcdify(hFig);                              % abre la interfaz
img = xkcdify(hFig, 'Amplitud', 2);         % sin interfaz: devuelve la imagen
imwrite(img, 'demo_xkcd.png');
```

La interfaz permite ajustar el efecto en vivo y exportar el resultado:

![Interfaz de xkcdify](doc/xkcdify_gui.png)

| Parámetro      | Por defecto | Qué hace                                               |
|----------------|-------------|--------------------------------------------------------|
| `Sigma`        | 15          | Longitud de la ondulación (px)                         |
| `Amplitud`     | 1.2         | Desplazamiento típico de los píxeles (px)              |
| `GrosorLineas` | 2.5         | Grosor mínimo de las líneas de datos (0 = no tocar)    |
| `Fuente`       | `'auto'`    | Fuente de los textos: `'auto'`, `'ninguna'` o un nombre (ver [Fuentes](#fuentes)) |
| `RetocarEjes`  | `true`      | Engrosar los ejes y dibujarlos encima de los datos     |
| `Semilla`      | 1           | Semilla del ruido (misma semilla = misma imagen)       |
| `Interfaz`     | según salida | Abrir la interfaz (por defecto, solo si no se pide salida) |
| `TipoInterfaz` | `'auto'`    | `'uifigure'`, `'figure'` (clásica) o `'auto'`          |

## Instalación

```
git clone https://github.com/ezacur/xkcdify.git
```

o descarga el [ZIP](https://github.com/ezacur/xkcdify/archive/refs/heads/main.zip), y añade la carpeta al path de MATLAB con `addpath`. Después instala alguna fuente cómic con `instalar_fuentes` (ver [Fuentes](#fuentes)).

## Requisitos

- MATLAB, sin ninguna toolbox.
- La interfaz usa `uifigure` (R2021b o posterior). En versiones anteriores, en Octave o si `uifigure` falla, usa una interfaz clásica con `figure` y `uicontrol`.
- Opcional, pero recomendado: una fuente cómic (ver [Fuentes](#fuentes)).

## Fuentes

Con `Fuente = 'auto'` (por defecto), `xkcdify` usa la primera fuente instalada de esta lista **que tenga todos los caracteres de la figura**: si el título lleva una "ñ" y Humor Sans no la tiene, pasa a la siguiente. La interfaz muestra qué fuente ha elegido y por qué, y tiene un desplegable para elegirla a mano.

| Fuente | Estilo | Tildes y eñes | Licencia |
|---|---|---|---|
| [xkcd Script](https://github.com/ipython/xkcd-font) | la letra real de xkcd, con minúsculas | sí | CC BY-NC 3.0 (no comercial) |
| [Humor Sans](http://antiyawn.com/uploads/humorsans.html) | letra de xkcd, solo mayúsculas | **no** | gratuita |
| [Patrick Hand](https://fonts.google.com/specimen/Patrick+Hand) | manuscrita estrecha, muy legible | sí | SIL OFL |
| [Comic Neue](https://fonts.google.com/specimen/Comic+Neue) | Comic Sans "bien hecha" | sí | SIL OFL |
| [Architects Daughter](https://fonts.google.com/specimen/Architects+Daughter) | manuscrita, estilo de arquitecto | sí | SIL OFL |
| [Comic Relief](https://fonts.google.com/specimen/Comic+Relief) | parecida a Comic Sans | sí | SIL OFL |
| [Short Stack](https://fonts.google.com/specimen/Short+Stack) | redondeada y ancha | sí | SIL OFL |
| Comic Sans MS | viene con Windows | sí | — |

### Instalación automática

```matlab
instalar_fuentes                          % xkcd Script, Patrick Hand y Comic Neue
instalar_fuentes({'Humor Sans'})          % otras
instalar_fuentes('todas')
```

Descarga cada fuente de su origen oficial, comprueba que es una fuente y la instala:

- **Windows:** para todos los usuarios (`C:\Windows\Fonts`); Windows pide permiso de administrador. MATLAB **no** ve las fuentes instaladas solo para el usuario.
- **macOS:** en `~/Library/Fonts`.
- **Linux:** en `~/.local/share/fonts`, y ejecuta `fc-cache`.

Después, **reinicia MATLAB**.

### Instalación manual

Descarga el `.ttf` desde los enlaces de la tabla y:

- **Windows:** clic derecho en el fichero → **Instalar para todos los usuarios** (no vale "Instalar", que la instala solo para ti).
- **macOS:** doble clic → Instalar fuente.
- **Linux:** cópialo a `~/.local/share/fonts` y ejecuta `fc-cache -f`.

Y reinicia MATLAB. Para comprobarlo: `any(strcmpi(listfonts, 'xkcd Script'))`.

## Documentación

El tutorial completo, con ejemplos de cada parámetro, está en [`doc/tutorial_xkcdify.html`](doc/tutorial_xkcdify.html): es un único fichero; descárgalo y ábrelo en el navegador. Se genera desde [`tutorial_xkcdify.m`](tutorial_xkcdify.m) con `build_tutorial`.
