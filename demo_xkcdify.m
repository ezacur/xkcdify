%% Demo de xkcdify
% Crea una figura normal y abre la interfaz de xkcdify sobre ella.

close all

hFig = figure('Color', 'w', 'Position', [100 100 700 450]);

x = linspace(0, 10, 200);
plot(x, sin(x), x, 0.5*cos(1.5*x), x, exp(-x/4) - 0.5);
grid on
xlabel('tiempo (s)');
ylabel('valor');
legend('sin(x)', '0.5 cos(1.5x)', 'e^{-x/4} - 0.5', 'Location', 'southwest');
title('Demo de xkcdify');

xkcdify(hFig);
