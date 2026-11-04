# ② 別Notebook共通関数の参照呼出し事前検証

設計書ID: CMN-02 / 版: 2.0.0 / 作成日: 2026-11-05

方式AとしてNB_CommonFunctionsを同一ワークスペースに配置し、呼出元から単独セルの%runで定義を参照する。純PythonとSpark Columnの両方で文字列整形が同じ期待値になることを検証し、参照だけで読書きやNotebook終了が起きないことを確認する。

## 一覧

### 設計管理

項目: 設計書ID / 内容: CMN-02 / 項目: 版 / 内容: 2.0.0

項目: 作成日 / 内容: 2026-11-05 / 項目: 対象 / 内容: OneForce / Microsoft Fabric

項目: 文書状態 / 内容: レビュー用初版（環境未検証） / 項目: 承認者 / 内容: 未設定

項目: 原資料 / 内容: [ItemName]_DetailedDesign_テンプレート.xlsx / 項目: 参照サンプル / 内容: Warehouse_ProcedureDesign.xlsx

項目: 対象機能 / 内容: ② 別Notebook共通関数の参照呼出し事前検証 / 項目: 実装原本 / 内容: ソース対応シートを参照

項目: ローカル検証 / 内容: Python単体47件成功 / Notebook構文確認済み / 項目: 実環境検証 / 内容: SQL / Fabric / Spark は未実施

### 本書の前提・未確定事項

ID: U01 / 項目: 接続先・実体 / 内容: 前回のGoldLakehouse SQL分析エンドポイントを基準。Warehouseサンプル名はDataWarehouse。実際の配置先は導入時に確定。 / 状態: 実装前確認

ID: U02 / 項目: テーブル完全定義 / 内容: dbo.jp_dw_dsj_productitem_dim / productitemnamekanjiを引継ぐ。PK・全列・データ量・連携先型長は未提示。 / 状態: 本番適用前確認

ID: U03 / 項目: 承認・権限 / 内容: Preview利用可否、DDL/実行/読取/出力権限、担当者・承認者を確定。資格情報はソースに保持しない。 / 状態: 管理者確認

ID: U04 / 項目: 非機能 / 内容: 容量/件数/SLA/ログ保管/出力保存期間/監視通知の業務値は未確定。測定・運用設計後に確定。 / 状態: 運用前確認

ID: U05 / 項目: 業務範囲 / 内容: 税込計算・コード大文字化の汎用サンプルではなく、前回の文字列整形を実装対象とする。 / 状態: 本版の対象

ID: U06 / 項目: MERGE対象外 / 内容: Warehouseサンプル一覧の2026-10-27メモ（Fabric内MERGE不要）を踏まえ、MERGE/削除/既存表更新を実装しない。 / 状態: 参照は書式・記述粒度

## 詳細設計

### パラメータ・実行条件

項目: 共通Notebook / 説明: 定義だけを持つ参照先。 / デフォルト / 値: NB_CommonFunctions / 備考: 実装原本:common_functions.py

項目: 検証Notebook / 説明: Python/Sparkの期待値照合。 / デフォルト / 値: NB_CommonReference_Precheck / 備考: 同一ワークスペース

項目: 呼出方法 / 説明: %runを単独のコードセルに記載。 / デフォルト / 値: %run NB_CommonFunctions / 備考: 通常のimportやrun()とは区別

項目: ランタイム / 説明: Fabric NotebookのPySpark / 既存sparkを利用。 / デフォルト / 値: 対象環境のサポート済ランタイム / 備考: SparkSessionを新規生成しない

項目: 既定Lakehouse / 説明: 参照先は親と同一または継承。 / デフォルト / 値: GoldLakehouse（導入時設定） / 備考: ワークスペースIDは埋込まない

項目: 入力データ / 説明: 外部テーブル不要の固定20ケース。 / デフォルト / 値: tests/normalization_cases.json / 備考: Notebook内にも同じ期待値を保持

### 事前チェック

ID: P01 / チェック内容: Notebook名が一致し、同一ワークスペースに配置されている。 / NG時の動作: Fabricの参照エラーで停止。 / 対応機能: %run

