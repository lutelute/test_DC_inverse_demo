function cleanup_manager()
% ファイル整理・クリーンアップ管理システム
%
% 機能:
% 1. 古いファイルの自動整理
% 2. ディスク容量の管理
% 3. ファイル構造の維持
% 4. バックアップと復元

fprintf('\n=== ファイル整理・クリーンアップ管理 ===\n');

while true
    fprintf('\n--- クリーンアップメニュー ---\n');
    fprintf('1. 自動クリーンアップ実行\n');
    fprintf('2. 古いCSVファイルの整理\n');
    fprintf('3. 古いプロットファイルの整理\n');
    fprintf('4. ディスク容量チェック\n');
    fprintf('5. ファイル構造の検証\n');
    fprintf('6. アーカイブ管理\n');
    fprintf('7. 設定\n');
    fprintf('8. 終了\n');
    
    choice = input('選択してください (1-8): ');
    
    switch choice
        case 1
            auto_cleanup();
        case 2
            cleanup_csv_files();
        case 3
            cleanup_plot_files();
        case 4
            check_disk_usage();
        case 5
            verify_file_structure();
        case 6
            manage_archives();
        case 7
            manage_settings();
        case 8
            fprintf('クリーンアップ管理を終了します。\n');
            break;
        otherwise
            fprintf('無効な選択です。1-8から選択してください。\n');
    end
end
end

function auto_cleanup()
% 自動クリーンアップ実行

fprintf('\n--- 自動クリーンアップ ---\n');

% 設定読み込み
settings = load_cleanup_settings();

fprintf('設定:\n');
fprintf('- CSV保持期間: %d日\n', settings.csv_retention_days);
fprintf('- プロット保持数: %d個\n', settings.plot_retention_count);
fprintf('- 自動アーカイブ: %s\n', settings.auto_archive);

confirm = input('\nこの設定でクリーンアップを実行しますか? (y/N): ', 's');
if ~strcmpi(confirm, 'y')
    fprintf('キャンセルしました。\n');
    return;
end

cleanup_count = 0;
archive_count = 0;

% 1. CSVファイルのクリーンアップ
fprintf('\n1. CSVファイルをチェック中...\n');
[csv_cleaned, csv_archived] = cleanup_old_files('*.csv', settings.csv_retention_days, settings.auto_archive);
cleanup_count = cleanup_count + csv_cleaned;
archive_count = archive_count + csv_archived;

% 2. プロットファイルのクリーンアップ  
fprintf('2. プロットファイルをチェック中...\n');
[plot_cleaned, plot_archived] = cleanup_old_files('*.png', settings.plot_retention_count, settings.auto_archive, true);
cleanup_count = cleanup_count + plot_cleaned;
archive_count = archive_count + plot_archived;

% 3. レポートファイルのクリーンアップ
fprintf('3. レポートファイルをチェック中...\n');
[report_cleaned, report_archived] = cleanup_old_files('*.txt', settings.csv_retention_days, settings.auto_archive);
cleanup_count = cleanup_count + report_cleaned;
archive_count = archive_count + report_archived;

% 4. 一時ファイルの削除
fprintf('4. 一時ファイルをチェック中...\n');
temp_cleaned = cleanup_temp_files();
cleanup_count = cleanup_count + temp_cleaned;

fprintf('\n--- クリーンアップ完了 ---\n');
fprintf('削除ファイル: %d個\n', cleanup_count);
fprintf('アーカイブ: %d個\n', archive_count);
fprintf('空き容量の確保完了\n');
end

function cleanup_csv_files()
% CSVファイルの手動整理

fprintf('\n--- CSVファイル整理 ---\n');

% CSV ファイル検索
csv_files = [
    dir('*.csv');
    dir('results/**/*.csv');
    dir('test_cases/**/*.csv')
];

if isempty(csv_files)
    fprintf('CSVファイルが見つかりません。\n');
    return;
end

fprintf('発見されたCSVファイル: %d個\n', length(csv_files));

% ファイル分類
current_files = [];
old_files = [];
cutoff_date = now - 7; % 7日前

for i = 1:length(csv_files)
    if csv_files(i).datenum > cutoff_date
        current_files(end+1) = i;
    else
        old_files(end+1) = i;
    end
end

fprintf('- 最近のファイル: %d個\n', length(current_files));
fprintf('- 古いファイル (7日以上): %d個\n', length(old_files));

if isempty(old_files)
    fprintf('整理対象のファイルはありません。\n');
    return;
end

