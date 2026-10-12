clc;
clear;
close all;

% Number of samples
%{

fsig= 1000;
Tsig = 1/fsig;

Fs = 30 * fsig;
Ts = 1/Fs;

t = Ts : Ts : 1000 * Tsig - Ts;


x = 127 * sin(2* pi * fsig *t) ; 

x = awgn(x, 20, "measured" );

%}

x = randi([-128, 127], 1, 100000);

N = length(x);
time = 1 : N;

% Quantized input
x_n = x/128;

% Input power
p_before = mean(x_n.^2);

%% Parameters and initializations
% Window of filter
M = 32 ;

% Truncation
% Sweep resolution of output bits for M = 32
T_power = 7: 1 : 8 + log2(M) - 1 ; 
Trunc_coef = 2.^T_power;

% Saturation limits
max_val = 0.4;
min_val = -0.4;


% Sweep counter wait samples to find the optimum point
counter_sweep = [2, 4, 8, 16, 32, 64, 128, 256, 512]; 
SQNR_target = 30;
sqnr_db = zeros(length(T_power), N);
sqnr_db_rec = zeros(length(T_power), N);
sqnr_saturation_db = zeros(length(T_power), N);

% Use Cell Arrays to store data for different counter sizes
sqnr_now = cell(1, length(counter_sweep));
counter_events = cell(1, length(counter_sweep));

% Store the final SQNR for every counter size and bit resolution
sqnr_sweep = zeros(length(counter_sweep), length(T_power));

%% Calculate Non-Recursive and Pure Recursive (Independent of Counter)
for k = 1:length(T_power)
    % Non-recursive
    y_non_rec = zeros(1, N);
    for i = 1:N-M+1
        y_non_rec(i) = sum(x_n(i:i+M-1))/M;
    end
    
    y_rounded = zeros(size(y_non_rec));
    for i = 1:length(y_non_rec)
        y_rounded(i) = round(y_non_rec(i)*Trunc_coef(k))/Trunc_coef(k);
    end

    y_clipped = min(max(y_rounded, min_val), max_val);
    Q_error = y_non_rec - y_rounded;
    Q_error_saturation = y_non_rec - y_clipped;
    window_nonrec_sqnr = 2000;
    
    for j = window_nonrec_sqnr : N - M + 1
        p_quantized = mean(y_non_rec(j - window_nonrec_sqnr + 1 : j ).^2);
        p_error = max(mean(Q_error(j - window_nonrec_sqnr + 1 : j ).^2), 1e-14);
        p_saturation_noise = mean(Q_error_saturation(j - window_nonrec_sqnr + 1 : j ).^2);
        
        sqnr_db(k, j - window_nonrec_sqnr +1) = 10*log10(p_quantized/p_error);
        sqnr_saturation_db(k, j - window_nonrec_sqnr +1) = 10*log10(p_quantized/p_saturation_noise);
    end
    
    % Recursive form
    y_rec = zeros(1, N);
    y_rec(1) = round(sum(x_n(1 : M))/M * Trunc_coef(k))/Trunc_coef(k);
    for i = 2 : N - M + 1
        y_rec(i) = round((y_rec(i-1) + (x_n(i + M - 1) - x_n(i-1))/M)*Trunc_coef(k))/Trunc_coef(k);  
    end
    
    Q_error_rec = y_rec - y_non_rec;
    window_rec_sqnr = 400;
    for j = window_rec_sqnr : N - M + 1
        p_quantized = mean(y_non_rec(j - window_rec_sqnr + 1 : j ).^2);
        p_error_rec = max(mean(Q_error_rec(j - window_rec_sqnr + 1 : j ).^2), 1e-14);
        sqnr_db_rec(k, j- window_rec_sqnr + 1) = 10*log10(p_quantized/p_error_rec);
    end
end
    % Note we need to run many runs to get right SQNR arrangement in plot
    % We can not average on time for random variables, they are not WSS

%% Solution (Timer-Based Refresh Iterating Over Counter Sizes)
for C = 1:length(counter_sweep)
    
    % Initialize matrices for this specific counter size
    sqnr_now{C} = zeros(length(T_power), N);
    counter_events{C} = zeros(1, length(T_power));
    counter_size = counter_sweep(C);
    
    for k = 1:length(T_power)
        y_refresh = zeros(1, N);
        y_refresh(1) = round(sum(x_n(1 : M))/M * Trunc_coef(k))/Trunc_coef(k);
        start_idx = 1;
        Q_error_refresh = zeros(1,N);
        
        for i = 2 : N - M + 1
            y_refresh(i) = round((y_refresh(i-1) + (x_n(i + M - 1) - x_n(i-1))/M)*Trunc_coef(k))/Trunc_coef(k);
            Q_error_refresh(i) = y_refresh(i) - y_non_rec(i);
            
            % Powers
            eval_window = 200 ;
            if(i > eval_window)
                p_quantized2 = mean(y_non_rec(i-eval_window + 1 : i ).^2);
                p_error_refresh_val = max(mean(Q_error_refresh(i - eval_window + 1 : i ).^2), 1e-14);
            else
                p_quantized2 = mean(y_non_rec(1 : i ).^2);
                p_error_refresh_val = max(mean(Q_error_refresh(1 : i ).^2), 1e-14);
            end
            
            sqnr_now{C}(k, i) = 10*log10(p_quantized2/p_error_refresh_val);
            
            % Refresh every counter_size samples.
            if(i - start_idx >= counter_size) 
                y_refresh(i) =  round(sum(x_n(i : i + M - 1))/M * Trunc_coef(k))/Trunc_coef(k);
                Q_error_refresh(i) = y_refresh(i) - y_non_rec(i);  
                start_idx = i;
                counter_events{C}(k) = counter_events{C}(k) + 1;  
            end
        end
        % Calculate final SQNR for this counter size
