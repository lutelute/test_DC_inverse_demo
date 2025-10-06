# DC潮流逆問題の数学的理論

## 問題設定

### 目的
1. **真値生成**: 任意の母線注入 $P^{\star}$ (3G・3L) から順方向DC潮流で $\theta^{\star}, f^{\star}$ を作る
2. **逆推定**: $f^{\star}$ のみを用いて $\hat{\theta}, \hat{P}$ を復元  
3. **検証**: $\hat{P} \approx P^{\star}$, $\hat{f} = B_f\hat{\theta} \approx f^{\star}$ を数値で確認

### 数式（DC近似）

#### 基本方程式
- **枝潮流**: $f = B_f \theta$, where $B_f = \text{diag}(b) A$
- **母線注入**: $P = B_{\text{bus}} \theta$, where $B_{\text{bus}} = A^{\top} \text{diag}(b) A$  
- **基準角**: $\theta_{\text{ref}} = 0$

#### 逆問題の定式化
$$\hat{\theta} = \arg\min_{\theta: \theta_{\text{ref}} = 0} \|B_f \theta - f^{\star}\|_2^2$$

$$\hat{P} = B_{\text{bus}} \hat{\theta}$$

## 数学的性質

### 1. 行列の特性

#### サセプタンス行列 $B_{\text{bus}}$
- **対称性**: $B_{\text{bus}} = B_{\text{bus}}^{\top}$ 
- **半正定値**: すべての固有値 $\geq 0$
- **特異性**: $\text{rank}(B_{\text{bus}}) = n-1$ (基準バスによる)
- **物理的意味**: ネットワークのアドミタンス構造を表現

#### 枝-母線関係行列 $B_f$
- **サイズ**: $m \times n$ (通常 $m > n-1$ で過剰決定)
- **構造**: $B_f = \text{diag}(b) A$
- **ランク**: $\text{rank}(B_f) \leq n-1$
- **物理的意味**: 位相差から枝潮流への変換

### 2. 接続行列 $A$

#### 定義
$A \in \mathbb{R}^{m \times n}$ where:
$$A_{ij} = \begin{cases}
+1 & \text{if bus } j \text{ is the "from" bus of branch } i \\
-1 & \text{if bus } j \text{ is the "to" bus of branch } i \\
0 & \text{otherwise}
\end{cases}$$

#### 性質
- **Kirchhoffの法則**: $A^{\top} \mathbf{1} = \mathbf{0}$ (電流保存則)
- **ランク**: $\text{rank}(A) = n-1$ (連結グラフの場合)
- **ヌル空間**: $\text{null}(A^{\top}) = \text{span}(\mathbf{1})$

## 最小二乗解の解析

### 3. 逆問題の解法

#### 制約付き最小二乗問題
基準バス制約 $\theta_{\text{ref}} = 0$ の下で:

$$\min_{\theta} \|B_f \theta - f^{\star}\|_2^2$$

#### 縮約問題
$\theta = [\theta_{\text{keep}}^{\top}, 0]^{\top}$ として:

$$\min_{\theta_{\text{keep}}} \|B_f(:, \text{keep}) \theta_{\text{keep}} - f^{\star}\|_2^2$$

#### 正規方程式
$$B_f(:, \text{keep})^{\top} B_f(:, \text{keep}) \theta_{\text{keep}} = B_f(:, \text{keep})^{\top} f^{\star}$$

### 4. 解の存在と一意性

#### 定理 1: 解の存在
$f^{\star} \in \text{range}(B_f)$ ならば、最小二乗解が存在する。

**証明**: $B_f$ の疑似逆行列 $B_f^{\dagger}$ により $\hat{\theta} = B_f^{\dagger} f^{\star}$ として構成可能。

#### 定理 2: 解の一意性  
$\text{rank}(B_f(:, \text{keep})) = n-1$ ならば、最小二乗解は一意。

**証明**: 正規方程式の係数行列 $B_f(:, \text{keep})^{\top} B_f(:, \text{keep})$ が正則となる。

