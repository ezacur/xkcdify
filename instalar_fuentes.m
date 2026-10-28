function instalar_fuentes(nombres, varargin)
%INSTALAR_FUENTES  Descarga e instala fuentes cómic para xkcdify.
%
%   instalar_fuentes() instala xkcd Script, Patrick Hand y Comic Neue.
%   instalar_fuentes({'Humor Sans', 'Short Stack'}) instala esas.
%   instalar_fuentes('todas') instala todas las de la lista.
%   instalar_fuentes(..., 'Simular', true) descarga y comprueba las fuentes
%   y dice qué haría, pero no instala nada.
%
%   Las fuentes se descargan de su origen oficial (no se incluyen en el
%   repositorio):
%
%     xkcd Script          letra de xkcd, con minúsculas, tildes  CC BY-NC 3.0
%                          y eñes (github.com/ipython/xkcd-font)  (no comercial)
%     Humor Sans           letra de xkcd, solo mayúsculas, sin    gratuita
%                          tildes ni eñes (antiyawn.com)
%     Patrick Hand         manuscrita estrecha, muy legible       SIL OFL
%     Comic Neue           Comic Sans "bien hecha"                SIL OFL
%     Architects Daughter  manuscrita, estilo de arquitecto       SIL OFL
%     Comic Relief         parecida a Comic Sans                  SIL OFL
%     Short Stack          redondeada y ancha                     SIL OFL
%   (las OFL, de Google Fonts: github.com/google/fonts)
%
%   Dónde se instalan:
%     Windows  para todos los usuarios (C:\Windows\Fonts): MATLAB no ve las
%              fuentes instaladas solo para el usuario. Windows pide permiso
%              de administrador.
%     macOS    ~/Library/Fonts
%     Linux    ~/.local/share/fonts (y se ejecuta fc-cache)
%
%   Después hay que reiniciar MATLAB para que vea las fuentes nuevas.
%   xkcdify elige sola la primera que tenga todos los caracteres de la
%   figura; ver la opción 'Fuente' en help xkcdify.

    if nargin < 1 || isempty(nombres)
        nombres = {'xkcd Script', 'Patrick Hand', 'Comic Neue'};
    end
    p = inputParser;
    p.addParameter('Simular', false, @(v) isscalar(v));
    p.parse(varargin{:});
    simular = p.Results.Simular;

    google = 'https://github.com/google/fonts/raw/main/ofl/';
    catalogo = {
        'xkcd Script',         'https://github.com/ipython/xkcd-font/raw/master/xkcd-script/font/xkcd-script.ttf'
        'Humor Sans',          'http://antiyawn.com/uploads/Humor-Sans-1.0.ttf'
        'Patrick Hand',        [google 'patrickhand/PatrickHand-Regular.ttf']
        'Comic Neue',          [google 'comicneue/ComicNeue-Regular.ttf']
        'Architects Daughter', [google 'architectsdaughter/ArchitectsDaughter-Regular.ttf']
        'Comic Relief',        [google 'comicrelief/ComicRelief-Regular.ttf']
        'Short Stack',         [google 'shortstack/ShortStack-Regular.ttf']
    };

    if ischar(nombres) && strcmpi(nombres, 'todas')
        nombres = catalogo(:, 1)';
    end
    nombres = cellstr(nombres);
    [ok, idx] = ismember(lower(nombres), lower(catalogo(:, 1)));
    if ~all(ok)
        error('instalar_fuentes:desconocida', 'Fuente desconocida: %s. Disponibles: %s.', ...
            strjoin(nombres(~ok), ', '), strjoin(catalogo(:, 1)', ', '));
    end
    elegidas = catalogo(idx, :);

    % Las ya instaladas no se tocan
    try
        disponibles = lower(listfonts);
    catch
        disponibles = {};
    end
    yaEstan = ismember(lower(elegidas(:, 1)), disponibles);
    for k = find(yaEstan)'
        fprintf('%s ya está instalada.\n', elegidas{k, 1});
    end
    elegidas = elegidas(~yaEstan, :);
    if isempty(elegidas)
        fprintf('No hay nada que instalar.\n');
        return
    end

    % Descargar y comprobar que son fuentes de verdad
    carpeta = tempname;
    mkdir(carpeta);
    ficheros = cell(size(elegidas, 1), 1);
    for k = 1:size(elegidas, 1)
        [~, base, ext] = fileparts(elegidas{k, 2});
        ficheros{k} = fullfile(carpeta, [base ext]);
        fprintf('Descargando %s...\n', elegidas{k, 1});
        descargar(elegidas{k, 2}, ficheros{k});
        if ~esFuente(ficheros{k})
            error('instalar_fuentes:descarga', ...
                'Lo descargado para %s no es una fuente (%s).', elegidas{k, 1}, elegidas{k, 2});
        end
    end

    if simular
        fprintf('\nSimulación: fuentes descargadas y comprobadas en %s\n', carpeta);
        fprintf('Se instalarían en: %s\n', carpetaDestino());
        return
    end

    if ispc
        instalarWindows(elegidas(:, 1), ficheros);
    else
        destino = carpetaDestino();
        if ~exist(destino, 'dir')
            mkdir(destino);
        end
        for k = 1:numel(ficheros)
            copyfile(ficheros{k}, destino);
        end
        if ~ismac
            system('fc-cache -f');
        end
    end

    % Comprobar el resultado
    destino = carpetaDestino();
    for k = 1:numel(ficheros)
        [~, base, ext] = fileparts(ficheros{k});
        if exist(fullfile(destino, [base ext]), 'file')
            fprintf('Instalada: %s\n', elegidas{k, 1});
        else
            fprintf('NO instalada: %s (¿se rechazó el permiso de administrador?)\n', elegidas{k, 1});
        end
    end
    fprintf('\nReinicia MATLAB para que vea las fuentes nuevas.\n');
    if any(strcmpi(elegidas(:, 1), 'xkcd Script'))
        fprintf('xkcd Script tiene licencia CC BY-NC 3.0: no se puede usar con fines comerciales.\n');
    end
end

function d = carpetaDestino()
    if ispc
        d = fullfile(getenv('WINDIR'), 'Fonts');
    elseif ismac
        d = fullfile(getenv('HOME'), 'Library', 'Fonts');
    else
        d = fullfile(getenv('HOME'), '.local', 'share', 'fonts');
    end
end

function descargar(url, fichero)
    if exist('websave', 'file')
        websave(fichero, url);
    else
        urlwrite(url, fichero);   % Octave
    end
end

function tf = esFuente(fichero)
% Cabecera TrueType (00 01 00 00, 'true') u OpenType ('OTTO')
    fid = fopen(fichero, 'r');
    cabecera = fread(fid, 4, 'uint8=>uint8')';
    fclose(fid);
    tf = numel(cabecera) == 4 && (isequal(cabecera, uint8([0 1 0 0])) || ...
        any(strcmp(char(cabecera), {'true', 'OTTO'})));
end

function instalarWindows(nombres, ficheros)
% Copia a C:\Windows\Fonts y registra cada fuente, en un PowerShell con
% permisos de administrador (Windows mostrará el aviso)
    lineas = {};
    for k = 1:numel(ficheros)
        [~, base, ext] = fileparts(ficheros{k});
        lineas{end+1} = sprintf('Copy-Item -LiteralPath ''%s'' -Destination (Join-Path $env:WINDIR ''Fonts\\%s'') -Force', ...
            ficheros{k}, [base ext]); %#ok<AGROW>
        lineas{end+1} = sprintf(['New-ItemProperty -Path ''HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'' ' ...
            '-Name ''%s (TrueType)'' -Value ''%s'' -PropertyType String -Force | Out-Null'], ...
            nombres{k}, [base ext]); %#ok<AGROW>
    end
    script = fullfile(fileparts(ficheros{1}), 'instalar_fuentes.ps1');
    fid = fopen(script, 'w');
    fprintf(fid, '%s\r\n', lineas{:});
    fclose(fid);

    fprintf('Instalando (Windows pedirá permiso de administrador)...\n');
    orden = sprintf(['powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -Wait ' ...
        '-ArgumentList ''-NoProfile'',''-ExecutionPolicy'',''Bypass'',''-File'',''\\"%s\\"''"'], script);
    system(orden);
end
