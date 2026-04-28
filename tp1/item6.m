clear; close all; clc

%% Parametros del motor: obtenidos en el ejercicio anterior
Ki_m = 6.6667;
J=6.6667;
Bm=0.3334;
Laa=0.3334;
Ra=0.7141;
Km=0.1143;


%% Simulacion
dt      = 1e-5;
t_total = 10;
t       = 0:dt:t_total;
N       = length(t);

%% PID: verificado por prueba y error
% error nulo y tiempo establecimiento cerca de 3.5s (TL comienza en 2)
% Kp     = 200;
% Ki_pid = 0;
% Kd     = 200;

% valores menos extremos
% error de regimen 10% aprox
% sin muchas oscilaciones buen tiempo establecimiento
% Va solo tiene una saturacion
Kp     = 20;
Ki_pid = 0.0001;
Kd     = 20;

theta_ref = 1.0;
u_max =  12;
u_min = -12;

%% Variables
ia    = zeros(1, N);
wr    = zeros(1, N);
theta = zeros(1, N);
va    = zeros(1, N);

eI    = 0;
e_ant = 0;

%% Torque de carga
TL = zeros(1, N);
TL(t >= 2.0) = 20;

%% Loop
for k = 2:N-1

    % --- PID ---
    e       = theta_ref - theta(k);
    eD      = (e - e_ant) / dt;
    eI      = eI + e * dt;

    u_unsat = Kp*e + Ki_pid*eI + Kd*eD;
    u       = max(u_min, min(u_max, u_unsat));

    % Anti-windup
    eI = eI - (u_unsat - u) * dt;

    va(k) = u;
    e_ant = e;

    % --- Euler motor ---
    ia(k+1)    = ia(k)    + dt * ( va(k)/Laa - (Ra/Laa)*ia(k) - (Km/Laa)*wr(k) );
    wr(k+1)    = wr(k)    + dt * ( (Ki_m/J)*ia(k) - (Bm/J)*wr(k) - TL(k)/J );
    theta(k+1) = theta(k) + dt * wr(k);
end

%% Graficas
step = 10000;
figure;
subplot(3,1,1);
plot(t(1:step:end), theta(1:step:end), 'b'); yline(theta_ref, 'r--');
xlabel('Tiempo [s]'); ylabel('\theta [rad]');
title('Posicion angular'); grid on;

subplot(3,1,2);
plot(t(1:step:end), va(1:step:end), 'm');
xlabel('Tiempo [s]'); ylabel('Va [V]');
title('Voltaje de control'); grid on;

subplot(3,1,3);
plot(t(1:step:end), wr(1:step:end), 'g');
xlabel('Tiempo [s]'); ylabel('\omega_r [rad/s]');
title('Velocidad angular'); grid on;