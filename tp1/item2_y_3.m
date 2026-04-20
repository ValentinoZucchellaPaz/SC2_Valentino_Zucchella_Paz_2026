
% ============================================================
% Item 2 - Actividad Practica 1:
% Usando los datos de Curvas_Medidas_RLC.xls deducir los valores de R, L y C del circuito. Emplear el método de la respuesta al escalón (Chen), tomando como salida la tensión en el capacitor.
% ============================================================
% pkg install -forge io
clear all; close all; clc
pkg load io
pkg load control

data = xlsread("tp1/Curvas_Medidas_RLC_2026.xlsx");

t  = data(:,1);   % Tiempo
i  = data(:,2);   % Corriente
vc = data(:,3);   % Tensión capacitor
ve = data(:,4);   % Entrada
vr = data(:,5);   % Salida resistencia

% tiempos de muestreo (relativos a comienzo de dinamica)
t0 = 0.1    % instante del escalon
t1 = 0.01   % espaciado entre puntos

y1 = interp1(t, vc, t0 + t1)    % t = 0.11
y2 = interp1(t, vc, t0 + 2*t1)  % t = 0.12
y3 = interp1(t, vc, t0 + 3*t1)  % t = 0.13

y_inf = 12;
k1 = (y1 / y_inf) - 1;
k2 = (y2 / y_inf) - 1;
k3 = (y3 / y_inf) - 1;

b = 4*k1^3*k3 - 3*k1^2*k2^2 - 4*k2^3 + k3^2 + 6*k1*k2*k3 % b>0
a = k1^2 + k2 % a!=0
alpha1 = (k1*k2 + k3 - sqrt(b)) / (2*a)
alpha2 = (k1*k2 + k3 + sqrt(b)) / (2*a)
T1 = -t1 / log(alpha1) % -> 5.0778e-03
T2 = -t1 / log(alpha2) % -> 0.043321

s=tf('s');
G=1/((T1*s+1)*(T2*s+1))
[num,den]=tfdata(G,'v') % den = [T1*T2, T1+T2, 1] = [LC RC 1];

% Calculo C usando los datos obtenidos
% G = Vc(s)/Ve(s)
% i(t) = C · dv_c/dt => C = i * dt/dv_c
% G_i(s) = I(s)/Ve(s) = C · s · G(s)

% Elegir un instante dentro de la dinámica del primer escalón
% donde la corriente y la variación de Vc sean significativas, ademas tomo muchas muestras y promedio para evitar ruido
idx = find(t >= 0.12 & t <= 0.18);  % ventana dentro del transitorio

dVc = diff(vc(idx));
dt  = diff(t(idx));
i_mid = i(idx(1:end-1));

C_vals = (i_mid .* dt) ./ dVc;
C = mean(C_vals) % 2.2025e-04
L=den(1)/C % 0.9988
R=den(2)/C % 219.75

% validacion con sistema de estados
A = [-R/L   -1/L;
      1/C    0];

B = [1/L;
     0];

C_mat = [0 1];   % salida = v_c
D = 0;

sys = ss(A, B, C_mat, D);


% COMPARO:
%   - modelo de estados con valores de RLC calculadas en el ejercicio
%   - datos de sistema original (excel)
[y_model, t_sim, x_plot] = lsim(sys, ve, t);

figure;
plot(t, vc, 'b', 'LineWidth', 1.5); hold on; % valores del excel
plot(t_sim, y_model, '--g', 'LineWidth', 1.5); % modelo de estados con valores de RLC calc
plot(t, ve, '--r', 'LineWidth', 1.5); % vector de entrada
plot(t0 + t1,   y1, 'kx', 'LineWidth', 2, 'MarkerSize', 8);
plot(t0 + 2*t1, y2, 'kx', 'LineWidth', 2, 'MarkerSize', 8);
plot(t0 + 3*t1, y3, 'kx', 'LineWidth', 2, 'MarkerSize', 8);
legend('Vcap Medido', 'Vcap Modelo', 'Entrada','Puntos Chen');
title('Validacion del modelo RLC (Chen)');
xlabel('Tiempo [s]');
ylabel('V(t)');
grid on;


% ITEM 3: validar modelo obtenido en otro tramo (0.5 en adelante) y con otra variable (corriente)
C_validar_corriente = [1;0]';
sys2 = ss(A, B, C_validar_corriente, D);


idx_val = find(t >= 0.05, 1);
t_val = t(idx_val:end);
i_val = i(idx_val:end);
ve_val = ve(idx_val:end);

[y_val, t_sim, x_val] = lsim(sys2, ve_val, t_val - t_val(1));

figure;
plot(t_val, i_val, 'b', 'LineWidth', 1.5); hold on;
plot(t_val, y_val, '--r', 'LineWidth', 1.5);

legend('Corriente medida', 'Corriente modelo');
title('Validacion del modelo con corriente');
xlabel('Tiempo [s]');
ylabel('i(t)');
grid on;