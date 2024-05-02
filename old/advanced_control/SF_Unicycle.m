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

function [sys,x0,str,ts] = SF_Unicycle(t,x,u,flag,Xreel0,Yreel0,Theta0)

    %[sys,x0,str,ts]=f(t,x,u,flag,p1,p2,...) %d�finition d'une S-Function
    %where f is the S-function's name, t is the current time, x is the state vector of the corresponding S-function block, 
    %u is the block's inputs, flag indicates a task to be performed, and p1, p2, ... are the block's parameters. 
    %During simulation of a model, Simulink repeatedly invokes f, using flag to indicate the task to be performed for a 
    %particular invocation. Each time the S-function performs the task, it returns the result in a structure having the format shown in 
    %the syntax example.
    
    switch flag
    
      %%%%%%%%%%%%%%%%%%
      % Initialisation %
      %%%%%%%%%%%%%%%%%%
      
      case 0
        [sys,x0,str,ts] = mdlInitializeSizes(Xreel0,Yreel0,Theta0);
    
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Calcul de la d�riv�e de l'�tat continu %
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 1
          
        sys = mdlDerivatives(t,x,u);        % t --> Temps
                                            % x --> Etat du Robot Mobile
                                            % u --> Commande
       
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Update and Terminate (Fin de la simulation) NB : le 2 c'est pour les syst�mes discr�ts %
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {2,9}
          
        sys = []; % cleanup SYS = []"
    
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Calcul de la sortie de la S-fonction %
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 3
          
        sys = mdlOutputs(t,x,u);
    
      %%%%%%%%%%%%%%%%%%%%
      % Unexpected flags %
      %%%%%%%%%%%%%%%%%%%%
      otherwise
          
        error(['Unhandled flag = ',num2str(flag)]);
    end
end


%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================

function [sys,x0,str,ts]=mdlInitializeSizes(Xreel0,Yreel0,Theta0)

    sizes = simsizes;
    
    sizes.NumContStates  = 3;   % nombre d'�tats continus (x_courant, y_courant et theta_courant)
    sizes.NumDiscStates  = 0;   % nombre d'�tats discrets 
    sizes.NumOutputs     = 3;   % nombre de sorties (x, y, theta)
    sizes.NumInputs      = 2;   % nombre d'entr�es (les commandes u1 (vitesse lin�aire) et u2 (vitesse angulaire) pour le Cycab)
    sizes.DirFeedthrough = 0;   % sizes.DirFeedthrough = 0 si D=0; sizes.DirFeedthrough = 1 si D=1
                                % ATTENTION : En principe ce bit doit �tre �
                                % '1' pour r�specter la doc fournie par MATLAB
                                % "N�anmoins le laisser comme cela ne nuit pas � la simu"
                                % (voir sfuntmpl.m) 
    sizes.NumSampleTimes = 1;   % Nombre des pas d'�chantillonnages 
    
    sys = simsizes(sizes);
    
    % Conditions Initiales
    
    x0  = [Xreel0;Yreel0;Theta0];
    
    
    % str is always an empty matrix
    
    str = [];
    
    
    % initialize the array of sample times
    
    ts  = [0 0];

end


%=============================================================================
% mdlDerivatives
% Return the derivatives for the continuous states.
%=============================================================================

function sys=mdlDerivatives(~,x,u)

sys = [u(1)*cos(x(3)) ; u(1)*sin(x(3)) ; u(2)];

end

%=============================================================================
% mdlOutputs
% Return the block outputs.
%=============================================================================

function sys=mdlOutputs(~,x,~)

sys = x;

end
