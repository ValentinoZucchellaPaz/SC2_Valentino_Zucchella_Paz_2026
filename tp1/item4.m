clear all; close all; clc;
% correr codigo en matlab, octave no puede correrlo bien

% ============================================================
% PARAMETROS DEL MOTOR
% ============================================================
Laa = 366e-6;
J   = 5e-9;
Ra  = 55.6;
Bm  = 0;
Ki  = 6.49e-3;
Km  = 6.53e-3;
Va  = 12;

% ============================================================
% MATRICES DEL SISTEMA EN ESPACIO DE ESTADOS
%  x = [ia, wr, theta]^T
%  xp = A*x + B*Va + E*TL
% ============================================================
A = [-Ra/Laa,  -Km/Laa,  0;
      Ki/J,    -Bm/J,    0;
      0,        1,       0];

B = [1/Laa; 0; 0];
E = [0; -1/J; 0];

% ============================================================
% CONFIGURACION DE LA SIMULACION
% ============================================================
dt    = 1e-7;    % paso de integracion [s]
t_fin = 5;       % tiempo total [s]
N     = round(t_fin / dt);   % numero de pasos

% Torque de carga: crece linealmente hasta 120% del maximo teorico
TL_max_teo = Ki * Va / Ra
TL_rate    = 1.2 * TL_max_teo / t_fin;   % [N·m/s]

% ============================================================
% VECTORES PARA GUARDAR RESULTADOS
% ============================================================
t_vec  = zeros(1, N);
ia_vec = zeros(1, N);
wr_vec = zeros(1, N);
th_vec = zeros(1, N);
TL_vec = zeros(1, N);

% ============================================================
% CONDICIONES INICIALES
% ============================================================
ia = 0;      % corriente inicial [A]
wr = 0;      % velocidad angular inicial [rad/s]
th = 0;      % posicion angular inicial [rad]

% ============================================================
% INTEGRACION EULER EXPLICITO
%
%  x[k+1] = x[k] + dt * (A*x[k] + B*Va + E*TL[k])
%
% Expandido por componentes:
%  ia[k+1] = ia[k] + dt * (-Ra/Laa * ia[k] - Km/Laa * wr[k] + Va/Laa)
%  wr[k+1] = wr[k] + dt * ( Ki/J   * ia[k] - Bm/J   * wr[k] - TL[k]/J)
%  th[k+1] = th[k] + dt * ( wr[k] )
% ============================================================
for k = 1:N

    t_k  = k * dt;
    TL_k = TL_rate * t_k;

    % Guardar estado actual
    t_vec(k)  = t_k;
    ia_vec(k) = ia;
    wr_vec(k) = wr;
    th_vec(k) = th;
    TL_vec(k) = TL_k;

    % Calcular derivadas (lado derecho de las ecuaciones del motor)
    dia = -Ra/Laa * ia  -  Km/Laa * wr  +  Va/Laa;
    dwr =  Ki/J   * ia  -  Bm/J   * wr  -  TL_k/J;
    dth =  wr;

    % Avanzar un paso Euler
    ia = ia + dt * dia;
    wr = wr + dt * dwr;
    th = th + dt * dth;

end

% ============================================================
% DETECTAR INSTANTE DE STALL (wr cruza cero)
% ============================================================
idx_stall = find(wr_vec <= 0 & t_vec > 0.01, 1);

fprintf('Motor detenido en t = %.4f s\n',   t_vec(idx_stall));
fprintf('TL_stall            = %.4e N·m\n', TL_vec(idx_stall));
fprintf('ia en stall         = %.4f A\n',   ia_vec(idx_stall)); % 0.2158 A

% ============================================================
% GRAFICOS
% ============================================================

% Submuestrear solo para graficar (evita el efecto punteado)
% La simulacion y los calculos usan todos los 50M puntos
dec = 1000;
idx_plot = 1:dec:N;

t_p  = t_vec(idx_plot);
ia_p = ia_vec(idx_plot);
wr_p = wr_vec(idx_plot);
TL_p = TL_vec(idx_plot);

figure(1);

subplot(3,1,1);
plot(t_p, ia_p * 1e3, 'b', 'LineWidth', 1.4);
xline(t_vec(idx_stall), '--r', 'LineWidth', 1.2);
yline(ia_vec(idx_stall) * 1e3, '--r', 'LineWidth', 1.2);
ylabel('i_a(t) [mA]');
title('Motor DC - TL creciente lineal | Va=12V, dt=1e-7s');
grid on;

subplot(3,1,2);
plot(t_p, wr_p, 'r', 'LineWidth', 1.4);
yline(0, 'k--', 'LineWidth', 1.0);
xline(t_vec(idx_stall), '--r', 'LineWidth', 1.2);
ylabel('\omega_r(t) [rad/s]');
grid on;

subplot(3,1,3);
plot(t_p, TL_p * 1e6, 'k', 'LineWidth', 1.4);
xline(t_vec(idx_stall), '--r', 'Label', sprintf('t_{stall}=%.2fs', t_vec(idx_stall)), 'LineWidth', 1.2); % TL stall simulado
yline(TL_vec(idx_stall)*1e6, '--g', ...
      'Label', sprintf('TL_{max}=%.2e N·m', TL_vec(idx_stall)), 'LineWidth', 1.2); % TL stall teorico
ylabel('T_L(t) [\muN·m]');
xlabel('Tiempo [s]');
grid on;