% 古いファイル一覧表示
fprintf('\n古いファイル一覧:\n');
for i = 1:min(10, length(old_files)) % 最大10個表示
    idx = old_files(i);
    file_age = now - csv_files(idx).datenum;
    fprintf('%d. %s (%.1f日前, %.1fKB)\n', i, csv_files(idx).name, ...
            file_age, csv_files(idx).bytes/1024);
end

if length(old_files) > 10
    fprintf('... 他 %d個\n', length(old_files) - 10);
end

fprintf('\n整理オプション:\n');
fprintf('1. アーカイブに移動\n');
fprintf('2. 削除\n');
fprintf('3. キャンセル\n');

option = input('選択してください (1-3): ');

switch option
    case 1
        move_to_archive(csv_files, old_files);
    case 2
        delete_files(csv_files, old_files);
    case 3
        fprintf('キャンセルしました。\n');
end
end

function cleanup_plot_files()
% プロットファイルの手動整理

fprintf('\n--- プロットファイル整理 ---\n');

plot_files = [
    dir('*.png');
    dir('*.jpg');
    dir('*.fig');
    dir('results/**/*.png');
    dir('results/**/*.jpg');
    dir('results/**/*.fig')
];

if isempty(plot_files)
    fprintf('プロットファイルが見つかりません。\n');
    return;
end

fprintf('発見されたプロットファイル: %d個\n', length(plot_files));

% サイズ順でソート
[~, sort_idx] = sort([plot_files.bytes], 'descend');
sorted_files = plot_files(sort_idx);

% 大きなファイル表示
fprintf('\n大きなファイル (上位10個):\n');
for i = 1:min(10, length(sorted_files))
    file_size_mb = sorted_files(i).bytes / (1024*1024);
    fprintf('%d. %s (%.2f MB)\n', i, sorted_files(i).name, file_size_mb);
end

total_size_mb = sum([plot_files.bytes]) / (1024*1024);
fprintf('\n総サイズ: %.2f MB\n', total_size_mb);

if total_size_mb < 10
    fprintf('サイズが小さいため、整理の必要はありません。\n');
    return;
end

fprintf('\n整理オプション:\n');
fprintf('1. 大きなファイルのみアーカイブ\n');
fprintf('2. 古いファイルをアーカイブ\n');
fprintf('3. 手動選択\n');
fprintf('4. キャンセル\n');

option = input('選択してください (1-4): ');

switch option
    case 1
        % 5MB以上のファイルをアーカイブ
        large_files = find([plot_files.bytes] > 5*1024*1024);
        move_to_archive(plot_files, large_files);
    case 2
        % 30日以上古いファイルをアーカイブ
        old_files = find([plot_files.datenum] < now - 30);
        move_to_archive(plot_files, old_files);
    case 3
        manual_file_selection(plot_files);
    case 4
        fprintf('キャンセルしました。\n');
end
end

function check_disk_usage()
% ディスク容量チェック

fprintf('\n--- ディスク容量チェック ---\n');

% プロジェクトディレクトリのサイズ計算
dirs_to_check = {
    '.',
    'results/',
    'test_cases/',
    'archive/'
};

fprintf('%-20s %10s %8s\n', 'ディレクトリ', 'サイズ', 'ファイル数');
fprintf('%-20s %10s %8s\n', repmat('-', 1, 20), repmat('-', 1, 10), repmat('-', 1, 8));

total_size = 0;
total_files = 0;

for i = 1:length(dirs_to_check)
    dir_path = dirs_to_check{i};
    if exist(dir_path, 'dir')
        [dir_size, file_count] = get_directory_size(dir_path);
        total_size = total_size + dir_size;
        total_files = total_files + file_count;
        
        if dir_size > 1024*1024
            size_str = sprintf('%.1f MB', dir_size/(1024*1024));
        elseif dir_size > 1024
            size_str = sprintf('%.1f KB', dir_size/1024);
        else
            size_str = sprintf('%d B', dir_size);
        end
        
        fprintf('%-20s %10s %8d\n', dir_path, size_str, file_count);
    end
end

fprintf('%-20s %10s %8s\n', repmat('-', 1, 20), repmat('-', 1, 10), repmat('-', 1, 8));
if total_size > 1024*1024
    total_size_str = sprintf('%.1f MB', total_size/(1024*1024));
else
    total_size_str = sprintf('%.1f KB', total_size/1024);
end
fprintf('%-20s %10s %8d\n', '合計', total_size_str, total_files);

% 推奨事項
fprintf('\n--- 推奨事項 ---\n');
if total_size > 100*1024*1024 % 100MB
    fprintf('⚠️  プロジェクトサイズが大きくなっています (%.1f MB)\n', total_size/(1024*1024));
    fprintf('   古いファイルのクリーンアップを推奨します。\n');
