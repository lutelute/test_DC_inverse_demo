function run_analysis()
% DC潮流逆問題の実行とノイズを含む場合の分析
% 
% この関数は以下を実行します：
% 1. 基本のcase9での逆問題デモ
% 2. ノイズを含む場合での成功率分析
% 3. 結果の可視化

fprintf('=== DC潮流逆問題デモ開始 ===\n\n');

% 1. 基本デモ実行
fprintf('1. 基本デモ（case9）実行中...\n');
dc_flow_inverse_demo();

% 2. ノイズ分析 - 複数のノイズレベルで実行
fprintf('\n2. ノイズ感度分析実行中...\n');
noise_levels = [0, 0.001, 0.005, 0.01, 0.02, 0.05];  % 0%, 0.1%, 0.5%, 1%, 2%, 5%
success_rates = zeros(size(noise_levels));

for i = 1:length(noise_levels)
    noise_sigma = noise_levels(i);
    fprintf('  ノイズレベル %.1f%% 実行中...\n', noise_sigma*100);
    
    % バッチ実行（100ケース）
    opts = struct();
    opts.noise_sigma = noise_sigma;
    opts.tol_pass = 1e-6;  % より緩い判定基準
    opts.csv_prefix = sprintf('noise_%.3f_', noise_sigma);
    
    % エラーを避けるため一時的にwarningを無効化
    warning('off', 'MATLAB:nearlySingularMatrix');
    
    try
        dc_flow_inverse_batch('case9', 100, opts);
        
        % 結果を読み込んで成功率を計算
        csv_name = sprintf('noise_%.3f_case9_*.csv', noise_sigma);
        files = dir(csv_name);
        if ~isempty(files)
            T = readtable(files(end).name);
            success_rates(i) = sum(T.Status == "ok") / height(T) * 100;
        end
    catch ME
        fprintf('    エラー: %s\n', ME.message);
        success_rates(i) = 0;
    end
    
    warning('on', 'MATLAB:nearlySingularMatrix');
end

% 3. 結果の可視化
fprintf('\n3. 結果可視化中...\n');
create_noise_analysis_plot(noise_levels, success_rates);

% 4. 完全なcase9の結果を再実行して表示
fprintf('\n4. 詳細結果生成中...\n');
create_detailed_results();

fprintf('\n=== 分析完了 ===\n');
end

function create_noise_analysis_plot(noise_levels, success_rates)
% ノイズ感度分析の結果をプロット

figure('Position', [100, 100, 800, 600]);

% 成功率プロット
subplot(2,1,1);
plot(noise_levels*100, success_rates, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
xlabel('ノイズレベル (%)');
ylabel('成功率 (%)');
title('DC潮流逆問題のノイズ感度分析');
ylim([0, 105]);
xlim([0, max(noise_levels)*100]);

% ログスケールでも表示
subplot(2,1,2);
semilogx(noise_levels(2:end)*100, success_rates(2:end), 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
xlabel('ノイズレベル (%) [ログスケール]');
ylabel('成功率 (%)');
title('ノイズ感度分析（ログスケール）');
ylim([0, 105]);

% 結果をファイルに保存
saveas(gcf, 'noise_sensitivity_analysis.png');
fprintf('  プロット保存: noise_sensitivity_analysis.png\n');

% 数値結果をテーブルで保存
T = table(noise_levels', success_rates', 'VariableNames', {'NoiseLevel', 'SuccessRate'});
writetable(T, 'noise_analysis_summary.csv');
fprintf('  数値結果保存: noise_analysis_summary.csv\n');
end

function create_detailed_results()
% 詳細な結果分析を作成

% case9での単一実行で詳細を取得
mpc = loadcase('case9');
[Bbus, Bf, ~, ~] = makeBdc(mpc);
nbus = size(mpc.bus,1);

% 参照バス
define_constants;
ref = find(mpc.bus(:, BUS_TYPE) == REF, 1);
if isempty(ref), ref = 1; end
keep = setdiff(1:nbus, ref);

% ケースデータからP_trueを構築
P_true = build_P_from_case(mpc, ref);

% 順問題
theta_true = zeros(nbus,1);
theta_true(keep) = Bbus(keep,keep) \ P_true(keep);
f_true = Bf * theta_true;

% 逆問題
theta_hat = zeros(nbus,1);
theta_hat(keep) = Bf(:,keep) \ f_true;
P_hat = Bbus * theta_hat;

% 結果をファイルに保存
fid = fopen('detailed_results.txt', 'w');
fprintf(fid, 'DC潮流逆問題 詳細結果 (case9)\n');
fprintf(fid, '==================================\n\n');

fprintf(fid, '問題設定:\n');
fprintf(fid, '- システム: IEEE 9-bus test case\n');
fprintf(fid, '- バス数: %d\n', nbus);
fprintf(fid, '- ブランチ数: %d\n', size(mpc.branch,1));
fprintf(fid, '- 参照バス: %d\n\n', ref);

fprintf(fid, 'バス別結果:\n');
fprintf(fid, 'Bus   P_true [pu]    P_hat [pu]     誤差\n');
for i = 1:nbus
    fprintf(fid, '%3d   %+10.6f   %+10.6f   %+.3e\n', i, P_true(i), P_hat(i), P_hat(i)-P_true(i));
end

fprintf(fid, '\nブランチ別結果:\n');
fprintf(fid, 'Br  from->to    f_true [pu]    f_hat [pu]     誤差\n');
F = mpc.branch(:, F_BUS);
T = mpc.branch(:, T_BUS);
for e = 1:length(f_true)
    fprintf(fid, '%2d   %2d ->%-2d   %+10.6f   %+10.6f   %+.3e\n', e, F(e), T(e), f_true(e), Bf(e,:)*theta_hat, (Bf(e,:)*theta_hat)-f_true(e));
end

rel = @(a,b) norm(a-b,2) / max(norm(b,2),1e-12);
fprintf(fid, '\n全体誤差:\n');
fprintf(fid, '- 角度誤差: %.3e\n', rel(theta_hat, theta_true));
fprintf(fid, '- 電力誤差: %.3e\n', rel(P_hat, P_true));
fprintf(fid, '- 潮流誤差: %.3e\n', rel(Bf*theta_hat, f_true));

fclose(fid);
fprintf('  詳細結果保存: detailed_results.txt\n');
end

function P = build_P_from_case(mpc, ref)
% ケースの PG/PD から pu の注入ベクトル P を作る
define_constants;
nbus = size(mpc.bus,1);
base = mpc.baseMVA;

% 各バスの発電合計（MW）→ pu
Pg_bus = accumarray(mpc.gen(:, GEN_BUS), mpc.gen(:, PG), [nbus, 1], @sum, 0);
Pg_pu  = Pg_bus / base;

% 各バスの負荷（MW）→ pu
Pd_pu  = mpc.bus(:, PD) / base;

% ネット注入
P = Pg_pu - Pd_pu;

% 合計を 0 に調整（DC の理想：損失無視）
mismatch = sum(P);
P(ref) = P(ref) - mismatch;
end