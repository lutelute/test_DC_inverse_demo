# Plots Directory

このディレクトリには、分析結果の可視化ファイルが保存されます。

## プロットの種類

### 基本分析プロット
- `dc_inverse_3steps_visualization_*.png` - 3ステップ過程の可視化
- `matrix_structure_visualization_*.png` - 行列構造可視化
- `error_analysis_visualization_*.png` - 誤差解析
- `network_diagram_visualization_*.png` - ネットワーク図

### 比較分析プロット
- `scale_performance_analysis_*.png` - システム規模vs性能
- `noise_sensitivity_comparison_*.png` - ノイズ感度比較
- `numerical_stability_*.png` - 数値的安定性分析
- `execution_time_analysis_*.png` - 実行時間分析

### ノイズ感度分析
- `noise_sensitivity_analysis.png` - ノイズ感度総合分析

## ファイル形式

- **PNG**: Web表示・レポート用（推奨）
- **MATLAB Fig**: 再編集可能形式
- **PDF**: 論文・プレゼンテーション用

## 使用方法

```matlab
% プロット生成
visualize_inverse_process();          % 基本可視化
comparative_analysis();               % 比較分析プロット
run_all_test_cases('save_plots', true); % 全プロット生成
```