function run_all_test_cases(varargin)
% 全テストケースの自動実行とレポート生成
%
% 使用法:
%   run_all_test_cases()                    % 全ケース実行
%   run_all_test_cases('cases', {'case9'})  % 特定ケースのみ
%   run_all_test_cases('quick', true)       % 高速モード
%   run_all_test_cases('detailed', true)    % 詳細分析モード
%
% オプション:
%   'cases'     - 実行するケース名のセル配列（既定: 全ケース）
%   'quick'     - 高速モード（統計数削減）
%   'detailed'  - 詳細分析モード（追加検証）
%   'parallel'  - 並列実行（既定: false）
%   'save_plots'- プロット保存（既定: true）

% 引数解析
p = inputParser;
addParameter(p, 'cases', {}, @iscell);
addParameter(p, 'quick', false, @islogical);
addParameter(p, 'detailed', false, @islogical);
addParameter(p, 'parallel', false, @islogical);
addParameter(p, 'save_plots', true, @islogical);
parse(p, varargin{:});

opts = p.Results;

% テストケース設定読み込み
fprintf('=== DC潮流逆問題：全テストケース実行 ===\n\n');
config = test_case_config();

% 実行対象ケース決定
if isempty(opts.cases)
    test_cases = {config.name};
else
    test_cases = opts.cases;
    % 有効性チェック
    valid_cases = {config.name};
    invalid = setdiff(test_cases, valid_cases);
    if ~isempty(invalid)
        error('無効なテストケース: %s', strjoin(invalid, ', '));
    end
end

fprintf('実行対象ケース: %s\n', strjoin(test_cases, ', '));
fprintf('実行モード: %s\n', get_mode_description(opts));
fprintf('\n');

% 結果保存用構造体初期化
results = [];
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

% 並列処理設定
if opts.parallel && ~isempty(gcp('nocreate'))
    fprintf('並列処理プールを使用\n');
elseif opts.parallel
    fprintf('並列処理プール開始...\n');
    parpool('local');
end

%% 各テストケースの実行
total_start_time = tic;

for i = 1:length(test_cases)
    case_name = test_cases{i};
    case_config = config(strcmp({config.name}, case_name));
    
    fprintf('\n--- テストケース %d/%d: %s ---\n', i, length(test_cases), case_name);
    fprintf('説明: %s\n', case_config.description);
    fprintf('規模: %d buses, %d branches\n', case_config.buses, case_config.branches);
    
    case_start_time = tic;
    
    try
        % 個別ケーステスト実行
        case_result = run_single_test_case(case_name, case_config, opts);
        case_result.case_name = case_name;
        case_result.config = case_config;
        case_result.execution_time = toc(case_start_time);
        case_result.status = 'success';
        
        results(end+1) = case_result;
        
        fprintf('完了 (%.2f秒)\n', case_result.execution_time);
        
    catch ME
        fprintf('エラー: %s\n', ME.message);
        
        % エラー情報を記録
        error_result.case_name = case_name;
        error_result.config = case_config;
        error_result.execution_time = toc(case_start_time);
        error_result.status = 'error';
        error_result.error_message = ME.message;
        error_result.error_stack = ME.stack;
        
        results(end+1) = error_result;
    end
end

total_execution_time = toc(total_start_time);

%% 比較分析とレポート生成
fprintf('\n=== 比較分析とレポート生成 ===\n');

if opts.detailed
    generate_detailed_comparative_analysis(results, timestamp, opts);
end

generate_summary_report(results, total_execution_time, timestamp, opts);

if opts.save_plots
    generate_comparative_plots(results, timestamp, opts);
end

% 結果をMATファイルに保存
results_file = sprintf('results/all_test_results_%s.mat', timestamp);
save(results_file, 'results', 'timestamp', 'opts', 'config');
fprintf('結果保存: %s\n', results_file);

fprintf('\n=== 全テストケース完了 ===\n');
fprintf('総実行時間: %.2f秒\n', total_execution_time);
fprintf('成功: %d, エラー: %d\n', ...
    sum(strcmp({results.status}, 'success')), ...
    sum(strcmp({results.status}, 'error')));
end

function case_result = run_single_test_case(case_name, case_config, opts)
% 単一テストケースの実行

fprintf('  3ステップテスト実行中...\n');

% MATPOWER ケース読み込み
try
    mpc = loadcase(case_config.matpower_case);
catch ME
    error('MATPOWERケース "%s" の読み込み失敗: %s', case_config.matpower_case, ME.message);
end

% DC行列構築
[Bbus, Bf, ~, ~] = makeBdc(mpc);
nbus = size(mpc.bus, 1);
nbr = size(mpc.branch, 1);

% 基準バス
define_constants;
ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
if isempty(ref), ref = 1; end
keep = setdiff(1:nbus, ref);

