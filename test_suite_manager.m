function test_suite_manager()
% DC潮流逆問題テストスイート管理システム
%
% 機能:
% 1. 全テストケースの実行管理
% 2. 結果の自動保存と整理
% 3. 比較分析の自動実行
% 4. レポート生成
% 5. 継続的統合サポート

fprintf('\n=== DC潮流逆問題テストスイート管理 ===\n');

% メニュー表示
while true
    fprintf('\n--- テストスイートメニュー ---\n');
    fprintf('1. 全テストケース実行 (標準モード)\n');
    fprintf('2. 全テストケース実行 (高速モード)\n'); 
    fprintf('3. 全テストケース実行 (詳細モード)\n');
    fprintf('4. 特定ケースのみ実行\n');
    fprintf('5. 最新結果の比較分析\n');
    fprintf('6. 結果履歴の管理\n');
    fprintf('7. テストケース設定の確認\n');
    fprintf('8. 継続的統合レポート\n');
    fprintf('9. 終了\n');
    
    choice = input('選択してください (1-9): ');
    
    switch choice
        case 1
            run_standard_test_suite();
        case 2
            run_quick_test_suite();
        case 3
            run_detailed_test_suite();
        case 4
            run_custom_test_suite();
        case 5
            run_comparative_analysis();
        case 6
            manage_result_history();
        case 7
            show_test_configuration();
        case 8
            generate_ci_report();
        case 9
            fprintf('テストスイート管理を終了します。\n');
            break;
        otherwise
            fprintf('無効な選択です。1-9から選択してください。\n');
    end
end
end

function run_standard_test_suite()
% 標準モードでの全テストケース実行

fprintf('\n--- 標準モード実行 ---\n');
fprintf('全テストケースを標準設定で実行します。\n');

try
    run_all_test_cases();
    fprintf('✓ 標準テスト完了\n');
    
    % 自動で比較分析実行
    fprintf('\n自動比較分析を実行中...\n');
    comparative_analysis();
    fprintf('✓ 比較分析完了\n');
    
catch ME
    fprintf('✗ エラー: %s\n', ME.message);
end
end

function run_quick_test_suite()
% 高速モードでの全テストケース実行

fprintf('\n--- 高速モード実行 ---\n');
fprintf('全テストケースを高速設定で実行します。\n');
fprintf('(統計数削減、詳細分析スキップ)\n');

try
    run_all_test_cases('quick', true, 'save_plots', false);
    fprintf('✓ 高速テスト完了\n');
    
catch ME
    fprintf('✗ エラー: %s\n', ME.message);
end
end

function run_detailed_test_suite()
% 詳細モードでの全テストケース実行

fprintf('\n--- 詳細モード実行 ---\n');
fprintf('全テストケースを詳細設定で実行します。\n');
fprintf('(追加検証、詳細分析、全プロット生成)\n');

try
    run_all_test_cases('detailed', true, 'save_plots', true);
    fprintf('✓ 詳細テスト完了\n');
    
    % 詳細比較分析
    fprintf('\n詳細比較分析を実行中...\n');
    comparative_analysis();
    fprintf('✓ 詳細比較分析完了\n');
    
catch ME
    fprintf('✗ エラー: %s\n', ME.message);
end
end

function run_custom_test_suite()
% カスタムテストケース実行

fprintf('\n--- カスタムテスト実行 ---\n');

% 利用可能なケース表示
config = test_case_config();
fprintf('利用可能なテストケース:\n');
for i = 1:length(config)
    fprintf('%d. %s (%s)\n', i, config(i).name, config(i).description);
end

% ケース選択
selected_indices = input('実行するケース番号を入力 (例: [1,3,5] または 1): ');
if isscalar(selected_indices)
    selected_indices = [selected_indices];
end

% 有効性チェック
if any(selected_indices < 1 | selected_indices > length(config))
    fprintf('無効なケース番号が含まれています。\n');
    return;
end

selected_cases = {config(selected_indices).name};
fprintf('選択されたケース: %s\n', strjoin(selected_cases, ', '));

% 実行オプション
fprintf('\n実行オプション:\n');
fprintf('1. 標準\n2. 高速\n3. 詳細\n');
mode_choice = input('モードを選択 (1-3): ');

switch mode_choice
    case 1
        opts = {};
    case 2
        opts = {'quick', true};
    case 3
        opts = {'detailed', true};
    otherwise
        fprintf('無効な選択です。標準モードで実行します。\n');
        opts = {};
end

try
    run_all_test_cases('cases', selected_cases, opts{:});
    fprintf('✓ カスタムテスト完了\n');
    
catch ME
    fprintf('✗ エラー: %s\n', ME.message);
end
end

function run_comparative_analysis()
% 最新結果の比較分析

fprintf('\n--- 比較分析実行 ---\n');

