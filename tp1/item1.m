% ===========================================================
% Sistema: Circuito RLC serie
% Variables de estado: x = [i, v_c]
% Entrada:  u = v_e(t)  (escalon +/-12V, cambia signo cada 10ms)
% Salida:   y = v_r(t) = R * i(t)
%
% Modelo en espacio de estados:
%   x_p = A*x(t) + b*u(t)
%   y     = c^T * x(t)
%
% Matrices:
%   A = [-R/L  -1/L]    b = [1/L]    c = [R  0]
%       [ 1/C   0  ]        [ 0 ]
% ===========================================================

clear all; close all; clc;
pkg load control

% ============================================================
% Item 1 - Actividad Practica 1:
% Asignar valores a R = 2200 Ohm, L = 500 mH y C = 10uF. Obtener simulaciones que permitan estudiar la dinámica del sistema, con una entrada de tensión escalón de 12V, que cada 10 ms cambia de signo.
% ============================================================


% 1- ASIGNO VALORES A PARAMETROS, las variables del sistema (RLC, V)
R       = 2200;
L       = 500e-3;
C       = 10e-6;
V_amp   = 12.0;
T_signo = 10e-3;     % Periodo de cambio de signo de escalon[s] - 10 ms

% 2- CREO MATRICES que modelan sistemas (A, b, c)
A = [-R/L,  -1/L;
      1/C,   0  ];

B = [1/L;
     0  ];

C = [R;
     0]';      % y = c' * x  => v_r = R*i

D=0;

% 3- CREO SISTEMA usando libreria control -> obtengo salida para voltaje de resistencia
sys=ss(A,B,C,D);

% 4- (EXTRA) VERIFICO ESTABILIDAD: calc autovalores de A para tener los polos de la FdT
autovalores = eig(A);
fprintf('Autovalores del sistema:\n');
for k = 1:length(autovalores)
  fprintf('  lambda_%d = %.4f + %.4fi\n', k, real(autovalores(k)), imag(autovalores(k)));
end
if all(real(autovalores) < 0)
  fprintf('  => Sistema ESTABLE (Re(lambda) < 0)\n\n');
else
  fprintf('  => Sistema INESTABLE\n\n');
end

% 5- CONFIGURO SIMULACION: asigno vector de entrada U que cambia de signo cada 10ms, y seteo vector t de 0 a 0.1s con paso 1e-5
dt    = 1e-5;      % Paso [s]
t_fin = 0.10;      % Tiempo total [s]
t     = 0:dt:t_fin;
N     = length(t);

% Generacion de la entrada: escalon +12V/-12V cada T_signo
u_hist = zeros(1, N);
for k = 1:N
  n_periodo = floor(t(k) / T_signo);
  if mod(n_periodo, 2) == 0
    u_hist(k) = +V_amp;
  else
    u_hist(k) = -V_amp;
  end
end

% 6- SIMULACION y GRAFICO: tomo valores de las variables de interes y grafico
[y, t, x] = lsim(sys, u_hist, t);
% y -> tensión en la resistencia
% x(:,1) -> corriente i(t)
% x(:,2) -> tensión del capacitor
t_ms = t * 1e3;   % tiempo en ms para graficos
figure;

subplot(4,1,1);
plot(t_ms, 1e3*x(:,1), 'b', 'LineWidth', 1.4);
ylabel("i(t) [mA]", ...
"rotation", 0, ...
"fontweight", "bold", ...
"horizontalalignment", "right");
title('Circuito RLC - CI Nulas | R=2200\Omega, L=500mH, C=10\muF, u=\pm12V');
grid on;

subplot(4,1,2);
plot(t_ms, y, 'r', 'LineWidth', 1.4);
ylabel("Vo(t)", ...
       "rotation", 0, ...
       "fontweight", "bold", ...
       "horizontalalignment", "right");
grid on;

subplot(4,1,3);
plot(t_ms, x(:,2), 'k', 'LineWidth', 1.4);
ylabel("V_cap(t)", ...
       "rotation", 0, ...
       "fontweight", "bold", ...
       "horizontalalignment", "right");
grid on;

subplot(4,1,4);
plot(t_ms, u_hist, 'm', 'LineWidth', 1.4);       
h = xlabel("t [ms]", "fontweight", "bold");
set(h, "horizontalalignment", "right");
ylabel("V_e(t)", ...
       "rotation", 0, ...
       "fontweight", "bold", ...
       "horizontalalignment", "right");
grid on;

