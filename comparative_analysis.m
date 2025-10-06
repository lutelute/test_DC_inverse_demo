function comparative_analysis(results_file)
% 複数テストケースの比較分析と可視化
%
% 入力:
%   results_file - run_all_test_cases で生成された結果ファイル
%
% 使用法:
%   % 最新の結果ファイルを自動検索
%   comparative_analysis();
%   
%   % 特定の結果ファイルを指定
%   comparative_analysis('results/all_test_results_20241006_123456.mat');

if nargin < 1 || isempty(results_file)
    % 最新の結果ファイルを自動検索
    result_files = dir('results/all_test_results_*.mat');
    if isempty(result_files)
        error('結果ファイルが見つかりません。先に run_all_test_cases() を実行してください。');
    end
    [~, newest_idx] = max([result_files.datenum]);
    results_file = fullfile('results', result_files(newest_idx).name);
    fprintf('最新の結果ファイルを使用: %s\n', results_file);
end

% 結果データ読み込み
fprintf('\n=== DC潮流逆問題：比較分析 ===\n');
fprintf('結果ファイル読み込み中: %s\n', results_file);

data = load(results_file);
results = data.results;
timestamp = data.timestamp;

% 成功したケースのみ抽出
successful_results = results(strcmp({results.status}, 'success'));
n_success = length(successful_results);

if n_success == 0
    error('成功したテストケースがありません。');
end

fprintf('分析対象: %d個の成功ケース\n\n', n_success);

%% 1. システム規模による性能比較
create_scale_performance_analysis(successful_results, timestamp);

%% 2. 誤差分析
create_error_analysis(successful_results, timestamp);

%% 3. ノイズ感度比較
create_noise_sensitivity_comparison(successful_results, timestamp);

%% 4. 数値的安定性比較
create_numerical_stability_comparison(successful_results, timestamp);

%% 5. 実行時間分析
create_execution_time_analysis(successful_results, timestamp);

%% 6. 統合レポート生成
create_integrated_report(successful_results, timestamp);

fprintf('\n=== 比較分析完了 ===\n');
end

function create_scale_performance_analysis(results, timestamp)
% システム規模による性能比較

fprintf('1. システム規模による性能分析...\n');

% データ抽出
n_cases = length(results);
case_names = {results.case_name};
n_buses = zeros(n_cases, 1);
n_branches = zeros(n_cases, 1);
condition_numbers = zeros(n_cases, 1);
error_theta = zeros(n_cases, 1);
error_P = zeros(n_cases, 1);

for i = 1:n_cases
    n_buses(i) = results(i).config.buses;
    n_branches(i) = results(i).config.branches;
    condition_numbers(i) = results(i).basic.matrix_condition;
    error_theta(i) = results(i).basic.error_theta;
    error_P(i) = results(i).basic.error_P;
end

% プロット作成
fig1 = figure('Position', [100, 100, 1200, 800]);
fig1.Name = 'システム規模による性能比較';

