function config = test_case_config()
% 各テストケースの設定とメタデータ
%
% 戻り値:
%   config - 各テストケースの設定を含む構造体配列

config = [];

%% IEEE 9-bus (基本テストケース)
config(end+1).name = 'case9';
config(end).description = 'IEEE 9-bus - 基本的な3G3Lシステム';
config(end).matpower_case = 'case9';
config(end).category = 'small';
config(end).generators = 3;
config(end).loads = 3;
config(end).buses = 9;
config(end).branches = 9;
config(end).characteristics = '基本的なテストケース、理論検証に最適';
config(end).expected_performance = 'excellent';
config(end).noise_sensitivity = 'low';
config(end).test_priority = 1;

%% IEEE 14-bus (中規模テストケース)
config(end+1).name = 'case14';
config(end).description = 'IEEE 14-bus - 中規模配電系統';
config(end).matpower_case = 'case14';
config(end).category = 'medium';
config(end).generators = 5;
config(end).loads = 11;
config(end).buses = 14;
config(end).branches = 20;
config(end).characteristics = '中規模、現実的なトポロジー';
config(end).expected_performance = 'good';
config(end).noise_sensitivity = 'medium';
config(end).test_priority = 2;

%% IEEE 30-bus (中規模拡張)
config(end+1).name = 'case30';
config(end).description = 'IEEE 30-bus - 中規模送電系統';
config(end).matpower_case = 'case30';
config(end).category = 'medium';
config(end).generators = 6;
config(end).loads = 20;
config(end).buses = 30;
config(end).branches = 41;
config(end).characteristics = '複雑なメッシュトポロジー';
config(end).expected_performance = 'good';
config(end).noise_sensitivity = 'medium';
config(end).test_priority = 3;

%% IEEE 57-bus (大規模テスト)
config(end+1).name = 'case57';
config(end).description = 'IEEE 57-bus - 大規模送電系統';
config(end).matpower_case = 'case57';
config(end).category = 'large';
config(end).generators = 7;
config(end).loads = 42;
config(end).buses = 57;
config(end).branches = 80;
config(end).characteristics = '大規模、高い冗長性';
config(end).expected_performance = 'fair';
config(end).noise_sensitivity = 'high';
config(end).test_priority = 4;

%% IEEE 118-bus (大規模実用)
config(end+1).name = 'case118';
config(end).description = 'IEEE 118-bus - 大規模実用系統';
config(end).matpower_case = 'case118';
config(end).category = 'large';
config(end).generators = 54;
config(end).loads = 99;
config(end).buses = 118;
config(end).branches = 186;
config(end).characteristics = '実用規模、複雑な構造';
config(end).expected_performance = 'challenging';
config(end).noise_sensitivity = 'very_high';
config(end).test_priority = 5;

%% IEEE 300-bus (超大規模)
config(end+1).name = 'case300';
config(end).description = 'IEEE 300-bus - 超大規模系統';
config(end).matpower_case = 'case300';
config(end).category = 'xlarge';
config(end).generators = 69;
config(end).loads = 196;
config(end).buses = 300;
config(end).branches = 411;
config(end).characteristics = '超大規模、数値的挑戦';
config(end).expected_performance = 'difficult';
config(end).noise_sensitivity = 'extreme';
config(end).test_priority = 6;

% 設定の表示
fprintf('テストケース設定一覧:\n');
fprintf('%-10s %-8s %4s %4s %4s %4s %-15s\n', 'Case', 'Category', 'Bus', 'Gen', 'Load', 'Br', 'Performance');
fprintf('%-10s %-8s %4s %4s %4s %4s %-15s\n', repmat('-', 1, 10), repmat('-', 1, 8), repmat('-', 1, 4), repmat('-', 1, 4), repmat('-', 1, 4), repmat('-', 1, 4), repmat('-', 1, 15));
for i = 1:length(config)
    fprintf('%-10s %-8s %4d %4d %4d %4d %-15s\n', ...
        config(i).name, config(i).category, config(i).buses, ...
        config(i).generators, config(i).loads, config(i).branches, ...
        config(i).expected_performance);
end
fprintf('\n');

end