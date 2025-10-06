function dc_inverse_three_steps()
% DC潮流逆問題の明確な3ステップ実装
%
% 目的：
%   1. 真値生成：任意の母線注入 P* (3G・3L) から順方向DC潮流で θ*, f* を作る
%   2. 逆推定：f* のみを用いて θ̂, P̂ を復元
%   3. 検証：P̂ ≈ P*, f̂ = Bf*θ̂ ≈ f* を数値で確認
%
% 数式（DC近似）：
%   • 枝潮流 f = Bf*θ,  Bf = diag(b)*A
%   • 母線注入 P = Bbus*θ, Bbus = A^T*diag(b)*A  
%   • 基準角 θ_ref = 0
%   • 逆問題: θ̂ = argmin ||Bf*θ - f*||₂² s.t. θ_ref = 0
%   •         P̂ = Bbus*θ̂

fprintf('\n=== DC潮流逆問題：3ステップ実装 ===\n');

% IEEE 9-busケースを使用（3G・3Lの典型例）
mpc = loadcase('case9');
fprintf('使用ケース: IEEE 9-bus (3G・3L)\n');
fprintf('- バス数: %d\n', size(mpc.bus,1));
fprintf('- ブランチ数: %d\n', size(mpc.branch,1));
fprintf('- 発電機数: %d\n', size(mpc.gen,1));

% DC行列の構築
[Bbus, Bf, Pfinj, Pbus] = makeBdc(mpc);
nbus = size(mpc.bus,1);
nbr = size(mpc.branch,1);

% 基準バス設定
define_constants;
ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
if isempty(ref), ref = 1; end
keep = setdiff(1:nbus, ref);  % 基準バス以外

fprintf('基準バス: %d\n', ref);
fprintf('非基準バス: [%s]\n', num2str(keep));

fprintf('\n--- 行列サイズ確認 ---\n');
fprintf('Bbus: %dx%d\n', size(Bbus));
fprintf('Bf: %dx%d\n', size(Bf));
fprintf('Bbus(keep,keep): %dx%d\n', size(Bbus(keep,keep)));
fprintf('Bf(:,keep): %dx%d\n', size(Bf(:,keep)));

%% ステップ1: 真値生成
fprintf('\n=== ステップ1: 真値生成 P* → θ* → f* ===\n');

% ケース内のPG/PDから任意のP*を生成
P_star = generate_true_injection(mpc, ref);

fprintf('生成されたP* [pu]:\n');
print_vector_with_index('P*', P_star, 'Bus');

% 順方向DC潮流: P* → θ*
theta_star = zeros(nbus, 1);
theta_star(keep) = Bbus(keep, keep) \ P_star(keep);
theta_star(ref) = 0;  % 基準角

fprintf('\n計算されたθ* [rad]:\n');
print_vector_with_index('θ*', theta_star, 'Bus');

% 順方向DC潮流: θ* → f*
f_star = Bf * theta_star;

fprintf('\n計算されたf* [pu]:\n');
print_branch_flows(mpc, f_star, 'f*');

% 検証：P = Bbus*θ が成立するか
P_check = Bbus * theta_star;
fprintf('\n--- ステップ1検証 ---\n');
fprintf('||Bbus*θ* - P*||₂ = %.3e\n', norm(P_check - P_star));
fprintf('sum(P*) = %.3e (理想的には0)\n', sum(P_star));

%% ステップ2: 逆推定
fprintf('\n=== ステップ2: 逆推定 f* → θ̂ → P̂ ===\n');

% f*のみから最小二乗でθ̂を求める
% min ||Bf*θ - f*||₂² s.t. θ_ref = 0
fprintf('逆問題の定式化:\n');
fprintf('  min ||Bf*θ - f*||₂²\n');
fprintf('  s.t. θ_ref = 0\n');
fprintf('  ⇒ θ̂(keep) = Bf(:,keep) \\ f*\n');

theta_hat = zeros(nbus, 1);
theta_hat(keep) = Bf(:, keep) \ f_star;  % 最小二乗解
theta_hat(ref) = 0;  % 基準角制約

fprintf('\n推定されたθ̂ [rad]:\n');
print_vector_with_index('θ̂', theta_hat, 'Bus');

% θ̂からP̂を計算
P_hat = Bbus * theta_hat;

