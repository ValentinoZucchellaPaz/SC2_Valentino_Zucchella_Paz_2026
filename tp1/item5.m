% Valentino Zucchella Paz
% Wr (s) = Gva (s) * Va(s) + Gtl (s) * Tl (s)

clear all; close all; clc
pkg load control
pkg load io

data = xlsread("tp1/Curvas_Medidas_Motor_2026.xlsx");

t  = data(:,1);   % Tiempo
wr = data(:,2);   % Vel angular
ia = data(:,3);   % Corriente de Armadura
Vin = data(:,4);  % Tension de Entrada
Ein = Vin(end);   % cte de tension de entrada (no vector)  
Tl = data(:,5);   % Torque

% graficos de excel
figure;
subplot(2,1,1);
plot(t, wr, 'r', 'LineWidth', 1);
xlabel('Tiempo (s)');
ylabel('Velocidad Angular (rad/s)');
title('Datos Medidos');
grid on;
hold on;

subplot(2,1,2);
plot(t, ia, 'g', 'LineWidth', 1);
hold on;
plot(t, Vin, 'b', 'LineWidth', 1);
hold on;
plot(t, Tl, 'yellow', 'LineWidth', 1);
xlabel('Tiempo (s)');
ylabel('Amplitud');
legend('Corriente Armadura', 'Tension Entrada', 'Torque');
grid on;


% BUSCO Wr/Vin
% Metodo de Chen
t0_va = 2.68; % delay de escalon
t1_va = 0.5; % espacio entre puntos

% puntos que describen dinamica
t1_wr = t0_va + 1*t1_va
t2_wr = t0_va + 2*t1_va
t3_wr = t0_va + 3*t1_va

% busco y(ti_wr)
y_1 = interp1(t,wr,t1_wr)
y_2 = interp1(t,wr,t2_wr)
y_3 = interp1(t,wr,t3_wr)

% Ganancia y valor de regimen
y_inf = wr(end) % no lo afecta la perturbacion aqui, ya volvio al regimen
K_wr = y_inf/Ein

%calculo de k1,k2 y k3
k1 = (y_1/(K_wr*Ein)) - 1
k2 = (y_2/(K_wr*Ein)) - 1
k3 = (y_3/(K_wr*Ein)) - 1

%calculo de a1, a2 b y beta
b_wr = 4*k1^3*k3 - 3*k1^2*k2^2 - 4*k2^3 + k3^2 + 6*k1*k2*k3
a    = k1^2 + k2

a1_wr = (k1*k2 + k3 - sqrt(b_wr)) / (2*a)
a2_wr = (k1*k2 + k3 + sqrt(b_wr)) / (2*a)
T1_wr = -t1_va/log(a1_wr)
T2_wr = -t1_va/log(a2_wr)
beta_Wr = (k1+a2_wr)/(a1_wr - a2_wr)
T3_wr = beta_Wr*(T1_wr-T2_wr)+T1_wr

% Obtengo funcion de tranferencia de modelo
G_Wr_Vin = tf([0 0 1], [T1_wr*T2_wr T1_wr+T2_wr 1])*K_wr
G_Wr_Vin_z = tf([0 T3_wr 1], [T1_wr*T2_wr T1_wr+T2_wr 1])*K_wr


% simulo para escalon 10V
idx_15s = t <= 15;
t_sim = t(idx_15s);
Vin_sim = zeros(length(t_sim), 1);
Vin_sim(t_sim >= t0_va) = 10;

wr_sim = lsim(G_Wr_Vin, Vin_sim, t_sim);
wr_sim_z = lsim(G_Wr_Vin_z, Vin_sim, t_sim);

% Grafico y comparo
figure;
plot(t_sim, interp1(t, wr, t_sim), 'b', 'LineWidth', 1.4); hold on;
plot(t_sim, wr_sim, '--r', 'LineWidth', 1.4);
plot(t_sim, wr_sim_z, '-.g', 'LineWidth', 1.4); hold on;
plot(t_sim, Vin_sim, ':k', 'LineWidth', 1.4);
legend('Wr medido', 'Wr modelo Chen', 'Wr modelo Chen con cero', "Vin");
xlabel('Tiempo [s]');
ylabel('\omega_r [rad/s]');
title('Dinamica de Wr ante escalon Vin=10V');
grid on;