% サブプロット1: バス数 vs 条件数
subplot(2, 3, 1);
loglog(n_buses, condition_numbers, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('バス数');
ylabel('条件数');
title('バス数 vs 行列条件数');
grid on;
for i = 1:n_cases
    text(n_buses(i), condition_numbers(i)*1.2, case_names{i}, ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% サブプロット2: バス数 vs 位相角誤差
subplot(2, 3, 2);
loglog(n_buses, error_theta, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('バス数');
ylabel('位相角相対誤差');
title('バス数 vs 位相角誤差');
grid on;
for i = 1:n_cases
    text(n_buses(i), error_theta(i)*1.2, case_names{i}, ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% サブプロット3: バス数 vs 電力誤差
subplot(2, 3, 3);
loglog(n_buses, error_P, 'go-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('バス数');
ylabel('電力相対誤差');
title('バス数 vs 電力誤差');
grid on;
for i = 1:n_cases
    text(n_buses(i), error_P(i)*1.2, case_names{i}, ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% サブプロット4: 過剰決定度分析
subplot(2, 3, 4);
overdetermined_ratio = n_branches ./ (n_buses - 1);
bar(1:n_cases, overdetermined_ratio, 'FaceColor', [0.7, 0.7, 0.9]);
xlabel('ケース');
ylabel('過剰決定度 (m/(n-1))');
title('過剰決定度比較');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% サブプロット5: 条件数 vs 誤差相関
subplot(2, 3, 5);
loglog(condition_numbers, error_P, 'mo', 'MarkerSize', 8, 'LineWidth', 2);
xlabel('条件数');
ylabel('電力相対誤差');
title('条件数 vs 電力誤差');
grid on;
for i = 1:n_cases
    text(condition_numbers(i), error_P(i)*1.2, case_names{i}, ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 理論的上界線を追加
cond_range = [min(condition_numbers), max(condition_numbers)];
theoretical_bound = 1e-16 * cond_range;  % 機械精度 × 条件数
hold on;
loglog(cond_range, theoretical_bound, 'k--', 'LineWidth', 1, 'DisplayName', '理論的下界');
legend;

% サブプロット6: 性能サマリー
subplot(2, 3, 6);
performance_scores = -log10(error_P);  % 誤差の逆対数（高いほど良い）
bar(1:n_cases, performance_scores, 'FaceColor', [0.9, 0.7, 0.7]);
xlabel('ケース');
ylabel('性能スコア (-log₁₀(誤差))');
title('性能スコア比較');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 数値表示
for i = 1:n_cases
    text(i, performance_scores(i) + 0.5, sprintf('%.1f', performance_scores(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 図を保存
saveas(fig1, sprintf('results/plots/scale_performance_analysis_%s.png', timestamp));
fprintf('  保存: scale_performance_analysis_%s.png\n', timestamp);
end

function create_error_analysis(results, timestamp)
% 誤差分析

fprintf('2. 誤差分析...\n');

n_cases = length(results);
case_names = {results.case_name};

% 各ケースの誤差データ抽出
error_data = zeros(n_cases, 3);  % θ, P, f
for i = 1:n_cases
    error_data(i, 1) = results(i).basic.error_theta;
    error_data(i, 2) = results(i).basic.error_P;
    error_data(i, 3) = results(i).basic.error_f;
end

fig2 = figure('Position', [150, 150, 1000, 600]);
fig2.Name = '誤差分析比較';

% 棒グラフでの誤差比較
subplot(1, 2, 1);
bar_handle = bar(error_data, 'grouped');
set(gca, 'YScale', 'log');
xlabel('テストケース');
ylabel('相対誤差');
title('各ケースの誤差比較');
legend({'位相角 θ', '電力注入 P', '枝潮流 f'}, 'Location', 'best');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 色設定
colors = [0.8, 0.4, 0.4; 0.4, 0.8, 0.4; 0.4, 0.4, 0.8];
for i = 1:3
    bar_handle(i).FaceColor = colors(i, :);
end

% ヒートマップでの誤差分布
subplot(1, 2, 2);
imagesc(log10(error_data'));
colorbar;
colormap('hot');
xlabel('テストケース');
ylabel('誤差タイプ');
title('誤差分布 (log₁₀スケール)');
set(gca, 'XTickLabel', case_names);
set(gca, 'YTickLabel', {'θ誤差', 'P誤差', 'f誤差'});
xtickangle(45);

% 数値表示
for i = 1:n_cases
    for j = 1:3
        text(i, j, sprintf('%.1f', log10(error_data(i, j))), ...
             'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

saveas(fig2, sprintf('results/plots/error_analysis_%s.png', timestamp));
fprintf('  保存: error_analysis_%s.png\n', timestamp);
end

function create_noise_sensitivity_comparison(results, timestamp)
% ノイズ感度比較

fprintf('3. ノイズ感度比較...\n');

n_cases = length(results);
case_names = {results.case_name};

fig3 = figure('Position', [200, 200, 1200, 800]);
fig3.Name = 'ノイズ感度比較';

% 各ケースのノイズデータを収集
subplot(2, 2, 1);
colors = lines(n_cases);
for i = 1:n_cases
    noise_data = results(i).noise;
    semilogx(noise_data.noise_levels, noise_data.success_rates, ...
             'o-', 'Color', colors(i, :), 'LineWidth', 2, 'MarkerSize', 6, ...
             'DisplayName', case_names{i});
    hold on;
end
xlabel('ノイズレベル');
ylabel('成功率 (%)');
title('ノイズ vs 成功率');
legend('Location', 'best');
grid on;

% 平均誤差 vs ノイズ
subplot(2, 2, 2);
for i = 1:n_cases
    noise_data = results(i).noise;
    loglog(noise_data.noise_levels, noise_data.mean_errors_P, ...
           'o-', 'Color', colors(i, :), 'LineWidth', 2, 'MarkerSize', 6, ...
           'DisplayName', case_names{i});
    hold on;
end
xlabel('ノイズレベル');
ylabel('平均電力誤差');
title('ノイズ vs 平均誤差');
legend('Location', 'best');
grid on;

% ノイズ耐性ランキング
subplot(2, 2, 3);
% 1%ノイズでの成功率を比較指標とする
noise_tolerance = zeros(n_cases, 1);
target_noise = 0.01;

for i = 1:n_cases
    noise_data = results(i).noise;
    [~, idx] = min(abs(noise_data.noise_levels - target_noise));
    noise_tolerance(i) = noise_data.success_rates(idx);
end

[sorted_tolerance, sort_idx] = sort(noise_tolerance, 'descend');
sorted_names = case_names(sort_idx);

bar(1:n_cases, sorted_tolerance, 'FaceColor', [0.6, 0.8, 0.6]);
xlabel('ランキング');
ylabel(sprintf('成功率 @%.1f%% ノイズ', target_noise*100));
title('ノイズ耐性ランキング');
set(gca, 'XTickLabel', sorted_names);
xtickangle(45);
grid on;

% 数値表示
for i = 1:n_cases
    text(i, sorted_tolerance(i) + 2, sprintf('%.1f%%', sorted_tolerance(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 条件数 vs ノイズ耐性
subplot(2, 2, 4);
condition_numbers = [results.basic];
condition_numbers = [condition_numbers.matrix_condition];
scatter(condition_numbers, noise_tolerance, 100, colors, 'filled');
xlabel('条件数');
ylabel(sprintf('成功率 @%.1f%% ノイズ', target_noise*100));
title('条件数 vs ノイズ耐性');
set(gca, 'XScale', 'log');
grid on;

% ケース名をラベル表示
for i = 1:n_cases
    text(condition_numbers(i), noise_tolerance(i), case_names{i}, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
end

saveas(fig3, sprintf('results/plots/noise_sensitivity_comparison_%s.png', timestamp));
fprintf('  保存: noise_sensitivity_comparison_%s.png\n', timestamp);
end

function create_numerical_stability_comparison(results, timestamp)
% 数値的安定性比較

fprintf('4. 数値的安定性比較...\n');

n_cases = length(results);
case_names = {results.case_name};

% 安定性指標の抽出
stability_metrics = zeros(n_cases, 4);  % 条件数, ランク, 最小特異値, 過剰決定度
for i = 1:n_cases
    stability_metrics(i, 1) = results(i).stability.condition_number;
    stability_metrics(i, 2) = results(i).stability.matrix_rank;
    stability_metrics(i, 3) = results(i).stability.min_singular_value;
    stability_metrics(i, 4) = results(i).stability.overdetermined_ratio;
end

fig4 = figure('Position', [250, 250, 1200, 600]);
fig4.Name = '数値的安定性比較';

% 条件数比較
subplot(2, 3, 1);
semilogy(1:n_cases, stability_metrics(:, 1), 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('ケース');
ylabel('条件数');
title('条件数比較');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 数値ランク vs 理論ランク
subplot(2, 3, 2);
theoretical_rank = [results.config];
theoretical_rank = [theoretical_rank.buses] - 1;  % n-1
bar(1:n_cases, [theoretical_rank; stability_metrics(:, 2)']', 'grouped');
xlabel('ケース');
ylabel('ランク');
title('理論ランク vs 数値ランク');
legend({'理論 (n-1)', '数値'}, 'Location', 'best');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 最小特異値
subplot(2, 3, 3);
semilogy(1:n_cases, stability_metrics(:, 3), 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('ケース');
ylabel('最小特異値');
title('最小特異値');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 過剰決定度
subplot(2, 3, 4);
bar(1:n_cases, stability_metrics(:, 4), 'FaceColor', [0.9, 0.7, 0.5]);
xlabel('ケース');
ylabel('過剰決定度 m/(n-1)');
title('過剰決定度');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 数値表示
for i = 1:n_cases
    text(i, stability_metrics(i, 4) + 0.05, sprintf('%.2f', stability_metrics(i, 4)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 特異値分布（最初の数ケース）
subplot(2, 3, 5);
colors = lines(min(n_cases, 4));
for i = 1:min(n_cases, 4)
    sv = results(i).stability.singular_values;
    semilogy(1:length(sv), sv, 'o-', 'Color', colors(i, :), ...
             'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', case_names{i});
    hold on;
end
xlabel('特異値インデックス');
ylabel('特異値');
title('特異値分布');
legend('Location', 'best');
grid on;

% 安定性スコア
subplot(2, 3, 6);
stability_score = -log10(stability_metrics(:, 1)) + log10(stability_metrics(:, 3));
bar(1:n_cases, stability_score, 'FaceColor', [0.7, 0.5, 0.9]);
xlabel('ケース');
ylabel('安定性スコア');
title('総合安定性スコア');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

saveas(fig4, sprintf('results/plots/numerical_stability_%s.png', timestamp));
fprintf('  保存: numerical_stability_%s.png\n', timestamp);
end

function create_execution_time_analysis(results, timestamp)
% 実行時間分析

fprintf('5. 実行時間分析...\n');

n_cases = length(results);
case_names = {results.case_name};
execution_times = [results.execution_time];
n_buses = [results.config];
n_buses = [n_buses.buses];

fig5 = figure('Position', [300, 300, 800, 600]);
fig5.Name = '実行時間分析';

% 実行時間比較
subplot(2, 2, 1);
bar(1:n_cases, execution_times, 'FaceColor', [0.8, 0.6, 0.4]);
xlabel('ケース');
ylabel('実行時間 [秒]');
title('実行時間比較');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 数値表示
for i = 1:n_cases
    text(i, execution_times(i) + max(execution_times)*0.02, ...
         sprintf('%.2fs', execution_times(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% バス数 vs 実行時間
subplot(2, 2, 2);
loglog(n_buses, execution_times, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('バス数');
ylabel('実行時間 [秒]');
title('バス数 vs 実行時間');
grid on;

% 理論的計算量 O(n³) の線を追加
n_range = [min(n_buses), max(n_buses)];
theoretical_time = execution_times(1) * (n_range/n_buses(1)).^3;
hold on;
loglog(n_range, theoretical_time, 'k--', 'LineWidth', 1, 'DisplayName', 'O(n³)');
legend;

% ケース名をラベル表示
for i = 1:n_cases
    text(n_buses(i), execution_times(i)*1.2, case_names{i}, ...
         'HorizontalAlignment', 'center', 'FontSize', 8);
end

% 効率性分析
subplot(2, 2, 3);
efficiency = execution_times ./ (n_buses.^2);  % 時間/バス²
bar(1:n_cases, efficiency, 'FaceColor', [0.6, 0.8, 0.8]);
xlabel('ケース');
ylabel('効率性 [秒/バス²]');
title('計算効率性');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

% 実行時間の詳細内訳（モック）
subplot(2, 2, 4);
% 実際には各処理の時間を測定する必要がある
setup_time = execution_times * 0.1;
computation_time = execution_times * 0.8;
output_time = execution_times * 0.1;

bar(1:n_cases, [setup_time; computation_time; output_time]', 'stacked');
xlabel('ケース');
ylabel('実行時間 [秒]');
title('実行時間内訳');
legend({'セットアップ', '計算', '出力'}, 'Location', 'best');
set(gca, 'XTickLabel', case_names);
xtickangle(45);
grid on;

saveas(fig5, sprintf('results/plots/execution_time_analysis_%s.png', timestamp));
fprintf('  保存: execution_time_analysis_%s.png\n', timestamp);
end

function create_integrated_report(results, timestamp)
% 統合レポート生成

fprintf('6. 統合レポート生成...\n');

report_file = sprintf('results/comparative_report_%s.txt', timestamp);
fid = fopen(report_file, 'w');

fprintf(fid, 'DC潮流逆問題：比較分析レポート\n');
fprintf(fid, '==================================\n\n');
fprintf(fid, '分析日時: %s\n', datestr(now));
fprintf(fid, '分析対象: %d個のテストケース\n\n', length(results));

% ケース概要
fprintf(fid, 'テストケース概要:\n');
fprintf(fid, '%-10s %6s %6s %6s %12s %12s %8s\n', ...
    'Case', 'Buses', 'Branch', 'Rank', 'Condition', 'P Error', 'Time[s]');
fprintf(fid, '%s\n', repmat('-', 1, 80));

for i = 1:length(results)
    r = results(i);
    fprintf(fid, '%-10s %6d %6d %6d %12.3e %12.3e %8.2f\n', ...
        r.case_name, r.config.buses, r.config.branches, ...
        r.stability.matrix_rank, r.basic.matrix_condition, ...
        r.basic.error_P, r.execution_time);
end

% 性能ランキング
fprintf(fid, '\n性能ランキング (電力誤差基準):\n');
[~, rank_idx] = sort([results.basic], 'ComparisonMethod', @(x,y) x.error_P < y.error_P);
for i = 1:length(results)
    r = results(rank_idx(i));
    fprintf(fid, '%d. %-10s (誤差: %.3e)\n', i, r.case_name, r.basic.error_P);
end

% ノイズ耐性ランキング
fprintf(fid, '\nノイズ耐性ランキング (1%%ノイズ成功率):\n');
noise_scores = zeros(length(results), 1);
for i = 1:length(results)
    noise_data = results(i).noise;
    [~, idx] = min(abs(noise_data.noise_levels - 0.01));
    noise_scores(i) = noise_data.success_rates(idx);
end
[~, noise_rank_idx] = sort(noise_scores, 'descend');
for i = 1:length(results)
    r = results(noise_rank_idx(i));
    fprintf(fid, '%d. %-10s (成功率: %.1f%%)\n', i, r.case_name, noise_scores(noise_rank_idx(i)));
end

% 推奨事項
fprintf(fid, '\n推奨事項:\n');
fprintf(fid, '- 高精度が必要な場合: %s\n', results(rank_idx(1)).case_name);
fprintf(fid, '- ノイズ環境での使用: %s\n', results(noise_rank_idx(1)).case_name);
fprintf(fid, '- 大規模システムのテスト: %s\n', results(end).case_name);

fclose(fid);
fprintf('  統合レポート保存: %s\n', report_file);
end