% 基本性能テスト
fprintf('  基本性能テスト...\n');
basic_result = run_basic_performance_test(mpc, Bbus, Bf, ref, keep);

% ノイズ感度テスト
if opts.quick
    noise_levels = [0, 0.001, 0.01];
    n_trials = 20;
else
    noise_levels = [0, 0.0001, 0.001, 0.005, 0.01, 0.02, 0.05];
    n_trials = 100;
end

fprintf('  ノイズ感度テスト (%d trials)...\n', n_trials);
noise_result = run_noise_sensitivity_test(mpc, Bbus, Bf, ref, keep, noise_levels, n_trials);

% 数値的安定性テスト
fprintf('  数値的安定性テスト...\n');
stability_result = run_numerical_stability_test(mpc, Bbus, Bf, ref, keep);

% 結果統合
case_result = struct();
case_result.basic = basic_result;
case_result.noise = noise_result;
case_result.stability = stability_result;

% ケース別結果保存
case_dir = sprintf('test_cases/%s', case_name);
if ~exist(case_dir, 'dir'), mkdir(case_dir); end

result_file = sprintf('%s/result_%s.mat', case_dir, datestr(now, 'yyyymmdd_HHMMSS'));
save(result_file, 'case_result', 'case_config');

fprintf('  結果保存: %s\n', result_file);
end

function basic_result = run_basic_performance_test(mpc, Bbus, Bf, ref, keep)
% 基本性能テスト

% 真値生成
P_true = generate_test_injection(mpc, ref);
theta_true = zeros(size(mpc.bus, 1), 1);
theta_true(keep) = Bbus(keep, keep) \ P_true(keep);
f_true = Bf * theta_true;

% 逆推定
theta_hat = zeros(size(mpc.bus, 1), 1);
theta_hat(keep) = Bf(:, keep) \ f_true;
P_hat = Bbus * theta_hat;
f_hat = Bf * theta_hat;

% 誤差計算
rel_error = @(x, x_true) norm(x - x_true) / max(norm(x_true), 1e-12);

basic_result = struct();
basic_result.error_theta = rel_error(theta_hat, theta_true);
basic_result.error_P = rel_error(P_hat, P_true);
basic_result.error_f = rel_error(f_hat, f_true);
basic_result.residual_norm = norm(Bf * theta_hat - f_true);
basic_result.matrix_condition = cond(full(Bf(:, keep)));
basic_result.matrix_rank = rank(full(Bf(:, keep)));
basic_result.power_balance = abs(sum(P_true));
end

function noise_result = run_noise_sensitivity_test(mpc, Bbus, Bf, ref, keep, noise_levels, n_trials)
% ノイズ感度テスト

n_noise = length(noise_levels);
success_rates = zeros(n_noise, 1);
mean_errors_theta = zeros(n_noise, 1);
mean_errors_P = zeros(n_noise, 1);
std_errors_theta = zeros(n_noise, 1);
std_errors_P = zeros(n_noise, 1);

tolerance = 1e-6;

for i = 1:n_noise
    noise_sigma = noise_levels(i);
    errors_theta = zeros(n_trials, 1);
    errors_P = zeros(n_trials, 1);
    successes = 0;
    
    for trial = 1:n_trials
        try
            % 真値生成
            P_true = generate_test_injection(mpc, ref);
            theta_true = zeros(size(mpc.bus, 1), 1);
            theta_true(keep) = Bbus(keep, keep) \ P_true(keep);
            f_true = Bf * theta_true;
            
            % ノイズ追加
            if noise_sigma > 0
                f_noisy = f_true + noise_sigma * randn(size(f_true)) * norm(f_true);
            else
                f_noisy = f_true;
            end
            
            % 逆推定
            theta_hat = zeros(size(mpc.bus, 1), 1);
            theta_hat(keep) = Bf(:, keep) \ f_noisy;
            P_hat = Bbus * theta_hat;
            
            % 誤差計算
            rel_error = @(x, x_true) norm(x - x_true) / max(norm(x_true), 1e-12);
            err_theta = rel_error(theta_hat, theta_true);
            err_P = rel_error(P_hat, P_true);
            
            errors_theta(trial) = err_theta;
            errors_P(trial) = err_P;
            
            if err_theta < tolerance && err_P < tolerance
                successes = successes + 1;
            end
            
        catch
            errors_theta(trial) = inf;
            errors_P(trial) = inf;
        end
    end
    
    success_rates(i) = successes / n_trials * 100;
    mean_errors_theta(i) = mean(errors_theta(~isinf(errors_theta)));
    mean_errors_P(i) = mean(errors_P(~isinf(errors_P)));
    std_errors_theta(i) = std(errors_theta(~isinf(errors_theta)));
    std_errors_P(i) = std(errors_P(~isinf(errors_P)));
