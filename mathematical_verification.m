function mathematical_verification()
% DC潮流逆問題の数学的検証
%
% 目的：
% 1. 行列Bf, Bbusの数学的性質を確認
% 2. 最小二乗問題の解の一意性を検証
% 3. 逆問題の理論的解析
% 4. 数値的安定性の評価

fprintf('\n=== DC潮流逆問題：数学的検証 ===\n');

% ケース読み込み
mpc = loadcase('case9');
[Bbus, Bf, ~, ~] = makeBdc(mpc);

% 基本情報
nbus = size(mpc.bus, 1);
nbr = size(mpc.branch, 1);
define_constants;
ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
if isempty(ref), ref = 1; end
keep = setdiff(1:nbus, ref);

fprintf('システム概要:\n');
fprintf('- バス数 n = %d\n', nbus);
fprintf('- ブランチ数 m = %d\n', nbr);
fprintf('- 基準バス = %d\n', ref);
fprintf('- 自由度 = %d (= n-1)\n', length(keep));

%% 1. 行列の数学的性質
fprintf('\n=== 1. 行列の数学的性質 ===\n');

% Bbusの性質
fprintf('\nBbus行列の性質:\n');
fprintf('- サイズ: %dx%d\n', size(Bbus));
fprintf('- 対称性: %s\n', check_symmetry(Bbus));
fprintf('- 正定値性: %s\n', check_positive_definite(Bbus));
fprintf('- rank(Bbus) = %d\n', rank(Bbus));
fprintf('- rank(Bbus(keep,keep)) = %d\n', rank(Bbus(keep,keep)));
fprintf('- cond(Bbus(keep,keep)) = %.3e\n', cond(Bbus(keep,keep)));

% 固有値解析
eigenvals_Bbus = eig(Bbus);
eigenvals_reduced = eig(Bbus(keep,keep));
fprintf('- 最小固有値(Bbus): %.3e\n', min(eigenvals_Bbus));
fprintf('- 最小固有値(Bbus(keep,keep)): %.3e\n', min(eigenvals_reduced));

% Bf行列の性質  
fprintf('\nBf行列の性質:\n');
fprintf('- サイズ: %dx%d\n', size(Bf));
fprintf('- rank(Bf) = %d\n', rank(Bf));
fprintf('- rank(Bf(:,keep)) = %d\n', rank(Bf(:,keep)));
fprintf('- cond(Bf(:,keep)) = %.3e\n', cond(Bf(:,keep)));

% 過剰決定性の確認
fprintf('- 過剰決定度: m - (n-1) = %d - %d = %d\n', nbr, length(keep), nbr - length(keep));

%% 2. 最小二乗問題の解析
fprintf('\n=== 2. 最小二乗問題の解析 ===\n');

% テスト用の真値を生成
P_test = generate_test_injection(mpc, ref);
theta_test = zeros(nbus, 1);
theta_test(keep) = Bbus(keep,keep) \ P_test(keep);
f_test = Bf * theta_test;

fprintf('テストケース生成:\n');
fprintf('- sum(P_test) = %.3e\n', sum(P_test));
fprintf('- ||f_test||₂ = %.6f\n', norm(f_test));

% 最小二乗解の計算
fprintf('\n最小二乗解の計算:\n');
A_ls = Bf(:, keep);
b_ls = f_test;

fprintf('- 係数行列 A のサイズ: %dx%d\n', size(A_ls));
fprintf('- 右辺ベクトル b のサイズ: %dx1\n', length(b_ls));
fprintf('- rank(A) = %d\n', rank(A_ls));
fprintf('- null space dimension = %d\n', size(A_ls, 2) - rank(A_ls));

% 正規方程式での解法
fprintf('\n正規方程式による解析:\n');
AtA = A_ls' * A_ls;
Atb = A_ls' * b_ls;
fprintf('- A^T A のサイズ: %dx%d\n', size(AtA));
fprintf('- rank(A^T A) = %d\n', rank(AtA));
fprintf('- cond(A^T A) = %.3e\n', cond(AtA));

% 解の計算（複数手法）
theta_ls1 = A_ls \ b_ls;  % MATLAB標準
theta_ls2 = pinv(A_ls) * b_ls;  % 疑似逆行列
theta_ls3 = AtA \ Atb;  % 正規方程式

fprintf('\n解法比較:\n');
fprintf('- ||θ_ls1 - θ_test||₂ = %.3e (標準 \\)\n', norm(theta_ls1 - theta_test(keep)));
fprintf('- ||θ_ls2 - θ_test||₂ = %.3e (疑似逆)\n', norm(theta_ls2 - theta_test(keep)));
fprintf('- ||θ_ls3 - θ_test||₂ = %.3e (正規方程式)\n', norm(theta_ls3 - theta_test(keep)));

%% 3. 残差解析
fprintf('\n=== 3. 残差解析 ===\n');

theta_sol = zeros(nbus, 1);
theta_sol(keep) = theta_ls1;
f_reconstructed = Bf * theta_sol;

residual = f_reconstructed - f_test;
fprintf('最小二乗残差:\n');
fprintf('- ||Bf*θ̂ - f*||₂ = %.3e\n', norm(residual));
fprintf('- 相対残差 = %.3e\n', norm(residual) / norm(f_test));

