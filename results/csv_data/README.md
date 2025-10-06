# CSV Data Directory

このディレクトリには、テスト実行で生成されるCSVデータファイルが保存されます。

## ファイルの種類

### ノイズ感度分析結果
- `noise_analysis_summary.csv` - ノイズレベル別成功率サマリー
- `noise_*.csv` - 個別ノイズレベルでの詳細結果

### バッチ実行ログ
- `dc_batch_log_*.csv` - バッチ実行の詳細ログ
- `all_test_results_*.csv` - 全テストケース統合結果

### 比較分析結果
- `comparative_summary_*.csv` - ケース間比較サマリー
- `performance_metrics_*.csv` - 性能指標詳細

## ファイル命名規則

```
{analysis_type}_{case_name}_{timestamp}.csv
```

例:
- `noise_case9_20241006_123456.csv`
- `batch_all_20241006_123456.csv`

## データ保持ポリシー

- 最新10回分の結果を保持
- 古い結果は自動的に `archive/old_results/` に移動
- 重要な結果は手動で保護可能