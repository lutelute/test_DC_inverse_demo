function dc_flow_inverse_batch(case_name_or_mpc, N, opts)
% ランダムにN件のシナリオを生成し、DC順問題→逆問題→検証を一括実行。
% ・固定モデル（mpc / 'caseXX'）に対し、PG/PDをランダム摂動
% ・各回で：P_true→theta_true,f_true → (fのみ)→theta_hat,P_hat
% ・誤差と成否をログ化（CSV保存）。例外はstatus='error'で内容を記録
%
% 依存：MATPOWER の loadcase, makeBdc がパスにあること
%
% 引数:
%   case_name_or_mpc : 'case9' などの名前、または mpc 構造体
%   N                : シナリオ数（例: 100）
%   opts (任意)      : 構造体オプション
%       .seed           乱数シード（既定: 0）
%       .noise_sigma    fに乗せる相対ノイズ（0で無し, 例:0.01は±1%程度）
%       .Pg_scale       PG摂動幅（[min,max] 既定 [0.8,1.2]）
%       .Pd_scale       PD摂動幅（[min,max] 既定 [0.8,1.2]）
%       .absPd_floor    最小負荷値（pu, 既定 0）※負荷が0未満にならないよう下限
%       .tol_pass       合格判定の相対誤差閾値（既定 1e-9）
%       .csv_prefix     出力CSVプレフィックス（既定 'dc_batch_log_'）
%
% 例：
%   dc_flow_inverse_batch('case9', 100); % 既定設定で100件
%   dc_flow_inverse_batch('case14', 200, struct('noise_sigma',0.005));
%
% 数学（DC）:
%   f = B_f * theta,  B_f = diag(b) A
%   P = B_bus * theta, B_bus = A^T diag(b) A
%   逆問題: min ||B_f * theta - f||_2  →  P_hat = B_bus * theta

    if nargin < 2 || isempty(N), N = 100; end
    if nargin < 3, opts = struct(); end

    % 既定オプション
    if ~isfield(opts, 'seed'),        opts.seed = 0; end
    if ~isfield(opts, 'noise_sigma'), opts.noise_sigma = 0.0; end
    if ~isfield(opts, 'Pg_scale'),    opts.Pg_scale = [0.8, 1.2]; end
    if ~isfield(opts, 'Pd_scale'),    opts.Pd_scale = [0.8, 1.2]; end
    if ~isfield(opts, 'absPd_floor'), opts.absPd_floor = 0.0; end
    if ~isfield(opts, 'tol_pass'),    opts.tol_pass = 1e-9; end
    if ~isfield(opts, 'csv_prefix'),  opts.csv_prefix = 'dc_batch_log_'; end

    % 乱数シード
    rng(opts.seed);

    % ケース読み込み
    mpc = loadcase(case_name_or_mpc);
    name = local_case_name(case_name_or_mpc);

    % インデックス直書き（define_constants不要）
    BUS_TYPE = 2; PD = 3;
    GEN_BUS  = 1; PG = 2;
    F_BUS    = 1; T_BUS = 2;

    % DC行列
    [Bbus, Bf, ~, ~] = makeBdc(mpc);
    nbus = size(mpc.bus,1);
    nbr  = size(mpc.branch,1);

    % 参照バス（Slack）選択：BUS_TYPE==3があれば優先、なければ1
    ref = find(mpc.bus(:,BUS_TYPE) == 3, 1, 'first');
    if isempty(ref), ref = 1; end
    keep = setdiff(1:nbus, ref);

    % ベース値
    baseMVA = mpc.baseMVA;

    % ジェネバス集合、ベースPG（MW）
    gen_buses = mpc.gen(:, GEN_BUS);
    Pg_baseMW = accumarray(gen_buses, mpc.gen(:, PG), [nbus,1], @sum, 0);

    % 負荷ベース（MW）
    Pd_baseMW = mpc.bus(:, PD);

    % ログ用テーブル
    ScenarioID = (1:N).';
    Status     = strings(N,1);    % 'ok' | 'fail' | 'error'
    ErrTheta   = nan(N,1);
    ErrP       = nan(N,1);
    ErrF       = nan(N,1);
    SumPtrue   = nan(N,1);
    Note       = strings(N,1);

    % 実行
    t_start = tic;
    for s = 1:N
        try
            %----- 1) ランダムPG/PDを生成（MW） -----
            Pg_scale = lerp(opts.Pg_scale(1), opts.Pg_scale(2), rand(nbus,1));
            Pd_scale = lerp(opts.Pd_scale(1), opts.Pd_scale(2), rand(nbus,1));

            PgMW = Pg_baseMW .* Pg_scale;
            PdMW = Pd_baseMW .* Pd_scale;

            % 下限（負荷が負or小さすぎを防ぐ）
            PdMW = max(PdMW, opts.absPd_floor * baseMVA);

            %----- 2) P_true（pu）を構成 & 収支ゼロ化（refに寄せ） -----
            P_true = (PgMW - PdMW) / baseMVA;
            P_true(ref) = P_true(ref) - sum(P_true);

            % DC の順問題：theta_true, f_true
            theta_true = zeros(nbus,1);
            % 可解性（島化）等で警戒：Bbus(keep,keep)が正則かチェック
            if rcond(Bbus(keep,keep)) < 1e-12
                error('Bbus(keep,keep) is ill-conditioned (scenario=%d)', s);
            end
            theta_true(keep) = Bbus(keep,keep) \ P_true(keep);
            f_true = Bf * theta_true;

            % 観測ノイズ（相対）を付与（任意）
            if opts.noise_sigma > 0
                scale = max(1.0, abs(f_true)); % 相対ノイズの基準
                f_meas = f_true + opts.noise_sigma * (randn(nbr,1) .* scale);
            else
                f_meas = f_true;
            end

            %----- 3) 逆問題：f_meas のみから推定 -----
            theta_hat = zeros(nbus,1);
            % 最小二乗（過剰決定）
            theta_hat(keep) = Bf(:,keep) \ f_meas;
            P_hat = Bbus * theta_hat;
            f_hat = Bf * theta_hat;

            %----- 4) 誤差評価 -----
            rel = @(a,b) norm(a-b,2) / max(norm(b,2),1e-12);
            eTheta = rel(theta_hat, theta_true);
            eP     = rel(P_hat,     P_true);
            eF     = rel(f_hat,     f_true);

            ErrTheta(s) = eTheta;
            ErrP(s)     = eP;
            ErrF(s)     = eF;
            SumPtrue(s) = sum(P_true);

            % 合否
            if eP <= opts.tol_pass && eF <= opts.tol_pass
                Status(s) = "ok";
            else
                Status(s) = "fail";
                Note(s)   = sprintf('eP=%.3e eF=%.3e', eP, eF);
            end

        catch ME
            % 例外を捕捉してログ（Status='error'）
            Status(s) = "error";
            Note(s)   = string(ME.message);
        end
    end
    elapsed = toc(t_start);

    % ログをテーブル化
    T = table(ScenarioID, Status, ErrTheta, ErrP, ErrF, SumPtrue, Note);

    % 概要を表示
    n_ok    = sum(Status == "ok");
    n_fail  = sum(Status == "fail");
    n_error = sum(Status == "error");
    fprintf('\n=== %s | N=%d finished in %.2f s ===\n', name, N, elapsed);
    fprintf('ok=%d, fail=%d, error=%d\n', n_ok, n_fail, n_error);

    % CSV 保存
    stamp = datestr(now, 'YYYYmmdd_HHMMSS');
    csv_name = sprintf('%s%s_%s.csv', opts.csv_prefix, name, stamp);
    writetable(T, csv_name);
    fprintf('Saved log: %s\n', csv_name);
end

%=========== ユーティリティ ===========%

function y = lerp(a, b, u)
    % 線形補間：a + u*(b-a)  （uは[0,1]）
    y = a + (b - a) .* u;
end

function name = local_case_name(case_name_or_mpc)
    if ischar(case_name_or_mpc) || isstring(case_name_or_mpc)
        name = char(case_name_or_mpc);
    else
        name = 'mpc_struct';
    end
end