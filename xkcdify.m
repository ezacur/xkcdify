function varargout = xkcdify(hFig, varargin)
%XKCDIFY  Interfaz para dar a una figura el aspecto "dibujado a mano" de xkcd.
%
%   xkcdify(hFig) abre una ventana con controles para ajustar el efecto sobre
%   la figura hFig (por defecto gcf). La figura original no se modifica: en
%   cada cambio se aplican temporalmente los retoques (fuente, grosores...),
%   se captura el frame y se restauran las propiedades originales.
%
%   xkcdify(hFig, 'Sigma', 15, 'Amplitud', 1.2, ...) fija los valores iniciales.
%
%   img = xkcdify(hFig, ...) no abre la interfaz: aplica el efecto con los
%   parámetros indicados y devuelve la imagen RGB (double 0-1), lista para
%   imwrite. Sin interfaz, Sigma, Amplitud y GrosorLineas no se limitan al
%   rango de los sliders.
%
%   hGui = xkcdify(hFig, 'Interfaz', true, ...) abre la interfaz y devuelve
%   su uifigure.
%
%   Parámetros:
%     Sigma         - longitud de la ondulación (px). Mayor = ondas más largas.
%     Amplitud      - desplazamiento típico de los píxeles (px).
%     GrosorLineas  - grosor mínimo de las líneas de datos (0 = no tocar).
%     FuenteComic   - true para cambiar todas las fuentes a una tipo cómic.
%     RetocarEjes   - true para engrosar los ejes y dibujarlos encima (Layer top).
%     Semilla       - semilla del ruido (mismo valor = misma deformación).
%     Interfaz      - true abre la interfaz. Por defecto: true si no se pide
%                     salida, false si se pide (img = xkcdify(...)).
%
%   Ejemplo:
%     hFig = figure('Color','w');
%     x = linspace(0,10,200);
%     plot(x, sin(x), x, 0.5*cos(1.5*x));
%     xlabel('tiempo'); ylabel('valor'); legend('sin','cos'); title('Demo');
%     xkcdify(hFig);                              % interfaz
%     img = xkcdify(hFig, 'Amplitud', 2);         % directo, sin interfaz
%     imwrite(img, 'demo_xkcd.png');

    if nargin < 1 || isempty(hFig)
        hFig = gcf;
    end

    % Rangos de los sliders
    LIM_SIGMA    = [2 40];
    LIM_AMPLITUD = [0 5];
    LIM_GROSOR   = [0 6];

    p = inputParser;
    p.addParameter('Sigma',        15,   @(v) isscalar(v) && v > 0);
    p.addParameter('Amplitud',     1.2,  @(v) isscalar(v) && v >= 0);
    p.addParameter('GrosorLineas', 2.5,  @(v) isscalar(v) && v >= 0);
    p.addParameter('FuenteComic',  true, @(v) isscalar(v));
    p.addParameter('RetocarEjes',  true, @(v) isscalar(v));
    p.addParameter('Semilla',      1,    @(v) isscalar(v) && v >= 0);
    p.addParameter('Interfaz',     nargout == 0, @(v) isscalar(v));
    p.parse(varargin{:});
    opts = p.Results;

    fuenteComic = buscarFuenteComic();
    if isempty(fuenteComic)
        opts.FuenteComic = false;
    end

    %% SIN INTERFAZ: capturar, deformar y devolver la imagen
    if ~opts.Interfaz
        img = deformar(capturarFigura(hFig, opts, fuenteComic), opts, []);
        if nargout > 0
            varargout{1} = img;
        else
            figure('Name', 'xkcdify');
            imshow(img);
        end
        return
    end

    opts.Sigma        = limitar(opts.Sigma,        LIM_SIGMA);
    opts.Amplitud     = limitar(opts.Amplitud,     LIM_AMPLITUD);
    opts.GrosorLineas = limitar(opts.GrosorLineas, LIM_GROSOR);

    % Estado compartido por las funciones anidadas
    frame   = [];   % captura de la figura (double 0-1)
    ruido   = [];   % ruido base, fijo para una semilla (ver deformar)
    result  = [];   % imagen final

    %% INTERFAZ
    if isempty(hFig.Number)
        nombreFig = hFig.Name;
    else
        nombreFig = sprintf('Figura %d', hFig.Number);
    end
    hGui = uifigure('Name', ['xkcdify - ' nombreFig], ...
        'Position', [100 100 1000 560]);
    g = uigridlayout(hGui, [1 2]);
    g.ColumnWidth = {270, '1x'};

    pnl = uipanel(g, 'Title', 'Parámetros');
    gc = uigridlayout(pnl, [12 1]);
    gc.RowHeight = [repmat({'fit'}, 1, 11) {'1x'}];

    lblSigma = uilabel(gc);
    sldSigma = uislider(gc, 'Limits', LIM_SIGMA, 'Value', opts.Sigma, ...
        'MajorTicks', [2 10 20 30 40], 'MinorTicks', 2:2:40, ...
        'ValueChangingFcn', @(~,e) cambiarDistorsion('Sigma', e.Value), ...
        'ValueChangedFcn',  @(s,~) cambiarDistorsion('Sigma', s.Value));

    lblAmplitud = uilabel(gc);
    sldAmplitud = uislider(gc, 'Limits', LIM_AMPLITUD, 'Value', opts.Amplitud, ...
        'MajorTicks', 0:5, 'MinorTicks', 0:0.25:5, ...
        'ValueChangingFcn', @(~,e) cambiarDistorsion('Amplitud', e.Value), ...
        'ValueChangedFcn',  @(s,~) cambiarDistorsion('Amplitud', s.Value));

    lblGrosor = uilabel(gc);
    sldGrosor = uislider(gc, 'Limits', LIM_GROSOR, 'Value', opts.GrosorLineas, ...
        'MajorTicks', 0:6, 'MinorTicks', 0:0.5:6, ...
        'ValueChangingFcn', @(~,e) actualizarEtiquetas('GrosorLineas', e.Value), ...
        'ValueChangedFcn',  @(s,~) cambiarCaptura('GrosorLineas', s.Value));

    if isempty(fuenteComic)
        txtFuente = 'Fuente cómic (no hay ninguna instalada)';
    else
        txtFuente = ['Fuente cómic (' fuenteComic ')'];
    end
    chkFuente = uicheckbox(gc, 'Text', txtFuente, 'Value', opts.FuenteComic, ...
        'Enable', ~isempty(fuenteComic), ...
        'ValueChangedFcn', @(s,~) cambiarCaptura('FuenteComic', s.Value));
    uicheckbox(gc, 'Text', 'Retocar ejes (grosor, Layer top)', ...
        'Value', opts.RetocarEjes, ...
        'ValueChangedFcn', @(s,~) cambiarCaptura('RetocarEjes', s.Value));

    uibutton(gc, 'Text', 'Nueva semilla', 'ButtonPushedFcn', @(~,~) nuevaSemilla());
    uibutton(gc, 'Text', 'Recapturar figura', 'ButtonPushedFcn', @(~,~) cambiarCaptura());
    uibutton(gc, 'Text', 'Exportar...', 'ButtonPushedFcn', @(~,~) exportar());
    lblEstado = uilabel(gc, 'FontColor', [0.4 0.4 0.4], 'WordWrap', 'on');

    imgResultado = uiimage(g, 'ScaleMethod', 'scaledown');

    % Cerrar la interfaz si se cierra la figura original
    lst = addlistener(hFig, 'ObjectBeingDestroyed', @(~,~) delete(hGui));
    hGui.CloseRequestFcn = @(s,~) cerrar(s);

    actualizarEtiquetas();
    capturar();
    distorsionar();

    if nargout > 0
        varargout{1} = hGui;
    end

    %% CALLBACKS
    function cambiarDistorsion(nombre, valor)
        % Sigma y Amplitud: solo se vuelve a deformar la captura existente
        opts.(nombre) = valor;
        actualizarEtiquetas();
        distorsionar();
    end

    function cambiarCaptura(nombre, valor)
        % Fuente, retoques y grosores: hay que volver a capturar la figura
        if nargin > 0
            opts.(nombre) = valor;
        end
        actualizarEtiquetas();
        capturar();
        distorsionar();
    end

    function nuevaSemilla()
        opts.Semilla = randi(1e6);
        distorsionar();
    end

    function actualizarEtiquetas(nombre, valor)
        if nargin > 0
            opts.(nombre) = valor;
        end
        lblSigma.Text    = sprintf('Sigma (longitud de onda): %.1f px', opts.Sigma);
        lblAmplitud.Text = sprintf('Amplitud (temblor): %.2f px', opts.Amplitud);
        if opts.GrosorLineas > 0
            lblGrosor.Text = sprintf('Grosor mínimo de líneas: %.1f', opts.GrosorLineas);
        else
            lblGrosor.Text = 'Grosor mínimo de líneas: sin cambios';
        end
    end

    function exportar()
        [f, d] = uiputfile({'*.png', 'PNG'; '*.jpg', 'JPEG'; '*.tif', 'TIFF'}, ...
            'Exportar imagen xkcd', 'xkcd.png');
        figure(hGui);   % uiputfile deja la interfaz detrás
        if isequal(f, 0)
            return
        end
        imwrite(result, fullfile(d, f));
        lblEstado.Text = ['Exportado: ' fullfile(d, f)];
    end

    function cerrar(s)
        delete(lst);
        delete(s);
    end

    %% PROCESADO
    function capturar()
        frame = capturarFigura(hFig, opts, fuenteComic);
    end

    function distorsionar()
        if isempty(frame)
            return
        end
        t = tic;
        [result, ruido] = deformar(frame, opts, ruido);
        imgResultado.ImageSource = im2uint8(result);
        lblEstado.Text = sprintf('%d x %d px · semilla %d · %.0f ms', ...
            size(result, 2), size(result, 1), opts.Semilla, 1000 * toc(t));
    end