end

noise_result = struct();
noise_result.noise_levels = noise_levels;
noise_result.success_rates = success_rates;
noise_result.mean_errors_theta = mean_errors_theta;
noise_result.mean_errors_P = mean_errors_P;
noise_result.std_errors_theta = std_errors_theta;
noise_result.std_errors_P = std_errors_P;
end

function stability_result = run_numerical_stability_test(mpc, Bbus, Bf, ref, keep)
% 数値的安定性テスト

% 行列の数値的性質
A_ls = Bf(:, keep);
cond_number = cond(full(A_ls));
rank_A = rank(full(A_ls));
[m, n] = size(A_ls);

% 特異値分解
[U, S, V] = svd(full(A_ls));
singular_values = diag(S);
min_sv = min(singular_values);
max_sv = max(singular_values);

% 疑似逆条件数
pinv_cond = max_sv / min_sv;

stability_result = struct();
stability_result.condition_number = cond_number;
stability_result.matrix_rank = rank_A;
stability_result.overdetermined_ratio = m / n;
stability_result.singular_values = singular_values;
stability_result.min_singular_value = min_sv;
stability_result.max_singular_value = max_sv;
stability_result.pinv_condition = pinv_cond;
stability_result.numerical_rank = rank(full(A_ls), 1e-12);
end

function mode_desc = get_mode_description(opts)
% 実行モードの説明文生成
modes = {};
if opts.quick, modes{end+1} = '高速'; end
if opts.detailed, modes{end+1} = '詳細'; end
if opts.parallel, modes{end+1} = '並列'; end
if isempty(modes)
    mode_desc = '標準';
else
    mode_desc = strjoin(modes, '+');
end
end

function generate_summary_report(results, total_time, timestamp, opts)
% サマリーレポート生成
report_file = sprintf('results/summary_report_%s.txt', timestamp);
fid = fopen(report_file, 'w');

fprintf(fid, 'DC潮流逆問題：全テストケース実行レポート\n');
fprintf(fid, '============================================\n\n');
fprintf(fid, '実行日時: %s\n', datestr(now));
fprintf(fid, '総実行時間: %.2f秒\n', total_time);
fprintf(fid, '実行モード: %s\n\n', get_mode_description(opts));

% 成功/失敗統計
successful = strcmp({results.status}, 'success');
n_success = sum(successful);
n_error = sum(~successful);

fprintf(fid, '実行統計:\n');
fprintf(fid, '- 成功: %d ケース\n', n_success);
fprintf(fid, '- エラー: %d ケース\n', n_error);
fprintf(fid, '- 成功率: %.1f%%\n\n', n_success/(n_success+n_error)*100);

% 各ケースの結果
fprintf(fid, '各ケース結果:\n');
fprintf(fid, '%-10s %-8s %-12s %-12s %-12s %-8s\n', ...
    'Case', 'Status', 'θ Error', 'P Error', 'Condition', 'Time[s]');
fprintf(fid, '%s\n', repmat('-', 1, 70));

for i = 1:length(results)
    r = results(i);
    if strcmp(r.status, 'success')
        fprintf(fid, '%-10s %-8s %-12.3e %-12.3e %-12.3e %-8.2f\n', ...
            r.case_name, r.status, r.basic.error_theta, r.basic.error_P, ...
            r.basic.matrix_condition, r.execution_time);
    else
        fprintf(fid, '%-10s %-8s %-12s %-12s %-12s %-8.2f\n', ...
            r.case_name, r.status, 'ERROR', 'ERROR', 'ERROR', r.execution_time);
    end
end

fclose(fid);
fprintf('サマリーレポート保存: %s\n', report_file);
end

function generate_detailed_comparative_analysis(results, timestamp, opts)
% 詳細比較分析（実装スケルトン）
fprintf('詳細比較分析を実行中...\n');
% TODO: 詳細分析の実装
end

function generate_comparative_plots(results, timestamp, opts)
% 比較プロット生成（実装スケルトン）
fprintf('比較プロット生成中...\n');
% TODO: プロット生成の実装
end

function P = generate_test_injection(mpc, ref)
% テスト用電力注入生成
define_constants;
nbus = size(mpc.bus, 1);
baseMVA = mpc.baseMVA;

% ケースデータベース
Pg_bus = accumarray(mpc.gen(:, GEN_BUS), mpc.gen(:, PG), [nbus, 1], @sum, 0);
Pg_pu = Pg_bus / baseMVA;
Pd_pu = mpc.bus(:, PD) / baseMVA;

% 少し変動を加える
scale = 0.9 + 0.2 * rand(nbus, 1);
P = (Pg_pu .* scale) - (Pd_pu .* scale);

% 電力収支調整
P(ref) = P(ref) - sum(P);
end