function [safe, safetyCert] = check_collision(step_size, v, max_disturbance, psi_des, obstacle)

r = obstacle(1); xc = obstacle(2); yc = obstacle(3);

% Polynomial dynamics: Taylor expansion of nonlinear dynamics to degree 3  
syms x y p omega
f1=v*sin(p)+omega;
f2=v*cos(p);
u=-50*(p-psi_des*pi/180); f3=u;
% Obtained Polynomial dynamics
fT1 = taylor(f1, p, 'Order', 3);
fT2 = taylor(f2, p, 'Order', 3);
fT3=f3;


%% SOS Program

% 2d: Order of polynomial Barrier function
d=2;

% variables
sdpvar x y p omega

% Polynomial Uncertain nonlinear system dx(t)/dt=f(x,w)
f=[eval(fT1);eval(fT2);eval(fT3)];

% polynomial Barrier function of order 2d, c: coefficients, Vm: monomials
[V,c,Vm] = polynomial([x;y;p],2*d);

% dV(x)/dt
dVdt = jacobian(V,[x;y;p])*f;

% Uncertainty Set [-max_disturbance, max_disturbance]
g_omega=(max_disturbance-omega)*(omega+max_disturbance);
% Obstacle set 
%[h1, h2, h3] = occlusion_space(xo, yo, r, 0.7, 0.3);
g_obs=(r^2-(x - xc)^2 - (y - yc)^2) ;
%g_obs=0.25^2-(x-0.5)^2-(y-0.5)^2;
% Set of all states 
X=step_size^2-(x)^2-(y)^2-(p)^2;



% s1: SOS polynomial
[s1,c1] = polynomial([x;y;p;omega],2*d);
% s2: SOS polynomial
[s2,c2] = polynomial([x;y;p;omega],2*d);
% s3: SOS polynomial
[s3,c3] = polynomial([x;y;p;omega],2*d);



% SOS Conditions:
%V([x_0,y_0,psi_0])=0
% V>=1 on Obstacle  set 
% -dVdt>=0 for all uncertainty w  
F = [sos(V-1-s1*g_obs),sos(-dVdt-s2*g_omega-s3*X), sos(s1),sos(s2),sos(s3),c(1)==0];

%SDP solver
ops = sdpsettings('solver','mosek', 'verbose', 0);

% Solve SOS based SDP
[sol,v,Q]=solvesos(F,[],ops,[c1;c2;c3;c]);
%%

%% Results
% Obtained coefficients of polynomial Lyapunov Function
cc=value(c);

% Lyapunov Function
L1=sdisplay(cc'*Vm);
% dV(x)/dt
dL1 = sdisplay(jacobian(cc'*Vm,[x;y;p])*f);

safe = (sol.problem == 0);
safetyCert=L1;

end