end

%% FUNCIONES LOCALES
function frame = capturarFigura(hFig, opts, fuenteComic)
% 1. Aplicar retoques temporales, 2. capturar, 3. restaurar
    cambios = aplicarRetoques(hFig, opts, fuenteComic);
    restaurar = onCleanup(@() restaurarPropiedades(cambios));
    drawnow;
    fr = getframe(hFig);
    clear restaurar   % restaura ya (y también si getframe falla)
    drawnow;
    frame = double(fr.cdata) / 255;
end

function [result, ruido] = deformar(frame, opts, ruido)
% Deforma la captura con un campo de ruido suave. ruido guarda el ruido base
% para reutilizarlo: con la misma semilla y tamaño, mover un slider solo
% cambia lo que se toca y el dibujo no "salta".

    % Borde blanco para que la deformación no corte los bordes
    % (fijo hasta 5 px de amplitud, para que el ruido no cambie de tamaño)
    pad = max(40, ceil(8 * opts.Amplitud));
    imgPad = padarray(frame, [pad pad], 1, 'both');
    [rows, cols, ~] = size(imgPad);

    if isempty(ruido) || ruido.Semilla ~= opts.Semilla || ~isequal(size(ruido.X), [rows cols])
        s = RandStream('mt19937ar', 'Seed', opts.Semilla);
        ruido.Semilla = opts.Semilla;
        ruido.X = 2 * rand(s, rows, cols) - 1;
        ruido.Y = 2 * rand(s, rows, cols) - 1;
    end

    % Suavizar y normalizar para que la Amplitud sea en píxeles. Relleno
    % circular: con 'replicate' (el defecto) el borde repetido crea
    % desplazamientos enormes en la orilla.
    smoothX = imgaussfilt(ruido.X, opts.Sigma, 'Padding', 'circular');
    smoothY = imgaussfilt(ruido.Y, opts.Sigma, 'Padding', 'circular');
    dx = opts.Amplitud * smoothX / std(smoothX(:));
    dy = opts.Amplitud * smoothY / std(smoothY(:));

    % Remuestrear cada canal en las coordenadas "temblorosas"
    [X, Y] = meshgrid(1:cols, 1:rows);
    imgDistorted = zeros(size(imgPad));
    for k = 1:3
        imgDistorted(:,:,k) = interp2(X, Y, imgPad(:,:,k), ...
            X + dx, Y + dy, 'linear', 1);
    end

    result = imgDistorted(pad+1:end-pad, pad+1:end-pad, :);
