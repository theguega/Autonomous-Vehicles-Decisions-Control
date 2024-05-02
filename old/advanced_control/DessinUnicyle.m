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

function DessinUnicyle(Xreel,Yreel,theta, Info)

global d r

% --- Position du centre de l'essieu arri�re
xe = Xreel;
ye = Yreel;

%===================
% Essieu Arri�re  ||
%===================
% --- Centre de la roue arri�re droite
xArD = xe + d/2*sin(theta);
yArD = ye - d/2*cos(theta);
% 
% % --- Centre de la roue arri�re gauche
xArG = xe - d/2*sin(theta);
yArG = ye + d/2*cos(theta);

%========================
% Roue Arri�re Gauche  ||
%========================
xArGDev = xArG + r*cos(theta);
yArGDev = yArG + r*sin(theta);

xArGArr = xArG - r*cos(theta);
yArGArr = yArG - r*sin(theta);
% 
% %========================
% % Roue Arri�re Droite  ||
% %========================
xArDDev = xArD + r*cos(theta);
yArDDev = yArD + r*sin(theta);

xArDArr = xArD - r*cos(theta);
yArDArr = yArD - r*sin(theta);

%%Position du centre du point situ� devant le robot 
xA = xe + (0.5)*cos(theta);
yA = ye + (0.5)*sin(theta);

%===========================
% Trac� du Robot Mobile  ||
%===========================
figure(1)
hold on
plot(xe,ye,'r+');              % Trac� du centre de l'essieu arri�re
grid on
%line([xe xA],[ye yA])         % Trac� de l'empattement -- relie (x,y) � (xA,yA) 
%plot(xA, yA, 'b+')            % Trac� du devant du robot   
line([xArG xArD],[yArG yArD])                           % Trac� de l'essieu arri�re -- relie (xArG,yArG) � (xArD,yArD)
line([xArGDev xArGArr],[yArGDev yArGArr],'Color','r')   % Trac� de la roue arri�re gauche -- relie (xArGDev,yArGDev) � (xArGArr,yArGArr)
line([xArDDev xArDArr],[yArDDev yArDArr],'Color','r')   % Trac� de la roue arri�re droite -- relie (xArDDev,yArDDev) � (xArDArr,yArDArr)

for i=0:0.2:(2*pi)
    plot(xe+(d/2)*cos(i),ye+(d/2)*sin(i),'-');
end

%Dessin de l'info souhait�e
text(xe, ye+0.5, num2str(Info))

