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
%   su ventana.
%
%   La interfaz usa uifigure (MATLAB R2021b o posterior). Si no está
%   disponible (MATLAB anterior u Octave) o falla, usa una figure clásica con
%   uicontrol. No requiere ninguna toolbox.
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
%     TipoInterfaz  - 'auto' (por defecto: uifigure si se puede, si no
%                     figure), 'uifigure' o 'figure'.
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
    p.addParameter('TipoInterfaz', 'auto', @(v) any(strcmpi(v, {'auto', 'uifigure', 'figure'})));
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
    % ui ofrece lo mismo con uifigure o con figure clásica:
    %   ui.fig                      ventana
    %   ui.etiqueta(nombre, texto)  texto sobre un slider ('Sigma', ...)
    %   ui.imagen(img)              muestra el resultado
    %   ui.estado(texto)            barra de estado
    titulo = ['xkcdify - ' nombreFigura(hFig)];
    if isempty(fuenteComic)
        txtFuente = 'Fuente cómic (no hay ninguna instalada)';
    else
        txtFuente = ['Fuente cómic (' fuenteComic ')'];
    end

    tipo = lower(opts.TipoInterfaz);
    if strcmp(tipo, 'auto') && ~hayUifigure()
        tipo = 'figure';
    end
    ui = [];
    if ~strcmp(tipo, 'figure')
        try
            ui = crearUifigure();
        catch err
            if strcmp(tipo, 'uifigure')
                rethrow(err);
            end
            warning('xkcdify:uifigure', ...
                'No se pudo crear la interfaz con uifigure (%s). Se usa figure.', err.message);
        end
    end
    if isempty(ui)
        ui = crearFigureClasica();
    end

    % Cerrar la interfaz si se cierra la figura original (en Octave no hay
    % este evento: los callbacks comprueban que la figura siga existiendo)
    lst = [];
    try
        lst = addlistener(hFig, 'ObjectBeingDestroyed', @(~,~) cerrar());
    catch
    end
    set(ui.fig, 'CloseRequestFcn', @(~,~) cerrar());

    actualizarEtiquetas();
    capturar();
    distorsionar();

    if nargout > 0
        varargout{1} = ui.fig;
    end

    %% CONSTRUCCIÓN DE LA INTERFAZ
    function u = crearUifigure()
        hGui = uifigure('Name', titulo, 'Position', [100 100 1000 560]);
        try
            g = uigridlayout(hGui, [1 2]);
            g.ColumnWidth = {270, '1x'};

            pnl = uipanel(g, 'Title', 'Parámetros');
            gc = uigridlayout(pnl, [12 1]);
            gc.RowHeight = [repmat({'fit'}, 1, 11) {'1x'}];

            lbl.Sigma = uilabel(gc);
            uislider(gc, 'Limits', LIM_SIGMA, 'Value', opts.Sigma, ...
                'MajorTicks', [2 10 20 30 40], 'MinorTicks', 2:2:40, ...
                'ValueChangingFcn', @(~,e) cambiarDistorsion('Sigma', e.Value), ...
                'ValueChangedFcn',  @(s,~) cambiarDistorsion('Sigma', s.Value));

            lbl.Amplitud = uilabel(gc);
            uislider(gc, 'Limits', LIM_AMPLITUD, 'Value', opts.Amplitud, ...
                'MajorTicks', 0:5, 'MinorTicks', 0:0.25:5, ...
                'ValueChangingFcn', @(~,e) cambiarDistorsion('Amplitud', e.Value), ...
                'ValueChangedFcn',  @(s,~) cambiarDistorsion('Amplitud', s.Value));

            lbl.GrosorLineas = uilabel(gc);
            uislider(gc, 'Limits', LIM_GROSOR, 'Value', opts.GrosorLineas, ...
                'MajorTicks', 0:6, 'MinorTicks', 0:0.5:6, ...
                'ValueChangingFcn', @(~,e) actualizarEtiquetas('GrosorLineas', e.Value), ...
                'ValueChangedFcn',  @(s,~) cambiarCaptura('GrosorLineas', s.Value));

            uicheckbox(gc, 'Text', txtFuente, 'Value', opts.FuenteComic, ...
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
        catch err
            delete(hGui);
            rethrow(err);
        end

        u.fig      = hGui;
        u.etiqueta = @(nombre, texto) set(lbl.(nombre), 'Text', texto);
        u.imagen   = @(img) set(imgResultado, 'ImageSource', uint8(round(255 * img)));
        u.estado   = @(texto) set(lblEstado, 'Text', texto);
    end

    function u = crearFigureClasica()
        % HandleVisibility off: que plot() y gcf no apunten a la interfaz
        fig = figure('Name', titulo, 'NumberTitle', 'off', 'MenuBar', 'none', ...
            'ToolBar', 'none', 'HandleVisibility', 'off', 'IntegerHandle', 'off', ...
            'Position', [100 100 1000 560]);
        pnl = uipanel('Parent', fig, 'Title', 'Parámetros', 'Units', 'pixels');
        fondo = get(pnl, 'BackgroundColor');
        texto = @(t) uicontrol('Parent', pnl, 'Style', 'text', 'String', t, ...
            'HorizontalAlignment', 'left', 'BackgroundColor', fondo);

        lbl.Sigma = texto('');
        sldSigma = crearSlider(pnl, LIM_SIGMA, opts.Sigma, [1 5], ...
            @(v) cambiarDistorsion('Sigma', v), @(v) cambiarDistorsion('Sigma', v));
        lbl.Amplitud = texto('');
        sldAmplitud = crearSlider(pnl, LIM_AMPLITUD, opts.Amplitud, [0.05 0.5], ...
            @(v) cambiarDistorsion('Amplitud', v), @(v) cambiarDistorsion('Amplitud', v));
        lbl.GrosorLineas = texto('');
        sldGrosor = crearSlider(pnl, LIM_GROSOR, opts.GrosorLineas, [0.5 1], ...
            @(v) cambiarCaptura('GrosorLineas', v), @(v) actualizarEtiquetas('GrosorLineas', v));

        chkFuente = uicontrol('Parent', pnl, 'Style', 'checkbox', 'String', txtFuente, ...
            'Value', opts.FuenteComic, 'BackgroundColor', fondo, ...
            'Callback', @(s,~) cambiarCaptura('FuenteComic', logical(get(s, 'Value'))));
        if isempty(fuenteComic)
            set(chkFuente, 'Enable', 'off');
        end
        chkEjes = uicontrol('Parent', pnl, 'Style', 'checkbox', ...
            'String', 'Retocar ejes (grosor, Layer top)', ...
            'Value', opts.RetocarEjes, 'BackgroundColor', fondo, ...
            'Callback', @(s,~) cambiarCaptura('RetocarEjes', logical(get(s, 'Value'))));

        btnSemilla = uicontrol('Parent', pnl, 'Style', 'pushbutton', ...
            'String', 'Nueva semilla', 'Callback', @(~,~) nuevaSemilla());
        btnRecapturar = uicontrol('Parent', pnl, 'Style', 'pushbutton', ...
            'String', 'Recapturar figura', 'Callback', @(~,~) cambiarCaptura());
        btnExportar = uicontrol('Parent', pnl, 'Style', 'pushbutton', ...
            'String', 'Exportar...', 'Callback', @(~,~) exportar());
        lblEstado = texto('');
        set(lblEstado, 'ForegroundColor', [0.4 0.4 0.4]);

        ax = axes('Parent', fig, 'Units', 'pixels', 'Visible', 'off');
        hImg = [];

        % Controles de arriba abajo: {control, alto, separación anterior}
        filas = {lbl.Sigma, 18, 4;  sldSigma, 20, 0;  lbl.Amplitud, 18, 10;  sldAmplitud, 20, 0;
                 lbl.GrosorLineas, 18, 10;  sldGrosor, 20, 0;  chkFuente, 22, 12;  chkEjes, 22, 4;
                 btnSemilla, 26, 12;  btnRecapturar, 26, 6;  btnExportar, 26, 6;  lblEstado, 40, 16};

        try
            set(fig, 'SizeChangedFcn', @(~,~) colocar());
        catch
            set(fig, 'ResizeFcn', @(~,~) colocar());   % versiones antiguas
        end
        colocar();

        u.fig      = fig;
        u.etiqueta = @(nombre, t) set(lbl.(nombre), 'String', t);
        u.imagen   = @mostrarImagen;
        u.estado   = @(t) set(lblEstado, 'String', t);

        function colocar()
            pos = get(fig, 'Position');
            ancho = 270;
            m = 8;
            set(pnl, 'Position', [m m ancho max(pos(4) - 2*m, 1)]);
            set(ax, 'Position', [ancho + 2*m, m, max(pos(3) - ancho - 3*m, 1), max(pos(4) - 2*m, 1)]);
            y = pos(4) - 2*m - 20;   % debajo del título del panel
            for k = 1:size(filas, 1)
                y = y - filas{k, 3} - filas{k, 2};
                set(filas{k, 1}, 'Position', [10 y ancho - 24 filas{k, 2}]);
            end
        end

        function mostrarImagen(img)
            if isempty(hImg) || ~isequal(size(get(hImg, 'CData')), size(img))
                delete(hImg);
                hImg = image('Parent', ax, 'CData', img);
                set(ax, 'YDir', 'reverse', 'DataAspectRatio', [1 1 1], 'Visible', 'off', ...
                    'XLim', [0.5 size(img, 2) + 0.5], 'YLim', [0.5 size(img, 1) + 0.5]);
            else
                set(hImg, 'CData', img);
            end
        end
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
        ui.etiqueta('Sigma', sprintf('Sigma (longitud de onda): %.1f px', opts.Sigma));
        ui.etiqueta('Amplitud', sprintf('Amplitud (temblor): %.2f px', opts.Amplitud));
        if opts.GrosorLineas > 0
            ui.etiqueta('GrosorLineas', sprintf('Grosor mínimo de líneas: %.1f', opts.GrosorLineas));
        else
            ui.etiqueta('GrosorLineas', 'Grosor mínimo de líneas: sin cambios');
        end
    end

    function exportar()
        [f, d] = uiputfile({'*.png', 'PNG'; '*.jpg', 'JPEG'; '*.tif', 'TIFF'}, ...
            'Exportar imagen xkcd', 'xkcd.png');
        figure(ui.fig);   % uiputfile deja la interfaz detrás
        if isequal(f, 0)
            return
        end
        imwrite(result, fullfile(d, f));
        ui.estado(['Exportado: ' fullfile(d, f)]);
    end

    function cerrar()
        if ~isempty(lst)
            delete(lst);
            lst = [];
        end
        if ishghandle(ui.fig)
            delete(ui.fig);
        end
    end

    %% PROCESADO
    function capturar()
        if ~ishghandle(hFig)
            ui.estado('La figura original ya no existe.');
            return
        end
        frame = capturarFigura(hFig, opts, fuenteComic);
    end

    function distorsionar()
        if isempty(frame)
            return
        end
        t = tic;
        [result, ruido] = deformar(frame, opts, ruido);
        ui.imagen(result);
        ui.estado(sprintf('%d x %d px · semilla %d · %.0f ms', ...
            size(result, 2), size(result, 1), opts.Semilla, 1000 * toc(t)));
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
    [alto, ancho, ~] = size(frame);
    rows = alto + 2 * pad;
    cols = ancho + 2 * pad;
    imgPad = ones(rows, cols, 3);
    imgPad(pad+1:pad+alto, pad+1:pad+ancho, :) = frame;

    if isempty(ruido) || ruido.Semilla ~= opts.Semilla || ~isequal(size(ruido.X), [rows cols])
        [X0, Y0] = ruidoBase(opts.Semilla, rows, cols);
        ruido = struct('Semilla', opts.Semilla, 'X', X0, 'Y', Y0);
    end

    % Suavizar y normalizar para que la Amplitud sea en píxeles
    smoothX = suavizar(ruido.X, opts.Sigma);
    smoothY = suavizar(ruido.Y, opts.Sigma);
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

function [X, Y] = ruidoBase(semilla, rows, cols)
% Ruido uniforme en [-1, 1] reproducible, sin tocar el generador global
    if exist('RandStream', 'class')
        s = RandStream('mt19937ar', 'Seed', semilla);
        X = 2 * rand(s, rows, cols) - 1;
        Y = 2 * rand(s, rows, cols) - 1;
    else
        % Octave: no hay RandStream; se guarda y restaura el estado global
        estado = rand('state');
        rand('state', semilla);
        X = 2 * rand(rows, cols) - 1;
        Y = 2 * rand(rows, cols) - 1;
        rand('state', estado);
    end
end

function S = suavizar(R, sigma)
% Filtro gaussiano separable (radio 2*sigma) con relleno circular, sin
% toolboxes. Con relleno 'replicate' el borde repetido crearía
% desplazamientos enormes en la orilla.
    r = ceil(2 * sigma);
    g = exp(-(-r:r).^2 / (2 * sigma^2));
    g = g / sum(g);
    [rows, cols] = size(R);
    ii = mod((1-r:rows+r) - 1, rows) + 1;
    jj = mod((1-r:cols+r) - 1, cols) + 1;
    S = conv2(g, g, R(ii, jj), 'valid');
end

function s = crearSlider(padre, lim, valor, paso, alSoltar, alArrastrar)
% Slider clásico: alSoltar al soltar y alArrastrar mientras se arrastra
% (ContinuousValueChange no existe en Octave: ahí solo se actualiza al soltar)
    s = uicontrol('Parent', padre, 'Style', 'slider', 'Min', lim(1), 'Max', lim(2), ...
        'Value', valor, 'SliderStep', paso / diff(lim), ...
        'Callback', @(h,~) alSoltar(get(h, 'Value')));
    try
        addlistener(s, 'ContinuousValueChange', @(h,~) alArrastrar(get(h, 'Value')));
    catch
    end
end

function tf = hayUifigure()
% uifigure con uislider, uigridlayout y uiimage('ScaleMethod'): R2021b+
    if exist('OCTAVE_VERSION', 'builtin')
        tf = false;
    elseif exist('isMATLABReleaseOlderThan', 'file')
        tf = ~isMATLABReleaseOlderThan('R2021b');
    else
        tf = false;   % anterior a R2020b
    end
end

function nombre = nombreFigura(hFig)
    nombre = get(hFig, 'Name');
    if isempty(nombre)
        try
            nombre = sprintf('Figura %d', get(hFig, 'Number'));
        catch
            nombre = sprintf('Figura %d', double(hFig));   % Octave
        end
    end
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
        if ~isempty(objs)
            objs = objs(ismember(cellstr(get(objs, 'Type')), tipos));
        end
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
        if ~ishghandle(o)
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
    try
        disponibles = lower(listfonts);
    catch
        disponibles = {};   % Octave no tiene listfonts
    end
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