fprintf('\n推定されたP̂ [pu]:\n');
print_vector_with_index('P̂', P_hat, 'Bus');

% θ̂からf̂を計算（検証用）
f_hat = Bf * theta_hat;

fprintf('\n推定されたf̂ [pu]:\n');
print_branch_flows(mpc, f_hat, 'f̂');

%% ステップ3: 検証
fprintf('\n=== ステップ3: 数値検証 ===\n');

% 相対誤差計算関数
rel_error = @(x, x_true) norm(x - x_true) / max(norm(x_true), 1e-12);

% 各量の誤差
err_theta = rel_error(theta_hat, theta_star);
err_P = rel_error(P_hat, P_star);
err_f = rel_error(f_hat, f_star);

fprintf('相対誤差:\n');
fprintf('  θ̂ vs θ*: %.3e\n', err_theta);
fprintf('  P̂ vs P*: %.3e\n', err_P);
fprintf('  f̂ vs f*: %.3e\n', err_f);

% 詳細比較テーブル
fprintf('\n--- 詳細比較 ---\n');
fprintf('\n母線注入比較:\n');
fprintf('Bus    P* [pu]      P̂ [pu]      誤差         相対誤差\n');
for i = 1:nbus
    abs_err = P_hat(i) - P_star(i);
    rel_err = abs(abs_err) / max(abs(P_star(i)), 1e-12);
    fprintf('%3d  %+10.6f  %+10.6f  %+.3e  %.3e\n', i, P_star(i), P_hat(i), abs_err, rel_err);
end

fprintf('\nブランチ潮流比較:\n');
fprintf('Br  From-To    f* [pu]      f̂ [pu]      誤差         相対誤差\n');
for i = 1:nbr
    abs_err = f_hat(i) - f_star(i);
    rel_err = abs(abs_err) / max(abs(f_star(i)), 1e-12);
    fprintf('%2d   %2d->%-2d   %+10.6f  %+10.6f  %+.3e  %.3e\n', ...
        i, mpc.branch(i,1), mpc.branch(i,2), f_star(i), f_hat(i), abs_err, rel_err);
end

% 最終判定
fprintf('\n--- 最終判定 ---\n');
tolerance = 1e-10;
success = (err_theta < tolerance) && (err_P < tolerance) && (err_f < tolerance);

if success
    fprintf('✓ 逆推定成功！ (許容誤差: %.0e)\n', tolerance);
else
    fprintf('✗ 逆推定失敗 (許容誤差: %.0e)\n', tolerance);
end

fprintf('\n数学的整合性:\n');
fprintf('- Bbus は %dx%d 行列\n', size(Bbus));
fprintf('- Bf は %dx%d 行列 (過剰決定: %d > %d)\n', size(Bf), nbr, nbus-1);
fprintf('- rank(Bf(:,keep)) = %d\n', rank(Bf(:,keep)));
fprintf('- cond(Bf(:,keep)) = %.3e\n', cond(Bf(:,keep)));

fprintf('\n=== 3ステップ完了 ===\n');
end

function P = generate_true_injection(mpc, ref)
% ケースの発電・負荷データから真の注入P*を生成
define_constants;
nbus = size(mpc.bus, 1);
baseMVA = mpc.baseMVA;

% 発電量 [MW] → [pu]
Pg_bus = accumarray(mpc.gen(:, GEN_BUS), mpc.gen(:, PG), [nbus, 1], @sum, 0);
Pg_pu = Pg_bus / baseMVA;

% 負荷 [MW] → [pu]  
Pd_pu = mpc.bus(:, PD) / baseMVA;

% ネット注入 = 発電 - 負荷
P = Pg_pu - Pd_pu;

% 電力収支をゼロに（基準バスで調整）
imbalance = sum(P);
P(ref) = P(ref) - imbalance;
end

function print_vector_with_index(name, vec, index_name)
% ベクトルをインデックス付きで表示
for i = 1:length(vec)
    fprintf('  %s %2d: %+10.6f\n', index_name, i, vec(i));
end
end

function print_branch_flows(mpc, flows, name)
% ブランチ潮流をfrom-to形式で表示
define_constants;
F = mpc.branch(:, F_BUS);
T = mpc.branch(:, T_BUS);
for i = 1:length(flows)
    fprintf('  Br %2d (%2d->%-2d): %+10.6f\n', i, F(i), T(i), flows(i));
end
end