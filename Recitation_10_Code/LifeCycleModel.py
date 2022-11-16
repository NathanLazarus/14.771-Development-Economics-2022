import matplotlib.pyplot as plt
import numpy as np
from casadi import *

T = 60
T_retirement = T*3//4

r = 0.1           
R = 1 + r
beta = 1 / 1.1

taxes = [0, 0, 0]

gamma = 0.9
eta = 1

Lmax = 1

def utility(consumption, labour, gamma, eta):
    
    
    
    
    u_consumption = (consumption)**(1-gamma)/(1-gamma)
    
    u_labour = 0 
    
    u = u_consumption - u_labour
    return u


def tax(r, assets, consumption, wage, labour, taxes, T):
    
    

    tc = taxes[0]
    tk = taxes[1]
    tl = taxes[2]
    
    return r*assets[1:T+1] * tk + wage * labour *tl + consumption*tc



def asset_constraint(assets, wage, labour, consumption, R, taxes, T):
    temp = (R * assets[0:T] + wage * labour[:T] - consumption[:T]
    - tax(R-1, assets, consumption, wage, labour, taxes, T)  - assets[1:T+1])
    return temp


def wage_fun(T, T_ret):
    
    
    res = np.maximum(1.5,(1/2 + np.array(range(1,T+1)) * (1 - np.array(range(1,T+1))/T))) / 16
    res[(T_ret-1):T] = 0
    res[10] = 0 # Adding a shock
    return res



wage = wage_fun(T, T_retirement)


consumption = SX.sym('consumption', T, 1)
labour = SX.sym('labour', T, 1)
assets = SX.sym('assets', T+1, 1)



objective = -sum1(beta**(DM(range(T))) * utility(consumption, labour, gamma, eta))

    

lower_bound_C = DM.ones(T)*0.001    
lower_bound_L = np.ones(T)
lower_bound_A = vertcat([0], -100 * DM.ones(T-1), [0])

upper_bound_C = DM.ones(T)*np.inf
upper_bound_L = np.ones(T)  
upper_bound_A = vertcat([0], DM.ones(T)*np.inf)


lb_x = vertcat(lower_bound_C, lower_bound_L, lower_bound_A)
ub_x = vertcat(upper_bound_C, upper_bound_L, upper_bound_A)

nonlin_con = asset_constraint(assets, wage, labour, consumption, R, taxes, T)
nl_con = Function('nl_con',[vertcat(consumption,labour,assets)],[nonlin_con])



x_0 = vertcat(DM.ones(T), DM.ones(T), DM.zeros(T+1))


nlp = {'x': vertcat(consumption, labour, assets), 'f': objective, 'g': nonlin_con}
solver = nlpsol("solver", "ipopt", nlp,)

solution = solver(x0=x_0, lbx=lb_x, ubx=ub_x, lbg=0, ubg=0)
print(solution)
sol = np.array(solution["x"])


def plot_solution(solution, wage, T):
    plt.figure()
    plt.plot(solution[0:T], '.')
    print(solution[0:T])
    plt.title('Consumption')
    plt.savefig('consumption.pdf')
    plt.figure()
    plt.plot(solution[T:2*T], '.')
    plt.title('Labour')
    plt.savefig('labor.pdf')
    plt.figure()
    plt.plot(solution[2*T:], '.')
    plt.title('Assets')
    plt.savefig('assets.pdf')
    plt.figure()
    plt.plot(wage, '.')
    plt.title("Wage and Earnings")
    plt.savefig('earnings.pdf')
    plt.show()



plot_solution(sol, wage, T)