ID: P02 / チェック内容: 共通Notebookが定義のみであり、パラメータ再設定やexitを含まない。 / NG時の動作: 共通Notebookを修正してから参照する。 / 対応機能: NB_CommonFunctions

ID: P03 / チェック内容: PySparkが使用可能。参照先と親のLakehouse設定が整合。 / NG時の動作: セッション/接続設定を確認。 / 対応機能: 手動確認

ID: P04 / チェック内容: 取り込んだライブラリ版が2.0.0である。 / NG時の動作: 版不一致はデプロイ漏れとして調査。 / 対応機能: COMMON_VERSION

### 処理ロジック

ステップ: 1 / 処理内容: NB_CommonFunctionsを参照する。 / 判定 / 出力: 定義のみを読込み。読書き・exitなし。 / 対応ソース: %run独立セル

ステップ: 2 / 処理内容: normalize_textを固定20ケースで実行する。 / 判定 / 出力: Pythonの==でNULL/空文字/制御文字を厳密比較。 / 対応ソース: NB_CommonReference_Precheck

ステップ: 3 / 処理内容: 不正入力型と不正識別子を試験する。 / 判定 / 出力: CommonErrorを検出。暗黙変換しない。 / 対応ソース: CMN001 / CMN002

ステップ: 4 / 処理内容: 明示StringTypeのDataFrameを作成し、整形列を追加する。 / 判定 / 出力: 組込みregexp_replace。Python UDFは不使用。 / 対応ソース: transform_dataframe

ステップ: 5 / 処理内容: Spark結果をeqNullSafeで期待値と照合する。 / 判定 / 出力: 不一致case_idのみ取得。全量データcollectなし。 / 対応ソース: 20ケースの小規模試験

ステップ: 6 / 処理内容: 二重適用時の引用符増加を確認する。 / 判定 / 出力: 非冪等性を仕様として明示する。 / 対応ソース: TXT21

ステップ: 7 / 処理内容: 件数・版をJSONで出力し証跡保存。 / 判定 / 出力: status=PASS / Python20 / Spark20。 / 対応ソース: 環境実行後に判定

### 関数一覧

関数名: normalize_text / 説明: Python単一値の整形。 / 入出力概要: str|None → str|None / 備考: 型不正CMN001 / NUL CMN008

関数名: normalize_text_col / 説明: Spark Column式の整形。 / 入出力概要: 文字列Column → Column / 備考: 呼出側で型/NUL品質保証

関数名: transform_dataframe / 説明: 原文を保持して新しい整形列を追加。 / 入出力概要: DataFrame, 元列名, 出力列名 → DataFrame / 備考: 遅延評価。既存列上書き禁止

関数名: validate_identifier / 説明: 単一名の形式を検証。 / 入出力概要: str → str / 備考: 最大128文字

関数名: quote_table_name / 説明: 1～3階層のテーブル名を検証・引用。 / 入出力概要: str → バッククォート付きstr / 備考: 動的な任意SQLは受け付けない

関数名: その他の共通処理 / 説明: 設定/戻り値検査、JSONログ、Notebook呼出し補助。 / 入出力概要: ④の入出力・処理仕様を参照。 / 備考: 参照時は実行されない

### 共通文字列整形規則

規則: C01 / 項目: NULL / None / 処理内容: 入力NULLはNULLを返す。空文字とは区別。 / 注意: SQL/Python/Spark共通

規則: C02 / 項目: 両端空白 / 処理内容: U+0020（半角）、U+00A0（NBSP）、U+3000（全角）だけを両端から連続除去。 / 注意: 途中の空白は保持

規則: C03 / 項目: 二重引用符 / 処理内容: ASCIIの " を "" に置換する。大小文字や全角引用符は変更しない。 / 注意: 空白除去後に実施

規則: C04 / 項目: 制御文字 / 処理内容: タブ・CR・LFを保持。末尾改行の直前にある空白も内部文字として保持。 / 注意: Sparkは厳密末尾アンカー

規則: C05 / 項目: 非冪等 / 処理内容: 引用符のある値を再適用するとさらに二重化される。未加工の原文に一度だけ適用。 / 注意: 元列を上書きしない