### 5. 数値的安定性

#### 条件数による誤差増幅
入力誤差 $\|\delta f\|$ に対する出力誤差の上界:

$$\frac{\|\delta \theta\|}{\|\theta\|} \leq \kappa(B_f(:, \text{keep})) \frac{\|\delta f\|}{\|f\|}$$

where $\kappa(\cdot)$ は条件数。

#### 実用的考慮
- **良条件**: $\kappa < 10^{12}$ (倍精度での安全域)
- **悪条件**: $\kappa > 10^{15}$ (数値的不安定)

## 物理的解釈

### 6. エネルギー保存則

#### DC近似での電力収支
$$\sum_{i=1}^n P_i = 0$$

これは $P = B_{\text{bus}} \theta$ と $B_{\text{bus}} \mathbf{1} = \mathbf{0}$ から導かれる。

#### 損失の無視
DC近似では抵抗成分を無視するため:
- 有効電力損失 $= 0$
- 電圧振幅 $= 1.0$ pu (一定)

### 7. ネットワーク理論との関係

#### グラフ理論的観点
- **頂点**: 母線 (buses)
- **辺**: 送電線 (branches)  
- **重み**: サセプタンス $b$

#### 代数的観点
- **ラプラシアン行列**: $L = A^{\top} A$ (重みなし)
- **重み付きラプラシアン**: $B_{\text{bus}} = A^{\top} \text{diag}(b) A$

## 実装上の注意点

### 8. 数値計算の考慮

#### 推奨アルゴリズム
1. **QR分解**: $B_f(:, \text{keep}) = QR$  
2. **SVD**: 特異値分解による安定解法
3. **正規方程式**: 良条件の場合のみ

#### 警戒すべき状況
- **島化**: $\text{rank}(B_f) < n-1$
- **近特異**: $\kappa(B_f(:, \text{keep})) > 10^{12}$
- **数値誤差**: 残差 $\|B_f \hat{\theta} - f^{\star}\| > \text{tol}$

### 9. 実データでの課題

#### ノイズ耐性
観測ノイズ $f_{\text{meas}} = f^{\star} + \epsilon$ に対して:

$$\mathbb{E}[\|\hat{\theta} - \theta^{\star}\|^2] \leq \kappa^2(B_f) \mathbb{E}[\|\epsilon\|^2]$$

#### 正則化手法
悪条件問題に対する対策:
- **Tikhonov正則化**: $\min \|B_f \theta - f\|^2 + \lambda \|\theta\|^2$
- **切り捨てSVD**: 小特異値の除去

## 検証手法

### 10. 誤差評価指標

#### 相対誤差
- **位相角**: $\varepsilon_{\theta} = \frac{\|\hat{\theta} - \theta^{\star}\|}{\|\theta^{\star}\|}$
- **電力**: $\varepsilon_P = \frac{\|\hat{P} - P^{\star}\|}{\|P^{\star}\|}$  
- **潮流**: $\varepsilon_f = \frac{\|\hat{f} - f^{\star}\|}{\|f^{\star}\|}$

#### 成功判定基準
通常、以下を満たす場合を「成功」とする:
$$\varepsilon_{\theta}, \varepsilon_P, \varepsilon_f < 10^{-6}$$

### 11. 理論限界

#### 情報理論的下界
$m$ 個の枝潮流から $n-1$ 個の位相角を推定する問題では、必要条件:
$$m \geq n-1$$

#### 実用的要求
数値安定性を考慮すると:
$$m \geq 1.5(n-1)$$ 
程度の冗長性が望ましい。

## 結論

DC潮流逆問題は以下の数学的特徴を持つ:

1. **線形性**: 線形最小二乗問題として定式化可能
2. **一意性**: 適切な条件下で解が一意に決定  
3. **安定性**: 条件数に依存した数値的安定性
4. **物理的整合性**: エネルギー保存則を満足

この理論的基盤により、実用的な電力系統状態推定アルゴリズムの構築が可能となる。