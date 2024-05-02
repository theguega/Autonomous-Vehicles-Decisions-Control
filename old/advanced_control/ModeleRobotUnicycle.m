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

function ModeleRobotUnicycle

global L d r 
global AccelerationLineaireMax AccelerationAngulaireMax
global Rrobot

% Param�tres g�om�triques du robot mobile
L = 2.5;     % Empattement (en m�tre)
d = Rrobot;  % Largeur des essieux (en m�tre) pour que �a colle � la d�finition du robot circulaire
r = 1;     % Rayon des roues (en m�tre)

AccelerationLineaireMax = 1;
AccelerationAngulaireMax = 1;