規則: C06 / 項目: 対象外入力 / 処理内容: U+0000はSQLとの共通契約外。Python/共通ジョブではCMN008で拒否。SQL呼出前に品質確認が必要。 / 注意: SQL Function内では検査しない

規則: C07 / 項目: 長さ / 処理内容: varchar(max)を用いて固定長による切捨てを避ける。元データ取得時・連携先格納時の型上限は別途確認。 / 注意: TXT20は5,000→10,000バイト

規則: C08 / 項目: 用途境界 / 処理内容: CSVの完全なレコード出力機能でもSQLのエスケープ機能でもない。CSV writerの自動エスケープと二重適用しない。 / 注意: SQL値は別途パラメータ化

### エラー処理

コード: CMN001 / 条件: Python入力型不正 / 対応: strまたはNoneを指定する。暗黙のstr変換はしない。 / 備考: normalize_text

コード: CMN002 / 条件: テーブル/列識別子不正 / 対応: ASCII英数字・下線、1～3階層、単一名128文字以内を確認。 / 備考: validate_identifier / quote_table_name

コード: CMN003 / 条件: JSON/設定不正 / 対応: 16KB以内のJSONオブジェクト。未知キー・重複キー・NaN・文字列boolを拒否。 / 備考: parse_config

コード: CMN004 / 条件: 元列なし/型不正/列重複 / 対応: 存在・厳密な列名・StringTypeを確認。 / 備考: transform_dataframe

コード: CMN005 / 条件: 出力列名衝突 / 対応: 大文字小文字を無視して既存列との衝突を拒否。別名を指定。 / 備考: 元列を保護

コード: CMN008 / 条件: U+0000を検出 / 対応: 原文品質を修正。黙って削除しない。 / 備考: normalize_text / run_transform_job

コード: Fabric固有例外 / 条件: タイムアウト/未配置/権限/読書きエラー / 対応: 子から再raiseし、親でも再raiseする。成功JSONに変換しない。 / 備考: 自動再試行なし

### 設計上の注意点

項目: 参照と実行の違い / 内容: %runは現在コンテキストへ定義を読込む。run()の戻り値契約とは別。 / 受入条件: ②と④の用途を混同しない。 / 参照: R06/R07

項目: 名前衝突 / 内容: 共通公開名を呼出元で再定義しない。参照し直すと定義が置換される。 / 受入条件: 版を統一して回帰試験する。 / 参照: ソース一覧

項目: 末尾改行 / 内容: Java正規表現の厳密末尾アンカーを使用。末尾改行直前の空白を削除しない。 / 受入条件: TXT13がPython/Sparkで一致。 / 参照: R08

項目: 再参照 / 内容: 定義を再読込みできるが、整形済みデータを再整形してよい意味ではない。 / 受入条件: 引用符増加を回避。 / 参照: TXT21

## 入出力定義

### 入出力仕様

項目: value / 方向 / 型: IN / str|None / 内容: 単一文字列、Noneを許可。数値/bool/bytesは拒否。 / 備考: normalize_text

項目: column / 方向 / 型: IN / Spark Column / 内容: StringTypeかつU+0000を含まない列。 / 備考: normalize_text_colは型検査を委譲

項目: df / source_column / output_column / 方向 / 型: IN / DataFrame / str / str / 内容: 元列存在、重複列名なし、出力列衝突なし。 / 備考: transform_dataframe

項目: 戻りDataFrame / 方向 / 型: OUT / DataFrame / 内容: 全元列を保持＋整形列1列を追加。 / 備考: 元DataFrameを破壊しない

項目: 検証結果 / 方向 / 型: OUT / JSONログ / 内容: status, python_cases, spark_cases, library_version。 / 備考: 環境試験結果を保存

## テスト仕様

### 文字列整形の期待値

