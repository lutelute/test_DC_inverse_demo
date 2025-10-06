function visualize_inverse_process()
% DC潮流逆問題の3ステップ可視化
%
% 目的：
% 1. ステップ1: P* → θ* → f* の順方向過程を可視化
% 2. ステップ2: f* → θ̂ → P̂ の逆方向過程を可視化  
% 3. ステップ3: 真値との比較を可視化
% 4. 数学的構造（行列、誤差分布）を可視化

fprintf('\n=== DC潮流逆問題：可視化デモ ===\n');

% ケース読み込み
mpc = loadcase('case9');
[Bbus, Bf, ~, ~] = makeBdc(mpc);

% 基本設定
nbus = size(mpc.bus, 1);
nbr = size(mpc.branch, 1);
define_constants;
ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
if isempty(ref), ref = 1; end
keep = setdiff(1:nbus, ref);

% メイン図
fig = figure('Position', [100, 100, 1200, 900]);
fig.Name = 'DC潮流逆問題：3ステップ可視化';

%% ステップ1: 順方向過程の可視化
% 真値生成
P_star = generate_true_injection(mpc, ref);
theta_star = zeros(nbus, 1);
theta_star(keep) = Bbus(keep,keep) \ P_star(keep);
f_star = Bf * theta_star;

% 図1: 電力注入分布
subplot(2, 4, 1);
bar(1:nbus, P_star, 'FaceColor', [0.2, 0.6, 0.8]);
title('ステップ1: 真の電力注入 P*');
xlabel('バス番号');
ylabel('電力注入 [pu]');
grid on;
for i = 1:nbus
    text(i, P_star(i) + sign(P_star(i))*0.02, sprintf('%.3f', P_star(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 図2: 位相角分布
subplot(2, 4, 2);
bar(1:nbus, theta_star*180/pi, 'FaceColor', [0.8, 0.4, 0.2]);
title('ステップ1: 真の位相角 θ*');
xlabel('バス番号');
ylabel('位相角 [度]');
grid on;
for i = 1:nbus
    text(i, theta_star(i)*180/pi + sign(theta_star(i))*0.2, sprintf('%.2f°', theta_star(i)*180/pi), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 図3: 枝潮流分布  
subplot(2, 4, 3);
bar(1:nbr, f_star, 'FaceColor', [0.6, 0.8, 0.3]);
title('ステップ1: 真の枝潮流 f*');
xlabel('ブランチ番号');
ylabel('潮流 [pu]');
grid on;
for i = 1:nbr
    text(i, f_star(i) + sign(f_star(i))*0.01, sprintf('%.3f', f_star(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

%% ステップ2: 逆推定過程の可視化
% 逆推定
theta_hat = zeros(nbus, 1);
theta_hat(keep) = Bf(:,keep) \ f_star;
P_hat = Bbus * theta_hat;
f_hat = Bf * theta_hat;

% 図4: 推定位相角
subplot(2, 4, 4);
bar(1:nbus, theta_hat*180/pi, 'FaceColor', [0.8, 0.2, 0.4]);
title('ステップ2: 推定位相角 θ̂');
xlabel('バス番号');
ylabel('位相角 [度]');
grid on;
for i = 1:nbus
    text(i, theta_hat(i)*180/pi + sign(theta_hat(i))*0.2, sprintf('%.2f°', theta_hat(i)*180/pi), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

%% ステップ3: 比較可視化
% 図5: 電力注入比較
subplot(2, 4, 5);
x = 1:nbus;
width = 0.35;
bar(x - width/2, P_star, width, 'FaceColor', [0.2, 0.6, 0.8], 'DisplayName', 'P* (真値)');
hold on;
bar(x + width/2, P_hat, width, 'FaceColor', [0.8, 0.2, 0.4], 'DisplayName', 'P̂ (推定)');
title('ステップ3: 電力注入比較');
xlabel('バス番号');
ylabel('電力注入 [pu]');
legend;
grid on;

% 図6: 位相角比較
subplot(2, 4, 6);
bar(x - width/2, theta_star*180/pi, width, 'FaceColor', [0.8, 0.4, 0.2], 'DisplayName', 'θ* (真値)');
hold on;
bar(x + width/2, theta_hat*180/pi, width, 'FaceColor', [0.8, 0.2, 0.4], 'DisplayName', 'θ̂ (推定)');
title('ステップ3: 位相角比較');
xlabel('バス番号');
ylabel('位相角 [度]');
legend;
grid on;

% 図7: 枝潮流比較
subplot(2, 4, 7);
x_br = 1:nbr;
bar(x_br - width/2, f_star, width, 'FaceColor', [0.6, 0.8, 0.3], 'DisplayName', 'f* (真値)');
hold on;
bar(x_br + width/2, f_hat, width, 'FaceColor', [0.8, 0.2, 0.4], 'DisplayName', 'f̂ (推定)');
title('ステップ3: 枝潮流比較');
xlabel('ブランチ番号');
ylabel('潮流 [pu]');
legend;
grid on;

% 図8: 誤差分布
subplot(2, 4, 8);
errors = [
    norm(theta_hat - theta_star);
    norm(P_hat - P_star);
    norm(f_hat - f_star)
];
error_labels = {'θ誤差', 'P誤差', 'f誤差'};
colors = [0.8, 0.4, 0.2; 0.2, 0.6, 0.8; 0.6, 0.8, 0.3];

bar_handle = bar(1:3, errors, 'FaceColor', 'flat');
bar_handle.CData = colors;
title('ステップ3: 誤差統計');
ylabel('L2ノルム誤差');
set(gca, 'XTickLabel', error_labels);
grid on;
set(gca, 'YScale', 'log');

% 数値表示
for i = 1:3
    text(i, errors(i)*1.5, sprintf('%.2e', errors(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 図を保存
saveas(fig, 'dc_inverse_3steps_visualization.png');
fprintf('可視化結果を保存: dc_inverse_3steps_visualization.png\n');

%% 行列構造の可視化
create_matrix_structure_plot(Bbus, Bf, keep, ref);

%% 誤差解析の可視化  
create_error_analysis_plot(mpc);

%% ネットワーク図の可視化
create_network_diagram(mpc, P_star, f_star);

fprintf('\n=== 可視化完了 ===\n');
end

function create_matrix_structure_plot(Bbus, Bf, keep, ref)
% 行列構造の可視化

fig2 = figure('Position', [150, 150, 1000, 400]);
fig2.Name = 'DC潮流逆問題：行列構造';

% Bbus行列の可視化
subplot(1, 3, 1);
imagesc(abs(Bbus));
colorbar;
title('|B_{bus}| 行列構造');
xlabel('バス番号');
ylabel('バス番号');
colormap(gca, 'hot');

% 基準バスの行・列をハイライト
hold on;
plot([ref-0.5, ref+0.5, ref+0.5, ref-0.5, ref-0.5], ...
     [ref-0.5, ref-0.5, ref+0.5, ref+0.5, ref-0.5], 'c-', 'LineWidth', 2);

% Bf行列の可視化
subplot(1, 3, 2);
imagesc(abs(Bf));
colorbar;
title('|B_f| 行列構造');
xlabel('バス番号');
ylabel('ブランチ番号');
colormap(gca, 'hot');

% 非基準バス列をハイライト
hold on;
for k = keep
    plot([k-0.5, k-0.5, k+0.5, k+0.5, k-0.5], ...
         [0.5, size(Bf,1)+0.5, size(Bf,1)+0.5, 0.5, 0.5], 'c-', 'LineWidth', 1);
end

% 縮約行列 Bf(:,keep) の可視化
subplot(1, 3, 3);
imagesc(abs(Bf(:, keep)));
colorbar;
title('|B_f(:,keep)| 縮約行列');
xlabel('非基準バス番号');
ylabel('ブランチ番号');
colormap(gca, 'hot');

% 数値情報を追加
dim_text = sprintf('サイズ: %dx%d\nrank: %d\ncond: %.2e', ...
    size(Bf(:,keep)), rank(full(Bf(:,keep))), cond(full(Bf(:,keep))));
text(0.02, 0.98, dim_text, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
     'BackgroundColor', 'white', 'FontSize', 8);

saveas(fig2, 'matrix_structure_visualization.png');
fprintf('行列構造可視化を保存: matrix_structure_visualization.png\n');
end

function create_error_analysis_plot(mpc)
% 誤差解析の可視化

fig3 = figure('Position', [200, 200, 1000, 600]);
fig3.Name = 'DC潮流逆問題：誤差解析';

% ノイズレベルに対する誤差変化
noise_levels = logspace(-12, -2, 20);
n_trials = 50;
errors_theta = zeros(length(noise_levels), n_trials);
errors_P = zeros(length(noise_levels), n_trials);

[Bbus, Bf, ~, ~] = makeBdc(mpc);
define_constants;
ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
if isempty(ref), ref = 1; end
keep = setdiff(1:size(mpc.bus,1), ref);

for i = 1:length(noise_levels)
    noise_sigma = noise_levels(i);
    
    for trial = 1:n_trials
        % 真値生成
        P_true = generate_true_injection(mpc, ref);
        theta_true = zeros(size(mpc.bus,1), 1);
        theta_true(keep) = Bbus(keep,keep) \ P_true(keep);
        f_true = Bf * theta_true;
        
        % ノイズ追加
        f_noisy = f_true + noise_sigma * randn(size(f_true)) * norm(f_true);
        
        % 逆推定
        theta_est = zeros(size(mpc.bus,1), 1);
        theta_est(keep) = Bf(:,keep) \ f_noisy;
        P_est = Bbus * theta_est;
        
        % 誤差記録
        errors_theta(i, trial) = norm(theta_est - theta_true) / norm(theta_true);
        errors_P(i, trial) = norm(P_est - P_true) / norm(P_true);
    end
end

% 統計値計算
mean_err_theta = mean(errors_theta, 2);
std_err_theta = std(errors_theta, 0, 2);
mean_err_P = mean(errors_P, 2);
std_err_P = std(errors_P, 0, 2);

% プロット
subplot(2, 2, 1);
loglog(noise_levels, mean_err_theta, 'b-', 'LineWidth', 2);
hold on;
loglog(noise_levels, mean_err_theta + std_err_theta, 'b--', 'LineWidth', 1);
loglog(noise_levels, max(mean_err_theta - std_err_theta, 1e-16), 'b--', 'LineWidth', 1);
grid on;
xlabel('ノイズレベル');
ylabel('位相角相対誤差');
title('ノイズ vs 位相角誤差');
legend('平均', '±1σ', 'Location', 'best');

subplot(2, 2, 2);
loglog(noise_levels, mean_err_P, 'r-', 'LineWidth', 2);
hold on;
loglog(noise_levels, mean_err_P + std_err_P, 'r--', 'LineWidth', 1);
loglog(noise_levels, max(mean_err_P - std_err_P, 1e-16), 'r--', 'LineWidth', 1);
grid on;
xlabel('ノイズレベル');
ylabel('電力注入相対誤差');
title('ノイズ vs 電力誤差');
legend('平均', '±1σ', 'Location', 'best');

% 条件数の影響
subplot(2, 2, 3);
cond_num = cond(full(Bf(:, keep)));
theoretical_amplification = cond_num * noise_levels;
loglog(noise_levels, theoretical_amplification, 'k--', 'LineWidth', 2, 'DisplayName', '理論値');
hold on;
loglog(noise_levels, mean_err_theta, 'b-', 'LineWidth', 2, 'DisplayName', '実測値');
grid on;
xlabel('ノイズレベル');
ylabel('誤差増幅率');
title('理論 vs 実測誤差');
legend;

% 残差分布
subplot(2, 2, 4);
P_test = generate_true_injection(mpc, ref);
theta_test = zeros(size(mpc.bus,1), 1);
theta_test(keep) = Bbus(keep,keep) \ P_test(keep);
f_test = Bf * theta_test;
theta_recon = zeros(size(mpc.bus,1), 1);
theta_recon(keep) = Bf(:,keep) \ f_test;
residual = Bf * theta_recon - f_test;

histogram(residual, 20, 'Normalization', 'pdf');
xlabel('残差 [pu]');
ylabel('確率密度');
title('最小二乗残差分布');
grid on;

saveas(fig3, 'error_analysis_visualization.png');
fprintf('誤差解析可視化を保存: error_analysis_visualization.png\n');
end

function create_network_diagram(mpc, P_star, f_star)
% ネットワーク図の可視化

fig4 = figure('Position', [250, 250, 800, 600]);
fig4.Name = 'DC潮流逆問題：ネットワーク図';

define_constants;

% バス座標（IEEE 9-bus用の手動配置）
if size(mpc.bus, 1) == 9
    bus_coords = [
        2, 3;    % Bus 1
        1, 2;    % Bus 2  
        3, 2;    % Bus 3
        2, 1;    % Bus 4
        1, 1;    % Bus 5
        3, 1;    % Bus 6
        1, 0;    % Bus 7
        2, 0;    % Bus 8
        3, 0     % Bus 9
    ];
else
    % 一般的な円形配置
    angles = linspace(0, 2*pi, size(mpc.bus,1)+1);
    angles = angles(1:end-1);
    bus_coords = [cos(angles)', sin(angles)'];
end

% ブランチ描画
for i = 1:size(mpc.branch, 1)
    from_bus = mpc.branch(i, F_BUS);
    to_bus = mpc.branch(i, T_BUS);
    
    x_coords = [bus_coords(from_bus, 1), bus_coords(to_bus, 1)];
    y_coords = [bus_coords(from_bus, 2), bus_coords(to_bus, 2)];
    
    % 潮流の大きさで線の太さを調整
    line_width = max(1, 3 * abs(f_star(i)) / max(abs(f_star)));
    
    % 潮流の方向で色を調整
    if f_star(i) > 0
        line_color = [0.8, 0.2, 0.2];  % 正方向: 赤
    else
        line_color = [0.2, 0.2, 0.8];  % 負方向: 青
    end
    
    line(x_coords, y_coords, 'LineWidth', line_width, 'Color', line_color);
    hold on;
    
    % 潮流値を表示
    mid_x = mean(x_coords);
    mid_y = mean(y_coords);
    text(mid_x, mid_y, sprintf('%.2f', f_star(i)), ...
         'HorizontalAlignment', 'center', 'BackgroundColor', 'white', ...
         'FontSize', 8);
end

% バス描画
for i = 1:size(mpc.bus, 1)
    x = bus_coords(i, 1);
    y = bus_coords(i, 2);
    
    % 電力注入の大きさで円のサイズを調整
    circle_size = max(100, 500 * abs(P_star(i)) / max(abs(P_star)));
    
    % 電力注入の符号で色を調整
    if P_star(i) > 0
        circle_color = [0.2, 0.8, 0.2];  % 発電: 緑
    else
        circle_color = [0.8, 0.8, 0.2];  % 負荷: 黄
    end
    
    scatter(x, y, circle_size, circle_color, 'filled', 'MarkerEdgeColor', 'black');
    
    % バス番号を表示
    text(x, y, sprintf('%d', i), 'HorizontalAlignment', 'center', ...
         'FontWeight', 'bold', 'FontSize', 10);
    
    % 電力注入値を表示
    text(x, y-0.15, sprintf('%.3f', P_star(i)), 'HorizontalAlignment', 'center', ...
         'FontSize', 8, 'BackgroundColor', 'white');
end

title('IEEE 9-bus DC潮流逆問題');
xlabel('X座標');
ylabel('Y座標');
grid on;
axis equal;

% 凡例
legend_text = {
    '正潮流 (赤)', '負潮流 (青)', 
    '発電 (緑)', '負荷 (黄)'
};
text(0.02, 0.98, sprintf('%s\n%s\n%s\n%s', legend_text{:}), ...
     'Units', 'normalized', 'VerticalAlignment', 'top', ...
     'BackgroundColor', 'white', 'FontSize', 9);

saveas(fig4, 'network_diagram_visualization.png');
fprintf('ネットワーク図可視化を保存: network_diagram_visualization.png\n');
end

function P = generate_true_injection(mpc, ref)
% 真の電力注入パターンを生成
define_constants;
nbus = size(mpc.bus, 1);
baseMVA = mpc.baseMVA;

% 発電量
Pg_bus = accumarray(mpc.gen(:, GEN_BUS), mpc.gen(:, PG), [nbus, 1], @sum, 0);
Pg_pu = Pg_bus / baseMVA;

% 負荷
Pd_pu = mpc.bus(:, PD) / baseMVA;

% ネット注入
P = Pg_pu - Pd_pu;

% 電力収支調整
imbalance = sum(P);
P(ref) = P(ref) - imbalance;
end