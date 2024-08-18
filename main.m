function beam_section_optimization()
    % Define optimization variables
    x0 = [300, 500, 30, 25, 4, 8]; % Initial guess
    lb = [300, 300, 30, 22, 2, 6]; % Lower bounds
    ub = [1000, 1000, 50, 29, 6, 10]; % Upper bounds

    % Optimization options
    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'interior-point');

    % Run optimization
    [x_opt, fval] = fmincon(@objective_function, x0, [], [], [], [], lb, ub, @constraint_functions, options);

    % Display results
    disp('Optimal design variables:');
    disp(['Width (b) = ', num2str(x_opt(1)), ' mm']);
    disp(['Height (h) = ', num2str(x_opt(2)), ' mm']);
    disp(['Concrete Strength (fcu) = ', num2str(x_opt(3)), ' MPa']);
    disp(['Rebar Diameter (d) = ', num2str(x_opt(4)), ' mm']);
    disp(['Number of Rebars = ', num2str(x_opt(5))]);
    disp(['Number of Stirrups = ', num2str(x_opt(6))]);
    disp(['Objective function value (cost + emissions) = ', num2str(fval)]);

    [cost, emissions] = objective_function(x_opt);
    disp(['Total Cost = ', num2str(cost)]);
    disp(['Total Emissions = ', num2str(emissions)]);

    % Plotting
    plot_results();
end

function [f, cost, emissions] = objective_function(x)
    b = x(1);
    h = x(2);
    fcu = x(3);
    d = x(4);
    num_rebars = x(5);
    num_stirrups = x(6);

    cost_concrete = 400; % price per m3 for C35 concrete
    cost_rebar = 300; % price per ton for rebar
    cost_stirrup = 250; % price per ton for stirrups
    volume = (b / 1000) * (h / 1000) * 1; % Volume in m3

    carbon_concrete = 384; % kg CO2e/m3 for C35 concrete
    carbon_rebar = 4000; % kg CO2e/ton for rebar
    carbon_stirrup = 4000; % kg CO2e/ton for stirrups

    cost = (cost_concrete * volume) + (cost_rebar * num_rebars * 0.01) + (cost_stirrup * num_stirrups * 0.01);
    emissions = (carbon_concrete * volume) + (carbon_rebar * num_rebars * 0.01) + (carbon_stirrup * num_stirrups * 0.01);

    f = cost + emissions;
end

function [c, ceq] = constraint_functions(x)
    b = x(1);
    h = x(2);
    fcu = x(3);
    d = x(4);
    num_rebars = x(5);
    num_stirrups = x(6);

    fc = 30; % Example concrete compressive strength
    fy = 400; % Example tensile strength of rebar
    As = num_rebars * pi * (d / 2)^2; % Total area of longitudinal rebars
    s = 200; % Spacing of stirrups (mm)
    h0 = h - 50; % Effective height (mm)

    M = 1e6; % Example design moment (Nm)
    Mu = (fc * b * h0 * (1 - (d / h0))) / 1.0; % Bending capacity (Nm)
    V = 1e5; % Example design shear force (N)
    Vu = 0.8 * fy * As / s; % Shear capacity (N)

    c(1) = M - Mu; % Bending capacity constraint
    c(2) = V - Vu; % Shear capacity constraint
    c(3) = (h / 1000) - 0.5; % Maximum deflection constraint
    ceq = [];
end

function plot_results()
    b_range = linspace(300, 1000, 10);
    h_range = linspace(300, 1000, 10);
    [B, H] = meshgrid(b_range, h_range);
    F = zeros(size(B));
    Cost = zeros(size(B));
    Emissions = zeros(size(B));

    for i = 1:numel(B)
        x = [B(i), H(i), 30, 25, 4, 8];
        [F(i), Cost(i), Emissions(i)] = objective_function(x);
    end

    % Plot Objective Function vs. Beam Dimensions
    figure;
    surf(B, H, F);
    xlabel('Width (b) [mm]');
    ylabel('Height (h) [mm]');
    zlabel('Objective Function Value (Cost + Emissions)');
    title('Objective Function Value vs. Beam Dimensions');
    colorbar;

    % Plot Cost vs. Beam Dimensions
    figure;
    surf(B, H, Cost);
    xlabel('Width (b) [mm]');
    ylabel('Height (h) [mm]');
    zlabel('Cost');
    title('Cost vs. Beam Dimensions');
    colorbar;

    % Plot Emissions vs. Beam Dimensions
    figure;
    surf(B, H, Emissions);
    xlabel('Width (b) [mm]');
    ylabel('Height (h) [mm]');
    zlabel('Emissions');
    title('Emissions vs. Beam Dimensions');
    colorbar;

    % Plot Design Variables vs. Objective Function
    num_points = 50;
    b_values = 300 + 700*rand(num_points, 1);
    h_values = 300 + 700*rand(num_points, 1);
    [f_vals, ~, ~] = arrayfun(@(b, h) objective_function([b, h, 30, 25, 4, 8]), b_values, h_values);
    
    figure;
    scatter3(b_values, h_values, f_vals, 'filled');
    xlabel('Width (b) [mm]');
    ylabel('Height (h) [mm]');
    zlabel('Objective Function Value (Cost + Emissions)');
    title('Design Variables vs. Objective Function');
end

beam_section_optimization();