ケース / 観点: TXT01 NULL / 入力（JSON表記）: NULL / None / 期待結果（JSON表記）: NULL / None / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT02 空文字 / 入力（JSON表記）: "" / 期待結果（JSON表記）: "" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT03 半角空白のみ / 入力（JSON表記）: "   " / 期待結果（JSON表記）: "" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT04 全角空白のみ / 入力（JSON表記）: "<全角空白><全角空白>" / 期待結果（JSON表記）: "" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT05 NBSPのみ / 入力（JSON表記）: "<NBSP><NBSP>" / 期待結果（JSON表記）: "" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT06 混在した前後空白 / 入力（JSON表記）: " <全角空白><NBSP>製品A<全角空白> <NBSP>" / 期待結果（JSON表記）: "製品A" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT07 引用符 / 入力（JSON表記）: " A\"B " / 期待結果（JSON表記）: "A\"\"B" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT08 連続引用符 / 入力（JSON表記）: "\"\"" / 期待結果（JSON表記）: "\"\"\"\"" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT09 内部空白保持 / 入力（JSON表記）: " A B<NBSP>C<全角空白>D " / 期待結果（JSON表記）: "A B<NBSP>C<全角空白>D" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT10 タブ保持 / 入力（JSON表記）: "\tA\t" / 期待結果（JSON表記）: "\tA\t" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT11 改行保持 / 入力（JSON表記）: "\nA\n" / 期待結果（JSON表記）: "\nA\n" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT12 CRLF保持 / 入力（JSON表記）: " A\r\nB " / 期待結果（JSON表記）: "A\r\nB" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT13 最終改行の直前空白を保持 / 入力（JSON表記）: " A \n" / 期待結果（JSON表記）: "A \n" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT14 先頭タブ直後の空白を保持 / 入力（JSON表記）: "\t A " / 期待結果（JSON表記）: "\t A" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT15 シングルクォート保持 / 入力（JSON表記）: " O'Brien " / 期待結果（JSON表記）: "O'Brien" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT16 絵文字 / 入力（JSON表記）: " 😀製品 " / 期待結果（JSON表記）: "😀製品" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT17 除去対象外の細い空白 / 入力（JSON表記）: "<細い空白>A<細い空白>" / 期待結果（JSON表記）: "<細い空白>A<細い空白>" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT18 大小文字保持 / 入力（JSON表記）: " aBc " / 期待結果（JSON表記）: "aBc" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT19 全角二重引用符保持 / 入力（JSON表記）: " ＂A＂ " / 期待結果（JSON表記）: "＂A＂" / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT20 8000バイト超の引用符展開 / 入力（JSON表記）: ASCII二重引用符×5,000 / 期待結果（JSON表記）: ASCII二重引用符×10,000 / 実施状態: Python成功 / Spark未実施

ケース / 観点: TXT21 非冪等性 / 入力（JSON表記）: 二重引用符1個を2回適用 / 期待結果（JSON表記）: 二重引用符4個 / 実施状態: Python成功 / Spark未実施

### 機能固有の試験

ID: NB01 / 観点 / 条件: 同一ワークスペースの%run / 期待結果: 全公開関数・版を参照できる。 / 実施状態: Fabric未実施

ID: NB02 / 観点 / 条件: 存在しない参照Notebook / 期待結果: Fabric参照エラーで停止。 / 実施状態: Fabric未実施

ID: NB03 / 観点 / 条件: 入力が数値/不正識別子 / 期待結果: CMN001/CMN002で拒否。 / 実施状態: ローカル47件に含む / 成功

ID: NB04 / 観点 / 条件: 出力列衝突/元列なし/非文字型 / 期待結果: CMN004/CMN005で拒否。 / 実施状態: Spark未実施 / 手動追加ケース

ID: NB05 / 観点 / 条件: 再参照・副作用確認 / 期待結果: 参照だけでI/O/exitなし。再読込後の版が同じ。 / 実施状態: Fabric未実施

## 導入・運用

### 実行手順

順序: 1 / 操作: NB_CommonFunctions.ipynbを取込み、名前を正確に合わせる。 / 確認内容: 同一ワークスペース。PySpark設定を確認。 / 注意: 取込後の自動改名に注意

順序: 2 / 操作: NB_CommonReference_Precheck.ipynbを取込む。 / 確認内容: 既定Lakehouseを同一または継承に設定。 / 注意: 接続IDの埋込みはしていない

順序: 3 / 操作: 検証Notebookを先頭から全セル実行する。 / 確認内容: %runは独立セル。コードセルのまとめ貼付は禁止。 / 注意: cells.txtでセル境界を確認

