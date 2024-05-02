%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Lounis ADOUANE                                                     %
%% Universit� de Technologie de Compi�gne (UTC)                       %
%% SY28 :: D�partement G�nie Informatique (GI)                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Part I : Planning and control of mobile robots                     %
%% Th�or�me de stabilit� de Lyapunov et m�thode des cycles-limites    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Derni�re modification le 21/03/2022                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DistanceTO = DistanceVerticaleTrajectoireObstacle(PositionRobot, PositionCible, PositionObstacle)

%% Attention quand la droite � une pente infinie (Pente = 90�)

%=======================================================================
% D�termination des param�tres de la droite S de la forme y = ax + b  ||
%=======================================================================
% La droite S est la droite qui passe par (Xreel0, Yreel0) et (Xd,Yd).
%%%%%%
Xreel= PositionRobot(1);
Yreel = PositionRobot(2);
Xd= PositionCible(1);
Yd= PositionCible(2); 
Xobst = PositionObstacle(1);
Yobst = PositionObstacle(2);
%%%%%%

Nb = 50;
x = linspace(Xreel,Xd,Nb)'; %Generates Nb points between Xreel and Xd
y = linspace(Yreel,Yd,Nb)'; %Generates Nb points between Yreel and Yd

%%Le mod�le : de aX+bY+c=0 avec b=1=> Moindre carr�s donne Y=[X ones(Nb)][-a -b]'
Matrice = [x, ones(Nb,1)];
Estimation = pinv(Matrice)*y; %Estimation = [a c]' 

%Finalement
a = Estimation(1,1);
c = Estimation(2,1);

DistanceTO = -((-a*Xobst)+(Yobst)-c) / (sqrt((a^2)+(1^2))); 
DistanceTO = abs(DistanceTO); %C'est juste pour les tests

%%Pour le dessin de la droite
% t=0:1:30; 
% VAR=(a*t+c);
% plot(t,VAR,'r')
