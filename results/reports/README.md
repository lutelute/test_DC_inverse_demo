# Reports Directory

このディレクトリには、テスト実行結果のレポートファイルが保存されます。

## レポートの種類

### 実行サマリー
- `summary_report_*.txt` - テスト実行サマリー
- `ci_report.txt` - 継続的統合用レポート

### 詳細分析
- `detailed_results.txt` - 詳細な数値結果
- `comparative_report_*.txt` - ケース間比較分析
- `mathematical_analysis_*.txt` - 数学的検証結果

### 性能評価
- `performance_benchmark_*.txt` - 性能ベンチマーク
- `scaling_analysis_*.txt` - スケーラビリティ分析

## レポート生成方法

```matlab
% 自動レポート生成
run_all_test_cases();              % 基本レポート
test_suite_manager();              % 統合レポート管理
comparative_analysis();            % 比較分析レポート
```

## レポート形式

### サマリーレポート例
```
DC潮流逆問題：全テストケース実行レポート
============================================

実行日時: 2024-10-06 12:34:56
総実行時間: 45.67秒

実行統計:
- 成功: 5 ケース
- エラー: 1 ケース
- 成功率: 83.3%

各ケース結果:
Case       Status   θ Error      P Error      Time[s]
------------------------------------------------------
case9      success  1.234e-12    5.678e-13    2.45
case14     success  2.345e-11    6.789e-12    5.67
...
```

## CI統合

継続的統合環境では `ci_report.txt` が自動生成され、テスト結果を判定します。