順序: 4 / 操作: 結果・ランタイム・実行時間・版を記録する。 / 確認内容: Python/Spark20ケース一致、異常値拒否。 / 注意: ④の前提条件

### 受入・証跡

項目: ソース整合 / 合格基準: 設計書記載の関数名・ファイル名・既定値と実装が一致。 / 証跡: ソース対応 / manifest.sha256 / 状態: 生成時照合済み

項目: ローカル試験 / 合格基準: 47テストメソッドすべて成功。 / 証跡: evidence/local_unittest.txt / 状態: 成功

項目: 構文検査 / 合格基準: Python原本/試験、Notebookコードセルの構文が妥当。 / 証跡: evidence/static_validation.txt / 状態: 成功（%runはFabric専用）

項目: 環境試験 / 合格基準: 各テスト仕様のSQL/Fabric/Spark試験を実環境で実施。 / 証跡: 実行ID/接続先/日時/実行者/結果 / 状態: 未実施

項目: 本番受入 / 合格基準: 型・権限・物理DDL・Preview許可・件数/性能・運用を承認。 / 証跡: レビュー/環境測定記録 / 状態: 未実施

## ソース対応

### 設計とソースの対応

ID: S01 / 役割: 共通関数原本 / 相対パス: python/common_functions.py / 備考: Notebook定義セルと同一

ID: S02 / 役割: 参照先 / 相対パス: notebooks/NB_CommonFunctions.ipynb / 備考: 定義のみ

ID: S03 / 役割: 事前検証 / 相対パス: notebooks/NB_CommonReference_Precheck.ipynb / 備考: Python/Spark試験

ID: S04 / 役割: ローカルテスト / 相対パス: tests/test_common_functions.py / 備考: 47テストメソッド

ID: S05 / 役割: 共通期待値 / 相対パス: tests/normalization_cases.json / 備考: 20ケース

### コピー・実行方法

種別: .sql / 方法: 対象T-SQLエディターでファイル単位に実行。 / 注意: Spark SQLには貼らない。失敗時は停止。 / 用途: ① / ③

種別: .ipynb / 方法: FabricのNotebook取込みで使用する。 / 注意: 名前、PySpark、既定Lakehouse、パラメータセルを確認。 / 用途: ② / ④

種別: .cells.txt / 方法: CELL区切りを目印にセル単位でコピーする。 / 注意: %runは独立セル、パラメータ指定を忘れない。 / 用途: リモートPCへのコピー

種別: .py / 方法: python/common_functions.pyを原本として保守する。 / 注意: 単体ではFabricの親子Notebook実行は開始しない。 / 用途: ローカル試験 / 共通定義

## 参照・改訂

### 参考資料・技術根拠

ID: R06 / 資料: Notebook参照実行 / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/author-execute-notebook / 適用事項: %runは同一ワークスペースの参照先Notebookを現在のコンテキストで実行。 確認日:2026-11-05

ID: R07 / 資料: NotebookUtils run / exit / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/notebookutils/notebookutils-notebook-run / 適用事項: パラメータセル、終了文字列、同一/継承Lakehouse、try/except外のexit。 確認日:2026-11-05

ID: R08 / 資料: PySpark regexp_replace / 参照先URL: https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.functions.regexp_replace.html / 適用事項: Spark組込みの正規表現置換を利用。利用するFabricランタイム上で別途検証。 確認日:2026-11-05

ID: R09 / 資料: Notebook取込 / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook / 適用事項: 標準.ipynb形式を取込み可能。実際のUI/権限を環境で確認。 確認日:2026-11-05

### 改訂履歴

版 / 日付: 1.0 / 前回生成分 / 変更内容: 一般的なサンプル設計・コード。 / 検証状態: 今回のテンプレ形式には未対応。 / 備考: 既存ZIPは参考扱い

版 / 日付: 2.0.0 / 2026-11-05 / 変更内容: 添付の概要/パラメータ/事前チェック/処理ロジック形式で4設計書を整備。文字列整形・試験・導入手順を追加。 / 検証状態: Python47件成功。実環境未実施。 / 備考: 本成果物
