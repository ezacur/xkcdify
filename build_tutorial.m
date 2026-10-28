%% Genera la documentación
% 1. Captura las dos interfaces (publish no las captura).
% 2. Genera las imágenes del README: doc/antes_despues.png y doc/xkcdify_gui.png.
% 3. Publica tutorial_xkcdify.m en una carpeta temporal.
% 4. Incrusta las imágenes en el HTML como data URIs (base64), de modo que
%    doc/tutorial_xkcdify.html es un único fichero sin dependencias.

repo = fileparts(mfilename('fullpath'));
docDir = fullfile(repo, 'doc');
tmpDir = tempname;
mkdir(tmpDir);
limpiar = onCleanup(@() rmdir(tmpDir, 's'));
if ~exist(docDir, 'dir')
    mkdir(docDir);
end

% Capturas de las interfaces, con la misma figura que la sección 1 del tutorial
close all force
hFig = figure('Color', 'w', 'Position', [100 100 640 420]);
x = linspace(0, 10, 200);
plot(x, sin(x), x, 0.5*cos(1.5*x), x, exp(-x/4) - 0.5);
grid on
xlabel('tiempo (s)');
ylabel('valor');
legend('sin(x)', '0.5 cos(1.5x)', 'e^{-x/4} - 0.5', 'Location', 'southwest');
title('Tres ondas');
hGui = xkcdify(hFig, 'Interfaz', true, 'TipoInterfaz', 'uifigure');
drawnow;
exportapp(hGui, fullfile(tmpDir, 'xkcdify_gui.png'));
copyfile(fullfile(tmpDir, 'xkcdify_gui.png'), docDir);
delete(hGui);

hGui = xkcdify(hFig, 'Interfaz', true, 'TipoInterfaz', 'figure');
drawnow;
fr = getframe(hGui);
imwrite(fr.cdata, fullfile(tmpDir, 'xkcdify_gui_clasica.png'));
delete(hGui);

% Antes -> después para el README: original, flecha y resultado
fr = getframe(hFig);
antes = double(fr.cdata) / 255;
despues = xkcdify(hFig, 'Amplitud', 1.5);
[alto, ~, ~] = size(antes);
[X, Y] = meshgrid(1:100, 1:alto);
yc = alto / 2;
flecha = inpolygon(X, Y, [15 60 60 88 60 60 15], yc + [-8 -8 -24 0 24 8 8]);
separador = repmat(1 - 0.65 * flecha, [1 1 3]);
imwrite([antes separador despues], fullfile(docDir, 'antes_despues.png'));
close all force

% La captura ya está en la carpeta de salida, donde <<xkcdify_gui.png>> la encuentra
publish(fullfile(repo, 'tutorial_xkcdify.m'), 'outputDir', tmpDir, 'showCode', true);
close all force

% Incrustar las imágenes. El HTML se trata como bytes para no alterar su
% codificación (los data URIs son ASCII).
html = char(leerBytes(fullfile(tmpDir, 'tutorial_xkcdify.html'))');
tokens = regexp(html, 'src="([^"]+\.png)"', 'tokens');
pngs = unique(cellfun(@(t) t{1}, tokens, 'UniformOutput', false));
for k = 1:numel(pngs)
    uri = ['data:image/png;base64,' matlab.net.base64encode(leerBytes(fullfile(tmpDir, pngs{k})))];
    html = strrep(html, ['src="' pngs{k} '"'], ['src="' uri '"']);
end

fid = fopen(fullfile(docDir, 'tutorial_xkcdify.html'), 'w');
fwrite(fid, double(html), 'uint8');
fclose(fid);
fprintf('Generado %s (%d imágenes incrustadas)\n', fullfile(docDir, 'tutorial_xkcdify.html'), numel(pngs));

function datos = leerBytes(fichero)
    fid = fopen(fichero, 'r');
    datos = fread(fid, Inf, 'uint8=>uint8');
    fclose(fid);
end
