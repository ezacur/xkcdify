%% Tutorial de xkcdify
% |xkcdify| convierte una figura de MATLAB en una imagen con aspecto
% "dibujado a mano", al estilo de los cómics de <https://xkcd.com xkcd>:
% líneas que tiemblan, ejes ondulados y letra de cómic.
%
% La figura original nunca se modifica. |xkcdify| aplica unos retoques
% temporales (fuente, grosores...), captura la figura como imagen, la deja
% como estaba y deforma la captura con un campo de ruido suave.
%
% Hay dos formas de usarlo:
%
% * *Con interfaz*: |xkcdify(hFig)| abre una ventana con sliders para
%   ajustar el efecto en vivo y exportar el resultado.
% * *Sin interfaz*: |img = xkcdify(hFig, ...)| devuelve directamente la
%   imagen, para usarlo en scripts.
%
% La versión HTML de este tutorial (|doc/tutorial_xkcdify.html|, un único
% fichero con las imágenes incrustadas) se genera con |build_tutorial|.

%% Descarga
% El código está en GitHub: <https://github.com/ezacur/xkcdify>
%
% * Con git: |git clone https://github.com/ezacur/xkcdify.git|
% * Sin git, en ZIP:
%   <https://github.com/ezacur/xkcdify/archive/refs/heads/main.zip>
%
% Basta con añadir la carpeta al path de MATLAB (|addpath|). Para usarlo
% solo hace falta |xkcdify.m|; |demo_xkcdify.m| es un ejemplo rápido.

%% Requisitos
% * MATLAB R2021b o posterior (usa |uifigure|, |uislider| y |uiimage|).
% * *Image Processing Toolbox* (|padarray| e |imgaussfilt|).
% * Opcional: la fuente *Humor Sans*, la letra de xkcd. Si está instalada
%   (para todos los usuarios, en |C:\Windows\Fonts|), |xkcdify| la usa
%   automáticamente. Si no, prueba con xkcd Script, xkcd, Comic Neue y
%   Comic Sans MS, en ese orden.

fuentes = {'Humor Sans', 'xkcd Script', 'xkcd', 'Comic Neue', 'Comic Sans MS'};
instaladas = fuentes(ismember(lower(fuentes), lower(listfonts)))

%% 1. Una figura normal
% Partimos de una gráfica cualquiera, hecha como siempre:

close all
hFig = figure('Color', 'w', 'Position', [100 100 640 420]);
x = linspace(0, 10, 200);
plot(x, sin(x), x, 0.5*cos(1.5*x), x, exp(-x/4) - 0.5);
grid on
xlabel('tiempo (s)');
ylabel('valor');
legend('sin(x)', '0.5 cos(1.5x)', 'e^{-x/4} - 0.5', 'Location', 'southwest');
title('Tres ondas');

%% 2. Con interfaz: xkcdify(hFig)
% Llamando a |xkcdify| sin pedir ninguna salida se abre la interfaz:
%
%   xkcdify(hFig);
%
% <<xkcdify_gui.png>>
%
% Los controles son:
%
% * *Sigma (longitud de onda)*: cuánto miden las ondulaciones, en píxeles.
%   Valores bajos dan un temblor nervioso; valores altos, curvas amplias.
% * *Amplitud (temblor)*: cuánto se desplazan los píxeles, también en
%   píxeles. 0 desactiva la deformación.
% * *Grosor mínimo de líneas*: engrosa las líneas de datos que sean más
%   finas que este valor (0 = no tocarlas). Las líneas finas se ven mal al
%   deformarlas.
% * *Fuente cómic*: cambia todos los textos a la fuente cómic encontrada.
% * *Retocar ejes*: engrosa los ejes (mínimo 1.5) y los dibuja encima de
%   los datos (|Layer = 'top'|).
% * *Nueva semilla*: sortea otro patrón de ruido.
% * *Recapturar figura*: vuelve a capturar si has cambiado la figura
%   original después de abrir la interfaz.
% * *Exportar...*: guarda el resultado en PNG, JPG o TIF, al mismo tamaño
%   que la figura.
%
% Sigma y Amplitud se actualizan en vivo mientras arrastras, porque solo
% deforman la captura que ya existe. La fuente, los retoques y el grosor
% necesitan volver a capturar la figura, así que se aplican al soltar.
%
% Si cierras la figura original, la interfaz se cierra con ella. Para
% recuperar el handle de la interfaz:
%
%   hGui = xkcdify(hFig, 'Interfaz', true);