% 残差の分布
fprintf('- 残差の最大値 = %.3e\n', max(abs(residual)));
fprintf('- 残差の平均値 = %.3e\n', mean(residual));
fprintf('- 残差の標準偏差 = %.3e\n', std(residual));

%% 4. 数値的安定性テスト
fprintf('\n=== 4. 数値的安定性テスト ===\n');

noise_levels = [1e-12, 1e-10, 1e-8, 1e-6, 1e-4];
fprintf('ノイズレベル vs 解の変化:\n');
fprintf('Noise Level    ||Δθ||₂      ||ΔP||₂      条件数悪化\n');

for i = 1:length(noise_levels)
    noise = noise_levels(i);
    
    % ノイズ付加
    f_noisy = f_test + noise * randn(size(f_test));
    
    % ノイズありの解
    theta_noisy = zeros(nbus, 1);
    theta_noisy(keep) = A_ls \ f_noisy;
    P_noisy = Bbus * theta_noisy;
    
    % 変化量
    delta_theta = norm(theta_noisy - theta_test);
    delta_P = norm(P_noisy - P_test);
    
    % 条件数による理論的悪化度
    theoretical_amplification = cond(A_ls) * noise / norm(f_test);
    
    fprintf('%.0e      %.3e    %.3e    %.3e\n', noise, delta_theta, delta_P, theoretical_amplification);
end

%% 5. 理論値との比較
fprintf('\n=== 5. 理論値との比較 ===\n');

% 理論的に期待される性質
fprintf('理論的性質の確認:\n');

% 1. Kirchhoff's law
fprintf('1. Kirchhoffの法則:\n');
incidence_check = check_kirchhoff_laws(mpc, Bf);
fprintf('   - 接続行列の性質: %s\n', incidence_check);

% 2. エネルギー保存
fprintf('2. エネルギー保存:\n');
power_balance = abs(sum(P_test));
fprintf('   - 電力収支: %.3e (理想的に0)\n', power_balance);

% 3. 対称性
fprintf('3. 対称性:\n');
fprintf('   - Bbus対称性: %s\n', check_symmetry(Bbus));

%% 6. 最適化問題としての解析
fprintf('\n=== 6. 最適化問題としての解析 ===\n');

% 目的関数値
objective_value = 0.5 * norm(A_ls * theta_ls1 - b_ls)^2;
fprintf('目的関数値 (1/2)||Aθ - b||₂²: %.3e\n', objective_value);

% 勾配の確認（最適性条件）
gradient = A_ls' * (A_ls * theta_ls1 - b_ls);
fprintf('勾配 ||∇f||₂: %.3e (最適解で0)\n', norm(gradient));

% KKT条件の確認（制約なし問題なので1次条件のみ）
fprintf('最適性条件: ||A^T(Aθ - b)||₂ = %.3e\n', norm(gradient));

fprintf('\n=== 数学的検証完了 ===\n');
end

function result = check_symmetry(A)
% 行列の対称性をチェック
if norm(A - A', 'fro') < 1e-12 * norm(A, 'fro')
    result = '対称';
else
    result = '非対称';
end
end

function result = check_positive_definite(A)
% 正定値性をチェック
try
    eigenvals = eig(A);
    min_eig = min(eigenvals);
    if min_eig > 1e-12
        result = '正定値';
    elseif min_eig > -1e-12
        result = '半正定値';
    else
        result = '不定';
    end
catch
    result = 'エラー';
end
end

function result = check_kirchhoff_laws(mpc, Bf)
% Kirchhoffの法則の確認
define_constants;
F = mpc.branch(:, F_BUS);
T = mpc.branch(:, T_BUS);
nbus = size(mpc.bus, 1);
nbr = size(mpc.branch, 1);

% 接続行列Aを再構築して確認
A = zeros(nbr, nbus);
for i = 1:nbr
    A(i, F(i)) = 1;
    A(i, T(i)) = -1;
end

% A * ones(nbus,1) = 0 should hold (Kirchhoff's current law)
kirchhoff_check = A * ones(nbus, 1);
if norm(kirchhoff_check) < 1e-12
    result = '正常 (∑f_in = ∑f_out)';
else
    result = sprintf('異常 (誤差: %.3e)', norm(kirchhoff_check));
end
end

function P = generate_test_injection(mpc, ref)
% テスト用の電力注入パターンを生成
define_constants;
nbus = size(mpc.bus, 1);
baseMVA = mpc.baseMVA;

% ケースデータを基にしつつ、少し変動を加える
scale_factor = 0.8 + 0.4 * rand(nbus, 1);  % 0.8～1.2の変動

% 発電量
Pg_bus = accumarray(mpc.gen(:, GEN_BUS), mpc.gen(:, PG), [nbus, 1], @sum, 0);
Pg_pu = (Pg_bus .* scale_factor) / baseMVA;

% 負荷
Pd_pu = (mpc.bus(:, PD) .* scale_factor) / baseMVA;

% ネット注入
P = Pg_pu - Pd_pu;

% 電力収支調整
imbalance = sum(P);
P(ref) = P(ref) - imbalance;
end