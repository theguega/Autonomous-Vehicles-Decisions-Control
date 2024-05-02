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

function XP = EquationDiff_Tourbillon(t, Vecteur)
%XP = systBO(t,X)
% Cette fonction retourne le vecteur Xpoint du systeme

global RayonCycleLimite Mu

X  = Vecteur(1);
Y  = Vecteur(2);

Xp = Y + X*(RayonCycleLimite^2 - X^2 - Y^2);
Yp = -X + Y*(RayonCycleLimite^2 - X^2 - Y^2);

XP = [Xp; Yp];

end