%% 3. Sin interfaz: img = xkcdify(hFig)
% Si se pide una salida, |xkcdify| no abre ninguna ventana: devuelve la
% imagen RGB (|double| entre 0 y 1), del mismo tamaño que la figura.
%
% (|figuraNueva|, al final del tutorial, crea una figura y oculta las
% anteriores para que no se repitan en cada sección. |xkcdify| funciona
% igual con figuras ocultas.)

img = xkcdify(hFig);
size(img)

figuraNueva(640, 420);
imshow(img, 'Border', 'tight');

%% 4. Parámetros
% Todos los parámetros se pasan como pares nombre-valor, igual en los dos
% modos (con interfaz fijan los valores iniciales de los controles):
%
% <html>
% <table border="1" cellpadding="4" style="border-collapse:collapse">
% <tr><th>Parámetro</th><th>Por defecto</th><th>Qué hace</th></tr>
% <tr><td>Sigma</td><td>15</td><td>Longitud de la ondulación (px)</td></tr>
% <tr><td>Amplitud</td><td>1.2</td><td>Desplazamiento típico de los píxeles (px)</td></tr>
% <tr><td>GrosorLineas</td><td>2.5</td><td>Grosor mínimo de las líneas de datos (0 = no tocar)</td></tr>
% <tr><td>FuenteComic</td><td>true</td><td>Cambiar los textos a la fuente cómic</td></tr>
% <tr><td>RetocarEjes</td><td>true</td><td>Engrosar los ejes y dibujarlos encima</td></tr>
% <tr><td>Semilla</td><td>1</td><td>Semilla del ruido</td></tr>
% <tr><td>Interfaz</td><td>según la salida</td><td>true abre la interfaz; por defecto, solo si no se pide salida</td></tr>
% </table>
% </html>
%
% En la interfaz, Sigma va de 2 a 40, Amplitud de 0 a 5 y GrosorLineas de
% 0 a 6. Sin interfaz no hay límites.

%% 4.1 Amplitud: cuánto tiembla
% Con la misma Sigma, la amplitud controla la intensidad del efecto:

amplitudes = [0.5 1.2 3];
imgs = arrayfun(@(a) xkcdify(hFig, 'Amplitud', a), amplitudes, 'UniformOutput', false);
mostrar(imgs, compose('Amplitud = %.1f px', amplitudes));

%% 4.2 Sigma: cómo de larga es la onda
% Con la misma amplitud (aquí 2 px para que se note), Sigma cambia el
% carácter del trazo. Sigma pequeña da un temblor fino, como un pulso
% nervioso; Sigma grande da curvas suaves y amplias:

sigmas = [4 15 35];
imgs = arrayfun(@(s) xkcdify(hFig, 'Sigma', s, 'Amplitud', 2), sigmas, 'UniformOutput', false);
mostrar(imgs, compose('Sigma = %d px', sigmas));

%% 4.3 Retoques: fuente, ejes y grosor
% Los retoques hacen que el resultado parezca de verdad un dibujo. Aquí
% el mismo efecto con y sin ellos:

sinRetoques = xkcdify(hFig, 'FuenteComic', false, 'RetocarEjes', false, 'GrosorLineas', 0);
conRetoques = xkcdify(hFig);
mostrar({sinRetoques, conRetoques}, {'Sin retoques', 'Con retoques (por defecto)'});

%%
% Los retoques son temporales: la figura original sigue intacta.

ax = findobj(hFig, 'Type', 'axes');
fprintf('Fuente de los ejes: %s, grosor: %.1f\n', ax.FontName, ax.LineWidth);

%% 5. Semilla: resultados reproducibles
% El ruido se genera a partir de |Semilla|, así que la misma semilla da
% siempre exactamente la misma imagen y otra semilla da otro trazo. Así se
% puede volver a generar una figura igual para un informe:

a = xkcdify(hFig, 'Semilla', 1);
b = xkcdify(hFig, 'Semilla', 1);
c = xkcdify(hFig, 'Semilla', 2);
fprintf('Semilla 1 dos veces: %s\n', mat2str(isequal(a, b)));
fprintf('Semilla 1 frente a 2: %s\n', mat2str(isequal(a, c)));

%%
% En la interfaz, el botón *Nueva semilla* sortea otra y la muestra en la
% barra de estado. Si te gusta un resultado, apunta la semilla para
% reproducirlo sin interfaz.