% BUSCO Wr/tL
% Problema, cuando aparece Tl ya esta en regimen y solo debo analizar dinamica, trabajar con la variacion respecto al equilibrio
% Entonces resto valor de regimen: d_wr = wr_t - wr_ss
% Luego: d_Wr (s) = Gtl (s) * Tl (s)

% aplico Chen
t0_tl = 18.67; % delay en el que comienza escalon
t1_tl = 0.3; % espacio entre puntos

t1_wr_tl = t0_tl + 1 * t1_tl;
t2_wr_tl = t0_tl + 2 * t1_tl;
t3_wr_tl = t0_tl + 3 * t1_tl;

wr_ss = interp1(t,wr,t0_tl) % valor de regimen antes de perturbacion
y_tl_1 = interp1(t,wr,t1_wr_tl) - wr_ss
y_tl_2 = interp1(t,wr,t2_wr_tl) - wr_ss
y_tl_3 = interp1(t,wr,t3_wr_tl) - wr_ss

y_ss_tl = interp1(t,wr,26.67) - wr_ss % valor de wr con perturbacion activa estable - valor de regimen anterior

K_tl = y_ss_tl/20 % regimen con perturbacion / escalon de perturbacion

k1_tl = (y_tl_1/(K_tl*20)) - 1
k2_tl = (y_tl_2/(K_tl*20)) -1
k3_tl = (y_tl_3/(K_tl*20)) -1

b_tl = (4*(k1_tl^3)*k3_tl)-(3*(k1_tl^2)*(k2_tl^2))-(4*(k2_tl^3))+(k3_tl^2)+(6*k1_tl*k2_tl*k3_tl)
a1_tl = ((k1_tl*k2_tl+k3_tl)-sqrt(b_tl))/(2*((k1_tl^2)+k2_tl))
a2_tl = ((k1_tl*k2_tl+k3_tl)+sqrt(b_tl))/(2*((k1_tl^2)+k2_tl))

T1_tl = -t1_tl/log(a1_tl)
T2_tl = -t1_tl/log(a2_tl)

beta_tl = (k1_tl+a2_tl)/(a1_tl - a2_tl)
T3_tl = beta_tl*(T1_tl-T2_tl)+T1_tl

% Obtengo funcion de tranferencia de modelo
G_Wr_Tl = tf([0 0 1], [T1_tl*T2_tl T1_tl+T2_tl 1])*K_tl
G_Wr_Tl_z = tf([0 T3_tl 1], [T1_tl*T2_tl T1_tl+T2_tl 1])*K_tl

% Aislar tramo de la perturbacion
mask = (t >= t0_tl-2) & (t <= 35);
t_tl    = t(mask) - t0_tl;    % tiempo relativo al inicio del escalon
wr_tl   = wr(mask);           % wr medido en ese tramo

% Señal incremental de TL en ese tramo
TL_inc = zeros(size(t_tl));
TL_inc(t_tl >= 0 & t_tl <= (26.67-t0_tl)) = 20;

% lsim sobre el tramo aislado
wr_tl_sim = lsim(G_Wr_Tl, TL_inc, t_tl);
wr_tl_sim_z = lsim(G_Wr_Tl_z, TL_inc, t_tl);

% Comparar
figure;
plot(t_tl, wr_tl - wr_ss, 'b', 'LineWidth', 1.4); hold on;
plot(t_tl, wr_tl_sim,  '--r', 'LineWidth', 1.4);
plot(t_tl, wr_tl_sim_z,  '--g', 'LineWidth', 1.4);
legend('wr incremental medido', 'wr modelo Chen', 'wr modelo Chen con cero');
xlabel('Tiempo relativo al escalon [s]');
ylabel('\Delta\omega_r [rad/s]');
title('Dinamica de Wr ante perturbacion TL=20V');
grid on;

% FINAL: JUNTO AMBAS FDT
% Señales completas desde t=0
Va_signal  = Vin;                        % entrada de tension del excel
TL_signal  = zeros(size(t));
TL_signal(t >= t0_tl & t < 26.67) = 20;   % escalon que se corta

