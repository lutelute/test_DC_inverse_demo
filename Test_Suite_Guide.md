# DC潮流逆問題テストスイートガイド

## 概要

このテストスイートは、DC潮流逆問題の実装を複数のIEEEテストケースで検証し、性能を比較分析するためのフレームワークです。

## テストケース一覧

### 小規模システム
- **case9**: IEEE 9-bus (3G-3L) - 基本検証用
- **case14**: IEEE 14-bus (5G-11L) - 標準ベンチマーク

### 中規模システム  
- **case30**: IEEE 30-bus (6G-20L) - 現実的規模
- **case57**: IEEE 57-bus (7G-42L) - 複雑なトポロジー

### 大規模システム
- **case118**: IEEE 118-bus (54G-99L) - 実用規模
- **case300**: IEEE 300-bus (69G-196L) - 超大規模

## 使用方法

### 1. 基本的な使用法

```matlab
% テストスイート管理画面を開く
test_suite_manager();
```

### 2. プログラマティックな実行

```matlab
% 全ケース標準実行
run_all_test_cases();

% 高速モード（開発時）
run_all_test_cases('quick', true);

% 詳細モード（研究用）
run_all_test_cases('detailed', true);

% 特定ケースのみ
run_all_test_cases('cases', {'case9', 'case14'});

% 並列実行
run_all_test_cases('parallel', true);
```

### 3. 結果の分析

```matlab
% 最新結果の比較分析
comparative_analysis();

% 特定結果ファイルの分析
comparative_analysis('results/all_test_results_20241006_123456.mat');
```

## テスト項目

### 基本性能テスト
1. **精度テスト**: 理想条件での復元精度
2. **一貫性テスト**: 複数実行での結果安定性
3. **電力収支テスト**: エネルギー保存則の確認

### ノイズ感度テスト
- ノイズレベル: 0%, 0.01%, 0.1%, 0.5%, 1%, 2%, 5%
- 統計回数: 20回（高速）〜100回（標準）
- 評価指標: 成功率、平均誤差、標準偏差

### 数値的安定性テスト
- 条件数評価
- 特異値分解
- ランク不足の検出
- 疑似逆行列の安定性

## 結果の解釈

### 成功判定基準
- 相対誤差 < 1e-6 (位相角、電力注入)
- 残差ノルム < 1e-9
- 数値的収束の確認

### 性能指標
1. **精度**: 理想条件での誤差
2. **ロバスト性**: ノイズ耐性
3. **安定性**: 条件数と特異値
4. **効率性**: 実行時間

### ケース別特徴

#### case9 (IEEE 9-bus)
- **特徴**: 最小構成、理論検証向け
- **期待性能**: 機械精度レベルの復元
- **用途**: アルゴリズム開発、デバッグ

#### case14 (IEEE 14-bus)  
- **特徴**: 標準ベンチマーク
- **期待性能**: 高精度、良好なノイズ耐性
- **用途**: 性能比較、検証

#### case30 (IEEE 30-bus)
- **特徴**: 実用的中規模システム
- **期待性能**: 実用レベルの精度
- **用途**: 実装検証、現実的評価

#### case57 (IEEE 57-bus)
- **特徴**: 複雑なトポロジー
- **期待性能**: 数値的挑戦
- **用途**: 安定性評価、限界テスト

#### case118 (IEEE 118-bus)
- **特徴**: 実用規模
- **期待性能**: 計算資源との tradeoff
- **用途**: スケーラビリティ評価

#### case300 (IEEE 300-bus)
- **特徴**: 超大規模
- **期待性能**: 数値的困難
- **用途**: 極限性能評価

## ファイル構造

```
test_cases/
├── test_case_config.m          # ケース設定
├── case9/                      # IEEE 9-bus 個別結果
│   └── result_*.mat
├── case14/                     # IEEE 14-bus 個別結果
│   └── result_*.mat
└── ...

results/
├── all_test_results_*.mat      # 統合結果
├── summary_report_*.txt        # サマリーレポート
├── comparative_report_*.txt    # 比較分析レポート
├── ci_report.txt              # CI用レポート
├── individual/                # 個別詳細結果
├── comparative/               # 比較分析詳細
└── plots/                     # 生成プロット
    ├── scale_performance_*.png
    ├── error_analysis_*.png
    ├── noise_sensitivity_*.png
    └── numerical_stability_*.png
```

## 継続的統合 (CI)

### 自動テスト
テストスイートはCI環境での自動実行をサポートします：

```matlab
% CI用レポート生成
test_suite_manager();  % -> 8. 継続的統合レポート

% または直接
run_all_test_cases('quick', true);
```

### 終了コード
- 0: 全テスト成功
- 1: 1つ以上のテスト失敗

### CI設定例 (.github/workflows/test.yml)
```yaml
name: DC Inverse Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup MATLAB
      uses: matlab-actions/setup-matlab@v1
    - name: Run Test Suite
      run: |
        matlab -batch "run_all_test_cases('quick', true)"
    - name: Upload Results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: results/
```

## トラブルシューティング

### よくある問題

#### 1. MATPOWERが見つからない
```
エラー: Undefined function 'loadcase'
解決: MATPOWERをMATLABパスに追加
```

#### 2. メモリ不足（大規模ケース）
```
エラー: Out of memory
解決: 'quick'モードまたは小規模ケースから開始
```

#### 3. 数値的不安定
```
警告: Matrix is close to singular
解決: 条件数をチェック、正則化検討
```

#### 4. 結果ファイルが見つからない
```
エラー: No result files found
解決: 先にrun_all_test_cases()を実行
```

### デバッグのヒント

1. **段階的テスト**: case9から開始
2. **ログ確認**: 各ケースのエラーメッセージ
3. **条件数監視**: 数値的困難の早期発見
4. **メモリ使用量**: 大規模ケースでの監視

## 拡張ガイド

### 新しいテストケースの追加

1. `test_case_config.m`に設定追加
2. フォルダ作成: `mkdir test_cases/new_case`
3. MATPOWERケースの準備
4. テスト実行で自動対応

### カスタム評価指標

`run_single_test_case()`関数を修正して独自の評価指標を追加可能。

### 並列化の最適化

大規模ケースでは並列処理プールの設定を調整：

```matlab
% 並列プール設定
delete(gcp('nocreate'));
parpool('local', 4);  % 4ワーカー
```

## 参考文献

- IEEE Power System Test Cases
- MATPOWER Documentation
- DC Power Flow Theory
- Numerical Linear Algebra