% 最新の結果ファイルを検索
result_files = dir('results/all_test_results_*.mat');
if isempty(result_files)
    fprintf('分析可能な結果ファイルが見つかりません。\n');
    fprintf('先にテストケースを実行してください。\n');
    return;
end

% ファイル一覧表示
fprintf('利用可能な結果ファイル:\n');
for i = 1:length(result_files)
    fprintf('%d. %s (%s)\n', i, result_files(i).name, ...
            datestr(result_files(i).datenum));
end

% ファイル選択
choice = input(sprintf('分析するファイル番号 (1-%d, 0=最新): ', length(result_files)));

if choice == 0 || isempty(choice)
    [~, newest_idx] = max([result_files.datenum]);
    selected_file = result_files(newest_idx).name;
else
    if choice < 1 || choice > length(result_files)
        fprintf('無効な選択です。\n');
        return;
    end
    selected_file = result_files(choice).name;
end

try
    comparative_analysis(fullfile('results', selected_file));
    fprintf('✓ 比較分析完了\n');
    
catch ME
    fprintf('✗ エラー: %s\n', ME.message);
end
end

function manage_result_history()
% 結果履歴の管理

fprintf('\n--- 結果履歴管理 ---\n');

% 結果ファイル一覧
result_files = dir('results/all_test_results_*.mat');
plot_files = dir('results/plots/*.png');

fprintf('結果ファイル: %d個\n', length(result_files));
fprintf('プロットファイル: %d個\n', length(plot_files));

if isempty(result_files)
    fprintf('履歴がありません。\n');
    return;
end

fprintf('\n履歴一覧:\n');
fprintf('%-3s %-30s %-20s %8s\n', 'No', 'ファイル名', '日時', 'サイズ');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:length(result_files)
    file_size = result_files(i).bytes / 1024; % KB
    fprintf('%-3d %-30s %-20s %7.1fKB\n', i, result_files(i).name, ...
            datestr(result_files(i).datenum), file_size);
end

fprintf('\n管理オプション:\n');
fprintf('1. 特定ファイルの詳細情報\n');
fprintf('2. 古いファイルの削除\n');
fprintf('3. 結果の比較\n');
fprintf('4. 戻る\n');

choice = input('選択してください (1-4): ');

switch choice
    case 1
        show_file_details(result_files);
    case 2
        cleanup_old_files(result_files);
    case 3
        compare_results(result_files);
    case 4
        return;
    otherwise
        fprintf('無効な選択です。\n');
end
end

function show_file_details(result_files)
% ファイル詳細情報表示

file_idx = input(sprintf('ファイル番号 (1-%d): ', length(result_files)));
if file_idx < 1 || file_idx > length(result_files)
    fprintf('無効なファイル番号です。\n');
    return;
end

filename = fullfile('results', result_files(file_idx).name);
try
    data = load(filename);
    
    fprintf('\n--- ファイル詳細情報 ---\n');
    fprintf('ファイル名: %s\n', result_files(file_idx).name);
    fprintf('作成日時: %s\n', datestr(result_files(file_idx).datenum));
    fprintf('サイズ: %.1f KB\n', result_files(file_idx).bytes / 1024);
    
    if isfield(data, 'results')
        results = data.results;
        successful = strcmp({results.status}, 'success');
        fprintf('総ケース数: %d\n', length(results));
        fprintf('成功ケース: %d\n', sum(successful));
        fprintf('失敗ケース: %d\n', sum(~successful));
        
        if any(successful)
            case_names = {results(successful).case_name};
            fprintf('成功ケース: %s\n', strjoin(case_names, ', '));
        end
    end
    
catch ME
    fprintf('ファイル読み込みエラー: %s\n', ME.message);
end
end

function cleanup_old_files(result_files)
% 古いファイルの削除

if length(result_files) <= 3
    fprintf('保持すべきファイルが少ないため、削除をスキップします。\n');
    return;
end

% 最新3個を除いて削除対象とする
[~, sort_idx] = sort([result_files.datenum], 'descend');
keep_count = 3;
delete_candidates = result_files(sort_idx(keep_count+1:end));

fprintf('\n削除候補ファイル:\n');
for i = 1:length(delete_candidates)
    fprintf('%d. %s (%s)\n', i, delete_candidates(i).name, ...
            datestr(delete_candidates(i).datenum));
end

confirm = input('\nこれらのファイルを削除しますか? (y/N): ', 's');
if strcmpi(confirm, 'y')
    for i = 1:length(delete_candidates)
        try
            delete(fullfile('results', delete_candidates(i).name));
            fprintf('削除: %s\n', delete_candidates(i).name);
        catch ME
            fprintf('削除失敗: %s (%s)\n', delete_candidates(i).name, ME.message);
        end
    end
    fprintf('清理完了。\n');
