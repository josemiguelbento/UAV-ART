% forces_moments.m
%  Computes the forces and moments acting on the airframe. 
%
%   Output is
%       F     - forces
%       M     - moments
%       Va    - airspeed
%       alpha - angle of attack
%       beta  - sideslip angle
%       wind  - wind vector in the inertial frame
%
%   New output includes:
%       miu_d - bank angle desired
%       miu - bank angle
%       Omega - angular velocity
%       dot_Omega_d - 
%       v - airspeed
%       v_d - airspeed desired
%       G - 
%       w - 
%       alpha0 - angle of attack that nullifies the forces due to the drag, lift and gravity
%       Maabb - 
%       Moo - 
%       Mdd - 
%       gamma - flight-path
%       D - 
%       k_VP - 
%       k_VI - 



function out = forces_moments(x, delta, wind, P)

    % relabel the inputs
    pn      = x(1);
    pe      = x(2);
    pd      = x(3);
    u       = x(4);
    v       = x(5);
    w       = x(6);
    phi     = x(7);
    theta   = x(8);
    psi     = x(9);
    p       = x(10);
    q       = x(11);
    r       = x(12);
    delta_e = delta(1);
    delta_a = delta(2);
    delta_r = delta(3);
    delta_t = delta(4);
    w_ns    = wind(1); % steady wind - North
    w_es    = wind(2); % steady wind - East
    w_ds    = wind(3); % steady wind - Down
    u_wg    = wind(4); % gust along body x-axis
    v_wg    = wind(5); % gust along body y-axis    
    w_wg    = wind(6); % gust along body z-axis

    % No gusts
    %u_wg = 0; v_wg = 0; w_wg = 0;
        
    %% Compute air data
            
    swind_vec = rotateFromInertialtoBody(phi,theta,psi,w_ns,w_es,w_ds);
    wind_vec = swind_vec + [u_wg,v_wg,w_wg];
    u_w = wind_vec(1); 
    v_w = wind_vec(2); 
    w_w = wind_vec(3);
    
    u_r = u - u_w;
    v_r = v - v_w;
    w_r = w - w_w;
    
    % compute wind data in NED
    inertial_wind_vec = rotateFromBodytoInertial(phi,theta,psi,u_w,v_w,w_w);
    w_n = inertial_wind_vec(1); 
    w_e = inertial_wind_vec(2);
    w_d = inertial_wind_vec(3);
    
    Va = sqrt(u_r^2+v_r^2+w_r^2);
    
    if abs(u_r) > 1e-5
        alpha = atan2(w_r,u_r);
    else
        alpha = 0;
    end
    
    if Va > 1e-5
        beta = asin(v_r/Va);
    else
        beta = 0;
    end

    %% Compute external forces and torques on aircraft
    
    Force = zeros(3,1);
    Torque = zeros(3,1);
    
    if Va > 1e-5
        Force = getFAer(Va,alpha,q,delta_e,beta,p,r,delta_a,delta_r,P);
        FAer = Force;
        Torque = getTorques(Va,alpha,q,delta_e,beta,p,r,delta_a,delta_r,P);
        TAer = Torque;
    end

    L = Torque(1) / (0.5*P.rho*Va^2*P.S_wing);
    M = Torque(2) / (0.5*P.rho*Va^2*P.S_wing);
    N = Torque(3) / (0.5*P.rho*Va^2*P.S_wing);
    
    %[pdot,qdot,rdot] = getAngularRateDerivatives(p,q,r,L,M,N,P);
    
    % Add thrust and torque generated by the propeller
    F_prop = 0.5*P.rho*P.S_prop*P.C_prop*((P.k_motor*delta_t)^2-Va^2);
    Force = Force + [F_prop;0;0];
    T_prop = -P.k_T_P*(P.k_Omega*delta_t)^2;
    Torque = Torque + [T_prop;0;0];

    % Gravity
    Fg_body = rotateFromInertialtoBody(phi,theta,psi,0,0,P.mass*P.gravity);
    Force = Force + Fg_body';
    
    %% Compute variables required for Precision Landing

    miu = phi; %??? duvida
    miu_d = 0;
    
    % Airspeed controller

    k_VP = 0.5; %arbitrary value
    k_VI = 0.8; %arbitrary value
    
    % Angular velocity controller

    Maabb = [P.C_ell_beta, 0; 
            0, P.C_m_alpha; 
            P.C_n_beta, 0];

  
    Moo = [P.b*P.C_ell_p,0,0;
                0,P.c*P.C_m_q,0;
                P.b*P.C_n_p,0,P.b*P.C_n_r];
   
    Moo = Moo/(2*V);

    Mdd = [0,P.C_ell_delta_a,P.C_ell_delta_r;
            P.C_m_delta_e,0,0;
            0,P.C_n_delta_a,P.C_n_delta_r];

    alpha0 = 0.01; % corresponds to the angle of attack that nullifies the 
                    % resulting forces due to the drag, lift and gravity. see
                    % paper and try to calculate this value for our model


    % Attitude controller
    gamma = asin(w/Va);
    chi = atan2(Va*sin(psi)+P.wind_e, Va*cos(psi)+P.wind_n);

    G=[sin(alpha) 0 -cos(alpha);-cos(alpha)*tan(beta) 1 -sin(alpha)*tan(beta);...
        cos(alpha)/cos(beta) 0 sin(alpha)/cos(beta)];

    W1=-D*tan(beta)-C+mass*g*(sin(miu)*cos(gamma)-sin(gamma)*tan(beta));

    W2=(-D*tan(alpha)-L*cos(beta)+mass*g*(cos(miu)*cos(gamma)*cos(beta)-...
        sin(gamma)*tan(alpha)))/((cos(beta))^2);

    W3=L*(tan(beta)+tan(gamma)*sin(miu))-C*tan(gamma)*cos(miu)+D*...
        (((tan(alpha)*sin(miu)*tan(gamma)+tan(alpha)*tan(beta))/(cos(beta)))...
        -tan(beta)*cos(miu)*tan(gamma))+mass*g*(((tan(alpha)*sin(miu)*tan...
        (gamma)*sin(gamma)+tan(alpha)*tan(beta)*sin(gamma))/(cos(beta)))-...
        ((tan(beta)*cos(miu))/cos(gamma)));
    
    W=[W1;W2;W3];

    D = Force(0);

    add_out = [miu, miu_d, gamma, G, W, chi, alpha0, Maabb, Moo, Mdd, D];
    
    out = [Force',Torque', FAer', TAer', Va, alpha, beta, w_n, w_e, w_d,...
        u_r, add_out];
    