%% 6. Exportar
% Con interfaz, el botón *Exportar...*. Sin interfaz, |imwrite|:
%
%   img = xkcdify(hFig, 'Amplitud', 2, 'Semilla', 42);
%   imwrite(img, 'mi_grafica_xkcd.png');
%
% La imagen tiene la misma resolución que la figura en pantalla. Para una
% imagen más grande, agranda la figura antes (|hFig.Position|).

%% 7. Otros tipos de gráfica
% Funciona con cualquier cosa que se vea en la figura: barras, superficies,
% colorbars, varios ejes...

hBar = figuraNueva(640, 420);
tiledlayout(hBar, 1, 2);
nexttile
bar([3 5 2 6; 4 2 5 3]', 'grouped');
title('Ventas'); xlabel('trimestre'); legend('2025', '2026');
nexttile
surf(peaks(25)); colorbar
title('peaks');

imgBar = xkcdify(hBar);
figuraNueva(640, 420);
imshow(imgBar, 'Border', 'tight');

%% 8. Cómo funciona por dentro
% Para cada imagen, |xkcdify| hace:
%
% # *Retoques temporales*: guarda el valor (y el modo |...Mode|) de cada
%   propiedad que va a cambiar y aplica la fuente cómic y los grosores.
% # *Captura*: |getframe| de la figura.
% # *Restaurar*: devuelve cada propiedad a su valor y modo originales, en
%   orden inverso. Va dentro de un |onCleanup|, así que se restaura aunque
%   falle la captura.
% # *Borde*: añade un margen blanco para que la deformación no corte los
%   bordes.
% # *Campo de desplazamientos*: dos campos de ruido aleatorio (uno para X
%   y otro para Y), suavizados con un filtro gaussiano de radio |Sigma| y
%   normalizados para que su desviación típica sea |Amplitud| píxeles.
% # *Deformar*: cada píxel se toma de su posición desplazada (|interp2|).
% # *Recortar*: se quita el margen.
%
% Este es el aspecto de uno de esos campos de desplazamiento (en X), con
% los valores por defecto. Son "manchas" suaves de unos |Sigma| píxeles,
% con valores de pocos píxeles:

s = RandStream('mt19937ar', 'Seed', 1);
ruido = 2 * rand(s, 420, 640) - 1;
dx = imgaussfilt(ruido, 15, 'Padding', 'circular');
dx = 1.2 * dx / std(dx(:));

figuraNueva(640, 420);
imagesc(dx, [-4 4]); axis image off
colormap(gca, turbo); cb = colorbar; cb.Label.String = 'desplazamiento en X (px)';
title('Campo de desplazamiento (Sigma = 15, Amplitud = 1.2)');

%% 9. Limitaciones
% * El resultado es una *imagen*, no una figura editable. Si cambias la
%   gráfica, vuelve a llamar a |xkcdify| (o pulsa *Recapturar figura*).
% * La resolución es la de la figura en pantalla.
% * Humor Sans solo tiene mayúsculas: todos los textos salen en
%   mayúsculas, como en xkcd.
% * Humor Sans *no tiene tildes ni eñes*: "gráfica" sale como "GRFICA".
%   Escribe los textos sin tildes o desactiva *Fuente cómic* (Comic Sans
%   MS sí las tiene).
% * MATLAB solo ve las fuentes instaladas para todos los usuarios, y hay
%   que reiniciarlo después de instalar una fuente.

%% Limpieza
% Cerramos todas las figuras del tutorial, también las ocultas.

close all

%% Funciones auxiliares del tutorial
% |figuraNueva| crea una figura blanca del tamaño indicado, cierra las que
% creó antes y oculta las demás. |mostrar| enseña en fila el mismo recorte
% de varias imágenes, a tamaño real (las diferencias son de pocos píxeles
% y al reducir se perderían).

function h = figuraNueva(ancho, alto)
    close(findall(groot, 'Type', 'figure', 'Tag', 'tutorialXkcdify'));
    set(findall(groot, 'Type', 'figure'), 'Visible', 'off');
    h = figure('Color', 'w', 'Position', [100 100 ancho alto], 'Tag', 'tutorialXkcdify');
end

function mostrar(imgs, titulos)
    filas = 60:290;
    cols  = 40:330;
    figuraNueva((numel(cols) + 20) * numel(imgs), numel(filas) + 40);
    t = tiledlayout(1, numel(imgs), 'TileSpacing', 'tight', 'Padding', 'tight');
    for k = 1:numel(imgs)
        nexttile(t);
        imshow(imgs{k}(filas, cols, :));
        title(titulos{k});
    end
end
