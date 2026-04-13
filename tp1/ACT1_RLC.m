% ===========================================================
%   Modelado RLC en Variables de Estado - Dr. Ing. Pucheta
%   Sistemas de Control II - FCEFyN - UNC
%   Actividad Practica 1 - Caso de estudio 1 - Items 1 y 2
% ===========================================================
%
% Sistema: Circuito RLC serie
% Variables de estado: x = [i, v_c]^T
% Entrada:  u = v_e(t)  (escalon +/-12V, cambia signo cada 10ms)
% Salida:   y = v_r(t) = R * i(t)
%
% Modelo en espacio de estados:
%   x_dot = A*x(t) + b*u(t)
%   y     = c^T * x(t)
%
% Matrices (Ec. 2-4 clase 2):
%   A = [-R/L  -1/L]    b = [1/L]    c^T = [R  0]
%       [ 1/C   0  ]        [ 0 ]
%
% Integracion numerica: Euler explicito
%   x[k+1] = x[k] + dt * (A*x[k] + b*u[k])
%   y[k]   = c' * x[k]
% ===========================================================

clear all; close all; clc;

fprintf('=====================================================\n');
fprintf('  MODELADO RLC EN VARIABLES DE ESTADO\n');
fprintf('  Dr. Ing. Pucheta | Sistemas de Control II\n');
fprintf('=====================================================\n\n');

% ============================================================
% Item 1 - Actividad Practica 1
% Metodología y explicacion de pasos:
% 1- ASIGNO VALORES A PARAMETROS, las variables del sistema (RLC, V)
% 2- CREO MATRICES que modelan sistemas (A, b, c)
% 3- (EXTRA) VERIFICO ESTABILIDAD: calc autovalores de A para tener los polos de la FdT
% 4- CONFIGURO SIMULACION: asigno vector de entrada U que cambia de signo cada 10ms, y seteo vector t de simulacion de 0 a 0.1s con paso 1e-5
% 5- SIMULACION: para cada entrada de U, evaluo el vector de estados (X) usando integracion recursiva de euler X(k+1)= X(k) + dt * X_dot -> como X_dot solo depende de X y de U no hago asignacion en dos pasos sino en uno solo (ademas uso condiciones iniciales nulas)
% 6- CALCULO SALIDA Y usando matriz c' y vector de estados X (en este caso mi salida es voltaje de la resistencia v_r)
% 7- GRAFICO: tomo valores de las variables de interes y grafico con vector de simulacion t
% ============================================================


% ============================================================
% 1- ASIGNO VALORES A PARAMETROS, las variables del sistema (RLC, V)
% ============================================================
R       = 2200;      % Resistencia [Ohm] - 2.2 kOhm
L       = 500e-3;    % Inductancia [H]   - 500 mHy
C       = 10e-6;     % Capacitancia [F]  - 10 uF
V_amp   = 12.0;      % Amplitud del escalon [V]
T_signo = 10e-3;     % Periodo de cambio de signo [s] - 10 ms

fprintf('Parametros del circuito:\n');
fprintf('  R = %d Ohm\n', R);
fprintf('  L = %.1f mH\n', L*1e3);
fprintf('  C = %.1f uF\n', C*1e6);
fprintf('  Entrada: +/-%.1f V, cambia signo cada %.0f ms\n\n', V_amp, T_signo*1e3);

% ============================================================
% 2- CREO MATRICES que modelan sistemas (A, b, c)
% ============================================================
A = [-R/L,  -1/L;
      1/C,   0  ];

b = [1/L;
     0  ];

c = [R;
     0];      % y = c' * x  => v_r = R*i

fprintf('Matriz de estados A:\n');
disp(A);
fprintf('Vector de entrada b:\n');
disp(b);
fprintf('Vector de salida c^T:\n');
disp(c');

% ============================================================
% 3- (EXTRA) VERIFICO ESTABILIDAD: calc autovalores de A para tener los polos de la FdT
% ============================================================
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

% ============================================================
% 4- CONFIGURO SIMULACION: asigno vector de entrada U que cambia de signo cada 10ms, y seteo vector t de simulacion de 0 a 0.1s con paso 1e-5
% ============================================================
dt    = 1e-5;      % Paso de integracion [s]
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

% ============================================================
% 5- SIMULACION: para cada entrada de U, evaluo el vector de estados (X) usando integracion recursiva de euler X(k+1)= X(k) + dt * X_dot -> como X_dot solo depende de X y de U no hago asignacion en dos pasos sino en uno solo (ademas uso condiciones iniciales nulas)
% ============================================================
fprintf('Simulando con condiciones iniciales NULAS...\n');
x0 = [0; 0];       % i(0) = 0 A,  v_c(0) = 0 V

x = zeros(2, N);
x(:,1) = x0;

for k = 1:N-1
  x(:,k+1) = x(:,k) + dt * (A * x(:,k) + b * u_hist(k));
end

% ============================================================
% 6- CALCULO SALIDA Y usando matriz c' y vector de estados X (en este caso mi salida es voltaje de la resistencia v_r)
% ============================================================

i_t  = x(1,:);      % Corriente [A]
vc_t = x(2,:);      % Tension en capacitor [V]
vr_t = c' * x;      % Salida: tension en resistor [V]  (= R*i)

% ============================================================
% 7- GRAFICO: tomo valores de las variables de interes y grafico con vector de simulacion t
% ============================================================
figure(1);
t_ms = t * 1e3;   % tiempo en ms para graficos

subplot(4,1,1);
plot(t_ms, i_t*1e3, 'b', 'LineWidth', 1.4);
ylabel('i(t) [mA]');
title('Circuito RLC - CI Nulas | R=2200\Omega, L=500mH, C=10\muF, u=\pm12V');
grid on;

subplot(4,1,2);
plot(t_ms, vc_t, 'r', 'LineWidth', 1.4);
ylabel('v_c(t) [V]');
grid on;

subplot(4,1,3);
plot(t_ms, u_hist, 'k', 'LineWidth', 1.4);
ylabel('v_e(t) [V]');
ylim([-15 15]);
grid on;

subplot(4,1,4);
plot(t_ms, vr_t, 'm', 'LineWidth', 1.4);
ylabel('v_r(t) [V]');
xlabel('Tiempo [ms]');
grid on;

% ============================================================
% RESUMEN EN CONSOLA
% ============================================================