else
    fprintf('削除をキャンセルしました。\n');
end
end

function compare_results(result_files)
% 結果の比較

if length(result_files) < 2
    fprintf('比較には2つ以上の結果ファイルが必要です。\n');
    return;
end

fprintf('比較する2つのファイルを選択してください:\n');
file1_idx = input(sprintf('1つ目のファイル番号 (1-%d): ', length(result_files)));
file2_idx = input(sprintf('2つ目のファイル番号 (1-%d): ', length(result_files)));

if file1_idx < 1 || file1_idx > length(result_files) || ...
   file2_idx < 1 || file2_idx > length(result_files) || ...
   file1_idx == file2_idx
    fprintf('無効な選択です。\n');
    return;
end

% 簡単な比較実装（拡張可能）
try
    data1 = load(fullfile('results', result_files(file1_idx).name));
    data2 = load(fullfile('results', result_files(file2_idx).name));
    
    fprintf('\n--- 比較結果 ---\n');
    fprintf('ファイル1: %s (%d ケース)\n', result_files(file1_idx).name, length(data1.results));
    fprintf('ファイル2: %s (%d ケース)\n', result_files(file2_idx).name, length(data2.results));
    
    % 詳細比較は今後の拡張項目
    fprintf('詳細比較機能は開発中です。\n');
    
catch ME
    fprintf('比較エラー: %s\n', ME.message);
end
end

function show_test_configuration()
% テストケース設定の確認

fprintf('\n--- テストケース設定 ---\n');
config = test_case_config();

% 詳細情報表示
for i = 1:length(config)
    c = config(i);
    fprintf('\n%d. %s\n', i, c.name);
    fprintf('   説明: %s\n', c.description);
    fprintf('   規模: %d buses, %d branches\n', c.buses, c.branches);
    fprintf('   発電機: %d, 負荷: %d\n', c.generators, c.loads);
    fprintf('   カテゴリ: %s\n', c.category);
    fprintf('   期待性能: %s\n', c.expected_performance);
    fprintf('   ノイズ感度: %s\n', c.noise_sensitivity);
    fprintf('   優先度: %d\n', c.test_priority);
end
end

function generate_ci_report()
% 継続的統合レポート生成

fprintf('\n--- 継続的統合レポート ---\n');

% 最新の結果を使用
result_files = dir('results/all_test_results_*.mat');
if isempty(result_files)
    fprintf('レポート生成に必要な結果ファイルがありません。\n');
    return;
end

[~, newest_idx] = max([result_files.datenum]);
latest_file = fullfile('results', result_files(newest_idx).name);

try
    data = load(latest_file);
    results = data.results;
    
    % CI用サマリー生成
    ci_report_file = 'results/ci_report.txt';
    fid = fopen(ci_report_file, 'w');
    
    fprintf(fid, 'DC Flow Inverse Problem - CI Report\n');
    fprintf(fid, '===================================\n\n');
    fprintf(fid, 'Test Date: %s\n', datestr(now));
    fprintf(fid, 'Result File: %s\n\n', result_files(newest_idx).name);
    
    % テスト統計
    successful = strcmp({results.status}, 'success');
    n_success = sum(successful);
    n_total = length(results);
    
    fprintf(fid, 'Test Statistics:\n');
    fprintf(fid, '- Total Cases: %d\n', n_total);
    fprintf(fid, '- Successful: %d\n', n_success);
    fprintf(fid, '- Failed: %d\n', n_total - n_success);
    fprintf(fid, '- Success Rate: %.1f%%\n\n', n_success/n_total*100);
    
    % 成功ケースの性能
    if n_success > 0
        successful_results = results(successful);
        errors_P = [successful_results.basic];
        errors_P = [errors_P.error_P];
        
        fprintf(fid, 'Performance Summary:\n');
        fprintf(fid, '- Best Error: %.3e\n', min(errors_P));
        fprintf(fid, '- Worst Error: %.3e\n', max(errors_P));
        fprintf(fid, '- Mean Error: %.3e\n', mean(errors_P));
        fprintf(fid, '- Median Error: %.3e\n', median(errors_P));
    end
    
    % Pass/Fail判定
    fprintf(fid, '\nOverall Result: ');
    if n_success == n_total
        fprintf(fid, 'PASS\n');
        exit_code = 0;
    else
        fprintf(fid, 'FAIL\n');
        exit_code = 1;
    end
    
    fclose(fid);
    
    fprintf('CI レポート生成完了: %s\n', ci_report_file);
    fprintf('終了コード: %d\n', exit_code);
    
    % 環境変数として終了コードを設定（CI環境用）
    setenv('DC_INVERSE_TEST_EXIT_CODE', num2str(exit_code));
    
catch ME
    fprintf('CI レポート生成エラー: %s\n', ME.message);
end
end