elseif total_size > 50*1024*1024 % 50MB
    fprintf('📊 プロジェクトサイズは中程度です (%.1f MB)\n', total_size/(1024*1024));
    fprintf('   定期的なクリーンアップを推奨します。\n');
else
    fprintf('✅ プロジェクトサイズは適切です (%.1f MB)\n', total_size/(1024*1024));
end
end

function verify_file_structure()
% ファイル構造の検証

fprintf('\n--- ファイル構造検証 ---\n');

required_dirs = {
    'test_cases',
    'results',
    'results/csv_data',
    'results/plots', 
    'results/reports',
    'results/individual',
    'results/comparative',
    'archive',
    'archive/old_results',
    'archive/temp_files'
};

missing_dirs = {};
existing_dirs = {};

for i = 1:length(required_dirs)
    if exist(required_dirs{i}, 'dir')
        existing_dirs{end+1} = required_dirs{i};
    else
        missing_dirs{end+1} = required_dirs{i};
    end
end

fprintf('✅ 存在するディレクトリ: %d個\n', length(existing_dirs));
for i = 1:length(existing_dirs)
    fprintf('   %s\n', existing_dirs{i});
end

if ~isempty(missing_dirs)
    fprintf('\n❌ 不足しているディレクトリ: %d個\n', length(missing_dirs));
    for i = 1:length(missing_dirs)
        fprintf('   %s\n', missing_dirs{i});
    end
    
    create_missing = input('\n不足しているディレクトリを作成しますか? (y/N): ', 's');
    if strcmpi(create_missing, 'y')
        for i = 1:length(missing_dirs)
            mkdir(missing_dirs{i});
            fprintf('作成: %s\n', missing_dirs{i});
        end
        fprintf('ディレクトリ構造を修復しました。\n');
    end
else
    fprintf('\n✅ ファイル構造は正常です。\n');
end

% .gitignore の確認
if ~exist('.gitignore', 'file')
    fprintf('\n⚠️  .gitignore ファイルが見つかりません。\n');
    create_gitignore = input('作成しますか? (y/N): ', 's');
    if strcmpi(create_gitignore, 'y')
        create_default_gitignore();
        fprintf('.gitignore を作成しました。\n');
    end
end
end

function manage_archives()
% アーカイブ管理

fprintf('\n--- アーカイブ管理 ---\n');

archive_dir = 'archive/old_results';
if ~exist(archive_dir, 'dir')
    fprintf('アーカイブディレクトリが存在しません。\n');
    return;
end

archive_files = dir(fullfile(archive_dir, '*'));
archive_files = archive_files(~[archive_files.isdir]); % ファイルのみ

if isempty(archive_files)
    fprintf('アーカイブファイルはありません。\n');
    return;
end

fprintf('アーカイブファイル: %d個\n', length(archive_files));

total_size = sum([archive_files.bytes]);
fprintf('総サイズ: %.2f MB\n', total_size/(1024*1024));

% 古いファイル（30日以上）の検出
old_threshold = now - 30;
old_files = archive_files([archive_files.datenum] < old_threshold);

if ~isempty(old_files)
    fprintf('\n30日以上古いファイル: %d個\n', length(old_files));
    fprintf('削除候補サイズ: %.2f MB\n', sum([old_files.bytes])/(1024*1024));
    
    delete_old = input('\n古いアーカイブファイルを削除しますか? (y/N): ', 's');
    if strcmpi(delete_old, 'y')
        for i = 1:length(old_files)
            delete(fullfile(archive_dir, old_files(i).name));
        end
        fprintf('%d個のファイルを削除しました。\n', length(old_files));
    end
end
end

function manage_settings()
% 設定管理

fprintf('\n--- クリーンアップ設定 ---\n');

settings = load_cleanup_settings();

fprintf('現在の設定:\n');
fprintf('1. CSV保持期間: %d日\n', settings.csv_retention_days);
fprintf('2. プロット保持数: %d個\n', settings.plot_retention_count);
fprintf('3. 自動アーカイブ: %s\n', settings.auto_archive);
fprintf('4. 一時ファイル自動削除: %s\n', settings.auto_delete_temp);

fprintf('\n変更する項目を選択 (0=戻る): ');
choice = input('');