end

function cambios = aplicarRetoques(hFig, opts, fuenteComic)
% Aplica los retoques y devuelve lo necesario para deshacerlos:
% cada fila es {objeto, propiedad, valor original, modo original}
    cambios = cell(0, 4);

    if opts.FuenteComic && ~isempty(fuenteComic)
        cambios = fijar(cambios, findall(hFig, '-property', 'FontName'), ...
            'FontName', fuenteComic);
    end

    if opts.RetocarEjes
        cambios = fijar(cambios, findall(hFig, 'Type', 'axes'), ...
            'LineWidth', @(v) max(v, 1.5));
        cambios = fijar(cambios, findall(hFig, 'Type', 'axes'), 'Layer', 'top');
        cambios = fijar(cambios, findall(hFig, 'Type', 'colorbar'), ...
            'LineWidth', @(v) max(v, 1.5));
        cambios = fijar(cambios, findall(hFig, 'Type', 'legend'), ...
            'LineWidth', @(v) max(v, 1));
    end

    if opts.GrosorLineas > 0
        tipos = {'line', 'errorbar', 'stair', 'functionline', ...
            'implicitfunctionline', 'parameterizedfunctionline'};
        objs = findall(hFig, '-property', 'LineWidth');
        objs = objs(ismember(arrayfun(@(o) o.Type, objs, 'UniformOutput', false), tipos));
        cambios = fijar(cambios, objs, 'LineWidth', @(v) max(v, opts.GrosorLineas));
    end