% lsim de cada canal por separado
wr_por_Va  = lsim(G_Wr_Vin, Va_signal,  t);
wr_por_Va_z  = lsim(G_Wr_Vin_z, Va_signal,  t);
wr_por_TL  = lsim(G_Wr_Tl,  TL_signal,  t);
wr_por_TL_z = lsim(G_Wr_Tl_z,  TL_signal,  t);

% Superposicion
wr_total = wr_por_Va + wr_por_TL_z;
% wr_total_z = wr_por_Va_z + wr_por_TL_z; % elijo usar solo el cero en TL y no en Va


% Comparar contra datos reales
figure;
plot(t, wr,        'b',   'LineWidth', 1.4); hold on;
plot(t, wr_total ,  '--g', 'LineWidth', 1.4);
legend('\omega_r medido', '\omega_r modelo completo');
xlabel('Tiempo [s]');
ylabel('\omega_r [rad/s]');
title('Dinamica completa de Wr ante Vin y TL');
grid on;
% analizando grafico veo que cero de Wr/Va es prescindible pero el cero de Wr/Tl si cambia la dinamica y la acerca mas a las mediciones, esto concuerda con el analisis de las funciones de transferencia a partir de las ecuaciones:
% Wr/Vin (s)= Ki / [(Ls+R)(Js+B)+Ki*Km] = Ki / [(L*J) s^2 + (L * B + J * R) s + (R*B+KmKi)]
% Wr/TL (s)= -Ki*(L s+R) / [(Ls+R)(Js+B)+Ki*Km] = -(L s+R)Ki / [(L*J) s^2 + (L * B + J * R) s + (R*B+KmKi)]


% FALTA FINAL FINAL: deducir valores de R, L, J, B, Ki, Km => necesito la FdT de I_a/Vin
% I_a/Vin= (J s + Bm) / [(Ls+R)(Js+B)+Ki*Km] = (J s + Bm) / [(L*J) s^2 + (L*Bm + J*R) s + (R*Bm+Km*Ki)]
% Metodo de Chen
t0_ia = 2.68; % delay de escalon
t1_ia_paso = 0.3; % espacio entre puntos

% puntos que describen dinamica
t1_ia = t0_va + 1*t1_ia_paso
t2_ia = t0_va + 2*t1_ia_paso
t3_ia = t0_va + 3*t1_ia_paso

% busco y(ti_ia)
y_1_ia = interp1(t,ia,t1_ia)
y_2_ia = interp1(t,ia,t2_ia)
y_3_ia = interp1(t,ia,t3_ia)

% Ganancia y valor de regimen
y_inf_ia = ia(end) % no lo afecta la perturbacion aqui, ya volvio al regimen
K_ia  = y_inf_ia/Ein

%calculo de k1,k2 y k3
k1_ia = (y_1_ia/y_inf_ia) - 1
k2_ia = (y_2_ia/y_inf_ia) - 1
k3_ia = (y_3_ia/y_inf_ia) - 1

%calculo de a1, a2 b y beta
b_ia  = 4*k1_ia^3*k3_ia - 3*k1_ia^2*k2_ia^2 - 4*k2_ia^3 + k3_ia^2 + 6*k1_ia*k2_ia*k3_ia
a_ia  = k1_ia^2 + k2_ia

a1_ia = (k1_ia*k2_ia + k3_ia - sqrt(b_wr)) / (2*a_ia)
a2_ia = (k1_ia*k2_ia + k3_ia + sqrt(b_wr)) / (2*a_ia)
T1_ia = -t1_ia_paso/log(a1_ia)
T2_ia = -t1_ia_paso/log(a2_ia)
beta_ia = (k1_ia+a2_ia)/(a1_ia - a2_ia)
T3_ia = beta_ia*(T1_ia-T2_ia)+T1_ia


% Obtengo funcion de tranferencia de modelo
G_Ia_Vin_z = tf([0 T3_ia 1], [T1_ia*T2_ia T1_ia+T2_ia 1])*K_ia


% simulo para escalon 10V
% idx_15s = t <= 15;
% t_sim = t(idx_15s);
% Vin_sim = zeros(length(t_sim), 1);
% Vin_sim(t_sim >= t0_va) = 10;

