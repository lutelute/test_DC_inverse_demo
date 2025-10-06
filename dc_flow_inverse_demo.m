function dc_flow_inverse_demo()
% DC 潮流近似で：
% - 任意ケースから真値 P* を作成（ケース内の PG/PD 利用）
% - f* を生成（Bf*theta*）
% - f* のみから最小二乗で theta_hat, P_hat を復元
% - 誤差・検証を表示
%
% 依存: MATPOWER がパスにあること（loadcase, makeBdc, define_constants）

define_constants;

%% 例1：case9（3G–3Lの典型）
run_roundtrip('case9');

%% 例2：case14（任意の他モデルで同じ手順）
% run_roundtrip('case14');

end

%============================== サブルーチン群 ==============================%

function run_roundtrip(mpc_in)
% mpc_in: 'case9' のようなケース名 or MATPOWER 構造体

    fprintf('\n================  Round-trip on %s  ================\n', case_name(mpc_in));
    mpc = loadcase(mpc_in);

    %--- DC 行列の構築
    [Bbus, Bf, ~, ~] = makeBdc(mpc);
    nbus = size(mpc.bus,1);

    %--- 参照（Slack）バス
    ref = pick_refbus(mpc);

    %--- ケース内の発電・負荷から P_true を作る（pu, 収支=0に調整）
    P_true = build_P_from_case(mpc, ref);

    %--- 順問題：P_true → theta_true, f_true
    keep = setdiff(1:nbus, ref);
    theta_true = zeros(nbus,1);
    theta_true(keep) = Bbus(keep,keep) \ P_true(keep);
    f_true = Bf * theta_true;

    %--- 逆問題：f_true のみ → theta_hat, P_hat（最小二乗）
    theta_hat = zeros(nbus,1);
    theta_hat(keep) = Bf(:,keep) \ f_true;   % 過剰決定 => 最小二乗解
    P_hat = Bbus * theta_hat;

    %--- 検証
    rel = @(a,b) norm(a-b,2) / max(norm(b,2),1e-12);
    fprintf('sum(P_true) = %+ .3e pu (DC では 0 が理想)\n', sum(P_true));
    fprintf('rel err theta = %.3e\n', rel(theta_hat, theta_true));
    fprintf('rel err P     = %.3e\n', rel(P_hat,     P_true));
    fprintf('rel err f     = %.3e\n', rel(Bf*theta_hat, f_true));

    %--- 表示（上位/下位を見やすく）
    print_bus_table(P_true, P_hat);
    print_branch_table(mpc, f_true, Bf*theta_hat);

    %--- 追加：測定 f_meas が与えられるときのワーカーを示す
    % [theta_est, P_est] = invert_from_branch_flows_dc(mpc, f_true, ref);
    % （f_true を f_meas に置けば実測逆推定）
end

function ref = pick_refbus(mpc)
% Slack バス（BUS_TYPE=3）があればそれを使用。無ければ bus1。
    define_constants;
    idx = find(mpc.bus(:, BUS_TYPE) == REF);
    if isempty(idx)
        ref = 1;
    else
        ref = idx(1);
    end
end

function P = build_P_from_case(mpc, ref)
% ケースの PG/PD から pu の注入ベクトル P を作る。
% 収支ゼロになるよう slack（ref）に全体補正をまとめて入れる。
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

function print_bus_table(P_true, P_hat)
    fprintf('\nBus   P_true [pu]    P_hat [pu]     diff\n');
    for i = 1:length(P_true)
        fprintf('%3d   %+10.6f   %+10.6f   %+ .3e\n', i, P_true(i), P_hat(i), P_hat(i)-P_true(i));
    end
end

function print_branch_table(mpc, f_true, f_hat)
    define_constants;
    F = mpc.branch(:, F_BUS);
    T = mpc.branch(:, T_BUS);
    fprintf('\nBr  from->to    f_true [pu]    f_hat [pu]     diff\n');
    for e = 1:length(f_true)
        fprintf('%2d   %2d ->%-2d   %+10.6f   %+10.6f   %+ .3e\n', e, F(e), T(e), f_true(e), f_hat(e), f_hat(e)-f_true(e));
    end
end

function name = case_name(mpc_in)
    if ischar(mpc_in) || isstring(mpc_in)
        name = char(mpc_in);
    else
        name = 'mpc_struct';
    end
end

%=================== 実測 f_meas からの逆推定だけ行う関数 ===================%

function [theta_hat, P_hat] = invert_from_branch_flows_dc(mpc_in, f_meas, ref)
% 入力:
%   mpc_in : ケース名 or 構造体
%   f_meas : 枝潮流ベクトル [pu]（mpc.branch の順番・向きに揃える）
%   ref    : 参照バス番号（省略時は Slack→無ければ1）
% 出力:
%   theta_hat : バス角度（rad, 基準=0）
%   P_hat     : 母線注入ベクトル [pu]
    mpc = loadcase(mpc_in);
    if nargin < 3 || isempty(ref)
        ref = pick_refbus(mpc);
    end
    [Bbus, Bf, ~, ~] = makeBdc(mpc);
    nbus = size(mpc.bus,1);
    keep = setdiff(1:nbus, ref);

    theta_hat = zeros(nbus,1);
    theta_hat(keep) = Bf(:,keep) \ f_meas;   % 最小二乗
    P_hat = Bbus * theta_hat;
end