end

function F_vec = getFAer(Va,alpha,q,de,beta,p,r,da,dr,P)
    
    F_lift = P.C_L_0 + P.C_L_alpha*alpha + P.C_L_q*(P.c/(2*Va))*q + ...
                                                        P.C_L_delta_e*de;
                                    
    F_drag = P.C_D_0 + P.C_D_alpha*alpha + P.C_D_q*(P.c/(2*Va))*q + ...
                                                        P.C_D_delta_e*de;
                                                    
%     F_drag = P.C_D_p + (P.C_L_0 + P.C_L_alpha*alpha)^2/...
%                                                 (pi*P.e*P.b^2/P.S_wing);
                                
    Fy = P.C_Y_0 + P.C_Y_beta*beta + P.C_Y_p*(P.b/(2*Va))*p + ... 
                        P.C_Y_r*(P.b/(2*Va))*r + P.C_Y_delta_a*da + ...
                                                        P.C_Y_delta_r*dr;
    
    % Rotate lift and drag forces from the stability frame to body frame
    R = [cos(alpha)   -sin(alpha);...
         sin(alpha)   cos(alpha)];  
    
    F_body = R*[-F_drag;-F_lift];            
    F_vec = 0.5*P.rho*Va^2*P.S_wing*[F_body(1);Fy;F_body(2)];

end

function T_vec = getTorques(Va,alpha,q,de,beta,p,r,da,dr,P)

    L = P.b*(P.C_ell_0 + P.C_ell_beta*beta + P.C_ell_p*(P.b/(2*Va))*p + ...
                        P.C_ell_r*(P.b/(2*Va))*r + P.C_ell_delta_a*da + ...
                                                    P.C_ell_delta_r*dr);
        
    M = P.c*(P.C_m_0 + P.C_m_alpha*alpha + P.C_m_q*(P.c/(2*Va))*q + ...
                                                        P.C_m_delta_e*de);
    
    N = P.b*(P.C_n_0 + P.C_n_beta*beta + P.C_n_p*(P.b/(2*Va))*p + ...
                        P.C_n_r*(P.b/(2*Va))*r + P.C_n_delta_a*da + ...
                                                    P.C_n_delta_r*dr);
                    
    T_vec = 0.5*P.rho*Va^2*P.S_wing*[L;M;N];    
    
end


%% ----
% é importante perceber como é que as coisas vão entrar no novo autopilot.
% mantendo a organização, entram dados pelo: states (x), airdata, e
% commands. É preciso perceber cada variável como é que entra.

% nao podem sair coisas diretamente daqui certo? ou vão por states ou
% airdata.

% PARAMETROS QUE TÊM E JA ESTAO A SAIR DAQUI:
% V (airspeed) -> states
% alpha e beta -> Forces e moments pelo air data
% miu_d -> assumimos = 0.
% miu -> Assumir que é 0? Parece-me estranho.. Procurar formula?
% omega (angular velocity no body) (p,q,r) -> states
% dot_omega (angular velocity no body) -> temos acesso no mav_dynamics.m na
%linha 151: [pdot,qdot,rdot] = getAngularRateDerivatives(p,q,r,L,M,N,P).
%Penso que já vai para o autopilot pelo sys.
% V_d -> constante pelos commands (references)

% PARAMETROS QUE TÊM QUE SAIR DAQUI E AINDA NAO ESTA 100%:
% gamma -> onde temos acesso a isto? 
% chi -> atan2(Va*sin(psi)+we, Va*cos(psi)+wn): 
% miu -> Assumir que é 0? Parece-me estranho.. Procurar formula?
% D,C,L 
% Para o calculo do u_a: 
% velocidade em relação ao vento, u,v,w dos states ou nao? (( v-> expressed
% in {I}
% parametros que vêm de visão (como simulamos isto?)


%obs meter saturações?
% problema com o dot_omega_d ...