end

function cambios = fijar(cambios, objs, prop, nuevo)
% Cambia prop en objs guardando el valor y el modo originales.
% nuevo puede ser un valor o una función (valor actual -> valor nuevo).
    for k = 1:numel(objs)
        o = objs(k);
        actual = get(o, prop);
        if isa(nuevo, 'function_handle')
            v = nuevo(actual);
        else
            v = nuevo;
        end
        if isequal(actual, v)
            continue
        end
        modo = [];
        if isprop(o, [prop 'Mode'])
            modo = get(o, [prop 'Mode']);
        end
        cambios(end+1, :) = {o, prop, actual, modo}; %#ok<AGROW>
        set(o, prop, v);
    end
end

function restaurarPropiedades(cambios)
% Deshace los cambios en orden inverso, restaurando también los ...Mode
    for k = size(cambios, 1):-1:1
        [o, prop, valor, modo] = cambios{k, :};
        if ~isvalid(o)
            continue
        end
        set(o, prop, valor);
        if ~isempty(modo)
            set(o, [prop 'Mode'], modo);
        end
    end
end

function nombre = buscarFuenteComic()
% Primera fuente tipo cómic instalada ('' si no hay ninguna)
    candidatas = {'Humor Sans', 'xkcd Script', 'xkcd', 'Comic Neue', 'Comic Sans MS'};
    disponibles = lower(listfonts);
    idx = find(ismember(lower(candidatas), disponibles), 1);
    if isempty(idx)
        nombre = '';
    else
        nombre = candidatas{idx};
    end
end

function v = limitar(v, lim)
    v = min(max(v, lim(1)), lim(2));
end