switch choice
    case 1
        new_days = input(sprintf('CSV保持期間 (現在: %d日): ', settings.csv_retention_days));
        if ~isempty(new_days) && isnumeric(new_days) && new_days > 0
            settings.csv_retention_days = new_days;
        end
    case 2
        new_count = input(sprintf('プロット保持数 (現在: %d個): ', settings.plot_retention_count));
        if ~isempty(new_count) && isnumeric(new_count) && new_count > 0
            settings.plot_retention_count = new_count;
        end
    case 3
        new_archive = input('自動アーカイブ (true/false): ', 's');
        if strcmpi(new_archive, 'true') || strcmpi(new_archive, 'false')
            settings.auto_archive = new_archive;
        end
    case 4
        new_temp = input('一時ファイル自動削除 (true/false): ', 's');
        if strcmpi(new_temp, 'true') || strcmpi(new_temp, 'false')
            settings.auto_delete_temp = new_temp;
        end
    case 0
        return;
end

save_cleanup_settings(settings);
fprintf('設定を保存しました。\n');
end

% ヘルパー関数群

function settings = load_cleanup_settings()
% デフォルト設定
settings = struct();
settings.csv_retention_days = 7;
settings.plot_retention_count = 10;
settings.auto_archive = 'true';
settings.auto_delete_temp = 'true';

% 設定ファイルがあれば読み込み
if exist('cleanup_settings.mat', 'file')
    loaded = load('cleanup_settings.mat');
    if isfield(loaded, 'settings')
        settings = loaded.settings;
    end
end
end

function save_cleanup_settings(settings)
save('cleanup_settings.mat', 'settings');
end

function [cleaned_count, archived_count] = cleanup_old_files(pattern, threshold, auto_archive, count_based)
if nargin < 4, count_based = false; end

files = dir(pattern);
cleaned_count = 0;
archived_count = 0;

if isempty(files), return; end

if count_based
    % 保持数ベース
    if length(files) > threshold
        [~, sort_idx] = sort([files.datenum], 'descend');
        old_files = files(sort_idx(threshold+1:end));
    else
        old_files = [];
    end
else
    % 日数ベース
    cutoff_date = now - threshold;
    old_files = files([files.datenum] < cutoff_date);
end

for i = 1:length(old_files)
    if strcmpi(auto_archive, 'true')
        move_file_to_archive(old_files(i).name);
        archived_count = archived_count + 1;
    else
        delete(old_files(i).name);
        cleaned_count = cleaned_count + 1;
    end
end
end

function count = cleanup_temp_files()
temp_patterns = {'*.tmp', '*~', '*.asv', '*.m~'};
count = 0;

for i = 1:length(temp_patterns)
    temp_files = dir(temp_patterns{i});
    for j = 1:length(temp_files)
        delete(temp_files(j).name);
        count = count + 1;
    end
end
end

function [total_size, file_count] = get_directory_size(dir_path)
if ~exist(dir_path, 'dir')
    total_size = 0;
    file_count = 0;
    return;
end

files = dir(fullfile(dir_path, '**/*'));
files = files(~[files.isdir]);

total_size = sum([files.bytes]);
file_count = length(files);
end

function move_file_to_archive(filename)
archive_dir = 'archive/old_results';
if ~exist(archive_dir, 'dir')
    mkdir(archive_dir);
end
movefile(filename, fullfile(archive_dir, filename));
end

function move_to_archive(files, indices)
fprintf('アーカイブに移動中...\n');
for i = 1:length(indices)
    idx = indices(i);
    move_file_to_archive(files(idx).name);
end
fprintf('%d個のファイルをアーカイブしました。\n', length(indices));
end

function delete_files(files, indices)
confirm = input(sprintf('%d個のファイルを削除します。よろしいですか? (y/N): ', length(indices)), 's');
if ~strcmpi(confirm, 'y')
    fprintf('キャンセルしました。\n');
    return;
end

fprintf('ファイルを削除中...\n');
for i = 1:length(indices)
    idx = indices(i);
    delete(files(idx).name);
end
fprintf('%d個のファイルを削除しました。\n', length(indices));
end

function manual_file_selection(files)
fprintf('手動選択は今後の実装予定です。\n');
end

function create_default_gitignore()
gitignore_content = [
    '# MATLAB specific files' char(10) ...
    '*.m~' char(10) ...
    '*.asv' char(10) char(10) ...
    '# Results and data files' char(10) ...
    'results/individual/*.mat' char(10) ...
    'results/csv_data/*.csv' char(10) ...
    'results/plots/*.png' char(10) ...
    'archive/old_results/*' char(10) char(10) ...
    '# OS specific files' char(10) ...
    '.DS_Store' char(10) ...
    'Thumbs.db' char(10)
];

fid = fopen('.gitignore', 'w');
fprintf(fid, '%s', gitignore_content);
fclose(fid);
end