valid_idx_refresh = 1:N-M+1;

p_signal = mean(y_non_rec(valid_idx_refresh).^2);
p_error = mean(Q_error_refresh(valid_idx_refresh).^2);

p_error = max(p_error, 1e-14);

sqnr_sweep(C,k) = 10*log10(p_signal/p_error);
    end
end

%% getting best results 
best_counter = zeros(1,length(T_power));
best_sqnr = zeros(1,length(T_power));
best_refreshes = zeros(1,length(T_power));

for k = 1:length(T_power)

    valid = find(sqnr_sweep(:,k) >= SQNR_target);

    if isempty(valid)

        best_counter(k) = NaN;
        best_sqnr(k) = NaN;
        best_refreshes(k) = NaN;

    else

        % Choose the largest counter that still satisfies SQNR target
        best_idx = valid(end);
        best_counter(k) = counter_sweep(best_idx);
        best_sqnr(k) = sqnr_sweep(best_idx,k);
        best_refreshes(k) = counter_events{best_idx}(k);

    end

end

%% Printables
valid_idx_non_rec = 1:N-M+1;
valid_idx_rec = 1:N-M+1;

fprintf('\n================== FINAL RESULTS FOR M = %d ==================\n', M);
fprintf('\n--- Baseline Forms ---\n');
for k = 1:length(T_power)     
    fprintf('Bits: %d | Non-Rec SQNR: %5.2f dB | Pure Rec SQNR: %5.2f dB\n', ...
        T_power(k)+1, mean(sqnr_db(k, valid_idx_non_rec)), mean(sqnr_db_rec(k, valid_idx_rec)));
end

fprintf('\n--- Refresh Solutions (Sweep Counter Size) ---\n');
for C = 1:length(counter_sweep)
    fprintf('\nCounter Wait Size: %d Samples\n', counter_sweep(C));
    for k = 1:length(T_power)
        fprintf('  Bits: %2d | Refresh SQNR: %5.2f dB | Refreshes Occurred: %d\n', ...
            T_power(k)+1, ...
            sqnr_sweep(C,k), ...
            counter_events{C}(k));
    end
end
fprintf('================================================================\n');



fprintf('\n--- Best Refresh Point ---\n');

for k = 1:length(T_power)

    fprintf('Bits: %2d | Best Counter: %4d | SQNR: %5.2f dB | Refreshes: %d\n', ...
        T_power(k)+1, ...
        best_counter(k), ...
        best_sqnr(k), ...
        best_refreshes(k));

end
%% Plots
% Non-recursive plot across all bits for M=32
figure;
for k = 1 : length(T_power)
    plot(time, sqnr_db(k , 1:N), 'DisplayName', ['Bits = ' num2str(T_power(k)+1)]);
    hold on ;
end
grid on;
xlabel('Time');
ylabel('SQNR (dB)');
title(['Non-Recursive Form for M = ' num2str(M)]);
legend('show');

% Recursive form
figure;
for k = 1 : length(T_power)
    plot(time, sqnr_db_rec(k , 1:N), 'DisplayName', ['Bits = ' num2str(T_power(k)+1)]);
    hold on;
end
grid on;
xlabel('Time');
ylabel('SQNR (dB) under recursion');
title('Recusrive form SQNR');
legend('show');

% Optimum Point Study: Compare different counter sizes for a fixed resolution (e.g., 10 bits)
figure;
test_bit_idx = find(T_power == 10); % corresponds to 11 bits (T_power=10 -> 10+1=11)
if ~isempty(test_bit_idx)
    for C = 1:length(counter_sweep)
        plot(time, sqnr_now{C}(test_bit_idx, 1:N), 'DisplayName', ['Counter = ' num2str(counter_sweep(C))]);
        hold on;
    end
end
grid on;
xlim([1000 50000]);
xlabel('Time');
ylabel('SQNR (dB)');
title(['Refresh Solution comparison at 11 Bits (M = ' num2str(M) ')']);
legend('show');

%% Test the sine

figure;
plot(time , x);
title('before filter');
xlim([0 500]);

figure;
plot(time , y_non_rec);
title('after filter using non recursive');
xlim([0 500]);

figure; 
plot(time , y_refresh);  
title('after filter using refreshed form');
xlim([0 500]);

figure;

for k = 1:length(T_power)
    plot(counter_sweep, sqnr_sweep(:,k), '-o', ...
        'DisplayName', ['Bits = ' num2str(T_power(k)+1)]);
    hold on;
end

yline(SQNR_target, '--', 'SQNR Target');

grid on;
xlabel('Refresh Interval (samples)');
ylabel('SQNR (dB)');
title(['SQNR vs Refresh Interval, M = ' num2str(M)]);
legend('show');


%% histogram
figure;
histogram(sqnr_now{1});
title('range of SQNR of the solution');

% The issue is the range of SQNR
% -->> solved by changing the way of calculating threshold and power window
% also check for no. of counts for hardware
% -->> under check 
% try to calculate theoretical SQNR



% Resource Folding (Serialization): If you must keep the full-sum refresh, do not instantiate M-1 parallel adders. 
%Instead, instantiate a single adder and a state machine. 
%When a refresh triggers, stall the incoming data and use that one adder over M clock cycles to accumulate the sum.
%  This trades latency for a massive reduction in physical combinational logic.


% Open-Loop Timer (Blind Refresh): Rip out the SQNR Monitor completely.
%  Power calculations require multipliers, which consume vast amounts of silicon real estate.
%  Replace the entire monitor and error estimator block with a simple integer counter that triggers the MUX every 64 or 128 cycles.