ia_sim_z = lsim(G_Ia_Vin_z, Vin_sim, t_sim);

% Grafico y comparo
figure;
plot(t_sim, interp1(t, ia, t_sim), 'b', 'LineWidth', 1.4); hold on;
plot(t_sim, ia_sim_z, '-.g', 'LineWidth', 1.4); hold on;
plot(t_sim, Vin_sim, ':k', 'LineWidth', 1.4);
plot(t1_ia, y_1_ia, 'ko', 'LineWidth', 2, 'MarkerSize', 6);
plot(t2_ia, y_2_ia, 'ko', 'LineWidth', 2, 'MarkerSize', 6);
plot(t3_ia, y_3_ia, 'ko', 'LineWidth', 2, 'MarkerSize', 6);
legend('Ia medido', 'Ia modelo Chen con cero', "Vin");
xlabel('Tiempo [s]');
ylabel('\omega_r [rad/s]');
title('Dinamica de Wr ante escalon Vin=10V');
grid on;


% si elijo Wr_Vin sin cero y Wr_Tl con cero, puedo comparar numeradores y denominadores:
% Wr_Vin = K_wr / [(T1_wr*T2_wr) s^2 + (T1_wr+T2_wr) s + 1]
% Wr_Vin = K_tl*(T3 s+1) / [(T1_wr*T2_wr) s^2 + (T1_wr+T2_wr) s + 1]

% Wr/Vin (s)= Ki / [(Ls+R)(Js+B)+Ki*Km] = Ki / [(L*J) s^2 + (L * B + J * R) s + (R*B+KmKi)]
% I_a/Vin= (J s + Bm) / [(Ls+R)(Js+B)+Ki*Km] = (J s + Bm) / [(L*J) s^2 + (L*Bm + J*R) s + (R*Bm+Km*Ki)]

% MAL, NO ANDA, NO RESPONDE BIEN A TL -> tengo dos fdt distintas cuando deben tener el mismo denominador (2 chen distintos)
% uso 0 de chen de TL y denominador de Vin -> TMP ANDA

[num_wr_tl, den_wr_tl] = tfdata(G_Wr_Tl_z, 'v') 
[num_wr_vin, den_wr_vin] = tfdata(G_Wr_Vin, 'v')
[num_ia_vin, den_ia_vin] = tfdata(G_Ia_Vin_z, 'v') 

Ki=num_wr_vin(3)
J=num_ia_vin(2)
Bm=num_ia_vin(3)
Laa=den_ia_vin(1)/J
Ra=(den_ia_vin(2)-Bm*Laa)/J
Km=(den_ia_vin(3)-Ra*Bm)/Ki

% Ra=(num_wr_tl(3))/(-Ki)
% Laa=(num_wr_tl(2))/(-Ki)

% ahora comparo denominadores para obtener J, Bm, Km


% armo matriz para diagrama de estados con
% x [ ia; wr; theta ]
A = [-Ra/Laa,  -Km/Laa,  0;
      Ki/J,    -Bm/J,    0;
      0,        1,       0];

B = [1/Laa; 0; 0];
E = [0; -1/J; 0];
D = [0]
C=[0 1 0]

% uso perturbacion como entrada para poder simular
B_aug = [B E];   % 2 entradas: Va y TL
D_aug = [0 0];   % salida no depende directo de entradas
sys = ss(A, B_aug, C, D_aug);

% armo entrada con escalones
Va = zeros(size(t));
Va(t >= 2.68) = 10;
TL = zeros(size(t));
TL(t >= 18.68 & t <= 26.67) = 20;
U = [Va TL];

wr_sim_datos_chen = lsim(sys, U, t);
figure;
plot(t, wr, 'k', 'LineWidth', 1.5); hold on;
plot(t, wr_sim_datos_chen, '--r', 'LineWidth', 2);
plot(t, TL, '--y', 'LineWidth', 2);
plot(t, Va, '--g', 'LineWidth', 2);

legend('Medido', 'Modelo físico', "TL", "Va");
xlabel('Tiempo [s]');
ylabel('\omega_r [rad/s]');
grid on;