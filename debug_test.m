function debug_test()
% デバッグ用の簡単なテスト

fprintf('=== デバッグテスト開始 ===\n');

% テスト設定読み込み
addpath('test_cases');
config = test_case_config();

% case9のみテスト
case_name = 'case9';
case_config = config(strcmp({config.name}, case_name));

fprintf('ケース: %s\n', case_name);
fprintf('説明: %s\n', case_config.description);

try
    % MATPOWER ケース読み込み
    mpc = loadcase(case_config.matpower_case);
    fprintf('MATPOWER読み込み成功\n');
    
    % DC行列構築
    [Bbus, Bf, ~, ~] = makeBdc(mpc);
    fprintf('DC行列構築成功\n');
    
    % 基本情報
    nbus = size(mpc.bus, 1);
    nbr = size(mpc.branch, 1);
    define_constants;
    ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
    if isempty(ref), ref = 1; end
    keep = setdiff(1:nbus, ref);
    
    fprintf('バス数: %d, ブランチ数: %d, 基準バス: %d\n', nbus, nbr, ref);
    
    % 基本性能テスト
    fprintf('基本性能テスト実行中...\n');
    basic_result = run_basic_performance_test_debug(mpc, Bbus, Bf, ref, keep);
    
    fprintf('基本性能テスト結果:\n');
    fprintf('- 位相角誤差: %.3e\n', basic_result.error_theta);
    fprintf('- 電力誤差: %.3e\n', basic_result.error_P);
    fprintf('- 潮流誤差: %.3e\n', basic_result.error_f);
    fprintf('- 条件数: %.3e\n', basic_result.matrix_condition);
    
    fprintf('=== デバッグテスト成功 ===\n');
    
catch ME
    fprintf('エラー: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('エラー位置: %s:%d\n', ME.stack(1).name, ME.stack(1).line);
    end
end
end

function basic_result = run_basic_performance_test_debug(mpc, Bbus, Bf, ref, keep)
% デバッグ用基本性能テスト

% 真値生成
P_true = generate_test_injection_debug(mpc, ref);
theta_true = zeros(size(mpc.bus, 1), 1);
theta_true(keep) = Bbus(keep, keep) \ P_true(keep);
f_true = Bf * theta_true;

fprintf('  真値生成完了\n');

% 逆推定
theta_hat = zeros(size(mpc.bus, 1), 1);
theta_hat(keep) = Bf(:, keep) \ f_true;
P_hat = Bbus * theta_hat;
f_hat = Bf * theta_hat;

fprintf('  逆推定完了\n');

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

fprintf('  誤差計算完了\n');
end

function P = generate_test_injection_debug(mpc, ref)
% デバッグ用電力注入生成
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