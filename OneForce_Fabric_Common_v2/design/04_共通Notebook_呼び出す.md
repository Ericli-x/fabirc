# ④ 共通Notebook（呼び出す）

設計書ID: CMN-04 / 版: 2.0.0 / 作成日: 2026-11-05

NB_ProductItem_MainからNB_CommonTransformをnotebookutils.notebook.run()で呼出し、パラメータ受渡し・整形・件数確認・JSON結果検証・例外伝播を共通化する。既定はサンプル実行で書込みなし。明示指定時だけ実行ID別の新規Deltaフォルダーへ出力し、既存データは上書きしない。

## 一覧

### 設計管理

項目: 設計書ID / 内容: CMN-04 / 項目: 版 / 内容: 2.0.0

項目: 作成日 / 内容: 2026-11-05 / 項目: 対象 / 内容: OneForce / Microsoft Fabric

項目: 文書状態 / 内容: レビュー用初版（環境未検証） / 項目: 承認者 / 内容: 未設定

項目: 原資料 / 内容: [ItemName]_DetailedDesign_テンプレート.xlsx / 項目: 参照サンプル / 内容: Warehouse_ProcedureDesign.xlsx

項目: 対象機能 / 内容: ④ 共通Notebook（呼び出す） / 項目: 実装原本 / 内容: ソース対応シートを参照

項目: ローカル検証 / 内容: Python単体47件成功 / Notebook構文確認済み / 項目: 実環境検証 / 内容: SQL / Fabric / Spark は未実施

### 本書の前提・未確定事項

ID: U01 / 項目: 接続先・実体 / 内容: 前回のGoldLakehouse SQL分析エンドポイントを基準。Warehouseサンプル名はDataWarehouse。実際の配置先は導入時に確定。 / 状態: 実装前確認

ID: U02 / 項目: テーブル完全定義 / 内容: dbo.jp_dw_dsj_productitem_dim / productitemnamekanjiを引継ぐ。PK・全列・データ量・連携先型長は未提示。 / 状態: 本番適用前確認

ID: U03 / 項目: 承認・権限 / 内容: Preview利用可否、DDL/実行/読取/出力権限、担当者・承認者を確定。資格情報はソースに保持しない。 / 状態: 管理者確認

ID: U04 / 項目: 非機能 / 内容: 容量/件数/SLA/ログ保管/出力保存期間/監視通知の業務値は未確定。測定・運用設計後に確定。 / 状態: 運用前確認

ID: U05 / 項目: 業務範囲 / 内容: 税込計算・コード大文字化の汎用サンプルではなく、前回の文字列整形を実装対象とする。 / 状態: 本版の対象

ID: U06 / 項目: MERGE対象外 / 内容: Warehouseサンプル一覧の2026-10-27メモ（Fabric内MERGE不要）を踏まえ、MERGE/削除/既存表更新を実装しない。 / 状態: 参照は書式・記述粒度

## 詳細設計

### Notebook構成

Notebook: NB_ProductItem_Main / 役割: 親。設定/実行ID/期限の確認、子実行、戻り値検証。 / 呼出方法: 手動またはPipeline Notebook activity / 依存: NB_CommonFunctions / NB_CommonTransform

Notebook: NB_CommonTransform / 役割: 子。設定解析、読取、整形、集計、任意出力。 / 呼出方法: notebookutils.notebook.run / 依存: NB_CommonFunctions / 既定Lakehouse

Notebook: NB_CommonFunctions / 役割: 純Python/Spark関数定義。 / 呼出方法: 親子とも%runで参照 / 依存: 同一ワークスペース

Notebook: NB_CommonCall_Precheck / 役割: 親子呼出しの成功/異常伝播を試験。 / 呼出方法: 手動実行 / 依存: 上記3Notebook

### パラメータ

項目: param_json / 説明: 処理設定をJSON文字列で受け渡す。 / デフォルト / 値: {"mode":"sample","write_output":false} / チェック: 16KB以下 / 重複・未知キー拒否

項目: execution_id / 説明: 親から子へ引継ぐ実行識別子。 / デフォルト / 値: 親:空文字→UUID採番 / 子:manual_sample / チェック: 英数字開始、1～64文字

項目: timeout_seconds / 説明: 親の呼出し期限。 / デフォルト / 値: 600秒 / チェック: 1～43200の整数 / bool不可

項目: mode / 説明: sample:固定6行 / table:実表読取。 / デフォルト / 値: sample / チェック: sampleまたはtable

項目: source_table / 説明: Sparkで参照する登録テーブル名。 / デフォルト / 値: dbo.jp_dw_dsj_productitem_dim / チェック: 1～3階層 / 識別子検証

項目: source_column / 説明: 整形対象の元列。 / デフォルト / 値: productitemnamekanji / チェック: 存在 / StringType / 大小文字一致

項目: output_column / 説明: 追加する整形列。 / デフォルト / 値: productitemnamekanji_normalized / チェック: 既存列との大小文字無視衝突禁止

項目: allow_empty / 説明: 0件を成功とする許可。 / デフォルト / 値: false / チェック: JSON booleanのみ

項目: write_output / 説明: 新規Delta出力を許可。 / デフォルト / 値: false / チェック: true時のみ保存 / 上書き不可

### 事前チェック

ID: P01 / チェック内容: 全Notebook同一ワークスペース、同一/継承既定Lakehouse。 / NG時の動作: 環境エラーで停止。設定を確認。 / 備考: useRootDefaultLakehouseで強制回避しない

ID: P02 / チェック内容: 親子の第1コードセルをパラメータセルとしてマーク。 / NG時の動作: 取込後UIで確認。ID/戻り値検証でも不一致検出。 / 備考: metadata.tagsにparametersを設定済み

ID: P03 / チェック内容: mode・JSON・識別子・実行ID・期限の形式。 / NG時の動作: CMN002/003/009/010。子呼出前にも検査。 / 備考: 任意SQLを引数に取らない

ID: P04 / チェック内容: 元列の存在/型、出力列の非衝突、入力にU+0000なし。 / NG時の動作: CMN004/005/008で停止。 / 備考: 親子とも失敗を隠さない

ID: P05 / チェック内容: 出力時は書込権限、容量、出力フォルダー未使用。 / NG時の動作: Spark/Deltaエラーで停止。既存パスを再利用しない。 / 備考: 自動削除・自動上書きなし

### 処理ロジック

ステップ: 1 / 処理内容: 親パラメータ読込。空の実行IDはUUIDに置換。共通定義を参照。 / 判定 / 出力: 入力契約を検証。 / 対応関数: parse_config / validate_execution_id

ステップ: 2 / 処理内容: notebookutils.notebook.runで子を同期呼出し。 / 判定 / 出力: 子名固定・タイムアウト・JSON/実行IDを渡す。 / 対応関数: run_common_notebook

ステップ: 3 / 処理内容: 子のパラメータセルに値を受け、共通定義を参照。 / 判定 / 出力: 親子でライブラリ版統一。 / 対応関数: %run NB_CommonFunctions

ステップ: 4 / 処理内容: sampleは明示schemaの6行、tableはspark.tableで取得。 / 判定 / 出力: 元表へのDMLなし。 / 対応関数: run_transform_job

ステップ: 5 / 処理内容: 元列検査後、Spark組込み式で整形列を追加しpersist。 / 判定 / 出力: 全元列＋整形列。元列上書きなし。 / 対応関数: transform_dataframe

ステップ: 6 / 処理内容: 件数/変更件数/NULL件数/NUL件数を集計して評価を確定。 / 判定 / 出力: 0件不許可/NULは例外。countだけで済ませない。 / 対応関数: agg + first

ステップ: 7 / 処理内容: write_output=trueなら実行ID別パスへ新規Delta出力。 / 判定 / 出力: mode(errorifexists)。falseなら保存なし。 / 対応関数: Files/oneforce_common/normalized/<ID>

ステップ: 8 / 処理内容: finallyでunpersist。成功結果をJSON文字列化。 / 判定 / 出力: 失敗はログ後再raise、成功JSONへ変換しない。 / 対応関数: run_transform_job / log_event

ステップ: 9 / 処理内容: 子の独立セルでexit(result_json)。 / 判定 / 出力: try/exceptの外。 / 対応関数: notebookutils.notebook.exit

ステップ: 10 / 処理内容: 親が戻り値の版/ID/件数/設定/出力パスを検証。 / 判定 / 出力: 空/不正JSON/非SUCCESSは失敗。 / 対応関数: parse_run_result

ステップ: 11 / 処理内容: 書込あり時は親でDeltaを再読込してnormalized_dfに設定。 / 判定 / 出力: 子の変数/DataFrame共有は前提にしない。 / 対応関数: spark.read.format(delta)

ステップ: 12 / 処理内容: 親も成功JSONをPipelineへ返す。 / 判定 / 出力: 独立セルのexit。例外時は失敗終了。 / 対応関数: NB_ProductItem_Main

### エラー処理

コード: CMN001 / 条件: Python入力型不正 / 対応: strまたはNoneを指定する。暗黙のstr変換はしない。 / 備考: normalize_text

コード: CMN002 / 条件: テーブル/列識別子不正 / 対応: ASCII英数字・下線、1～3階層、単一名128文字以内を確認。 / 備考: validate_identifier / quote_table_name

コード: CMN003 / 条件: JSON/設定不正 / 対応: 16KB以内のJSONオブジェクト。未知キー・重複キー・NaN・文字列boolを拒否。 / 備考: parse_config

コード: CMN004 / 条件: 元列なし/型不正/列重複 / 対応: 存在・厳密な列名・StringTypeを確認。 / 備考: transform_dataframe

コード: CMN005 / 条件: 出力列名衝突 / 対応: 大文字小文字を無視して既存列との衝突を拒否。別名を指定。 / 備考: 元列を保護

コード: CMN006 / 条件: 0件不許可 / 対応: allow_empty=falseのまま0件なら停止。承認してtrueに変更した場合のみ成功。 / 備考: 子と親で検証

コード: CMN007 / 条件: 戻り値契約違反 / 対応: 空/不正JSON、status/版/実行ID/件数/出力先/要求との不一致を拒否。 / 備考: parse_run_result / run_common_notebook

コード: CMN008 / 条件: U+0000を検出 / 対応: 原文品質を修正。黙って削除しない。 / 備考: normalize_text / run_transform_job

コード: CMN009 / 条件: 実行ID不正 / 対応: 英数字開始、英数字/_/-、1～64文字。出力先パスの安全性も担保。 / 備考: validate_execution_id

コード: CMN010 / 条件: タイムアウト不正 / 対応: 1～43200秒の整数。bool/文字列は不可。 / 備考: run_common_notebook

コード: Fabric固有例外 / 条件: タイムアウト/未配置/権限/読書きエラー / 対応: 子から再raiseし、親でも再raiseする。成功JSONに変換しない。 / 備考: 自動再試行なし

### ログ・再実行・出力制御

項目: ログ / 仕様: UTC時刻、レベル、イベント、実行ID、件数/エラー型/コードをJSON出力。 / 留意点: 原文/変換値/秘密値を通常ログに出さない。Fabric例外証跡もアクセス管理。 / 初期設定: Notebook実行履歴

項目: 例外伝播 / 仕様: 子と親の例外は再raise。異常をstatus=ERRORの正常exitにしない。 / 留意点: PipelineはFailedとして扱える設計。実環境で確認。 / 初期設定: 自動リトライなし

項目: 再実行 / 仕様: 書込なしは元データ再読取。書込ありは同じIDの既存パスで失敗。 / 留意点: 失敗時残存物を調査。新ID再実行は重複成果物を生む可能性。 / 初期設定: Exactly-once保証なし

項目: 書込み単位 / 仕様: Delta出力1箇所のみ。業務元表の変更はない。 / 留意点: ログとDelta出力を跨いだ分散トランザクションはない。 / 初期設定: errorifexists

項目: 出力場所 / 仕様: 既定LakehouseのFiles/oneforce_common/normalized/<execution_id>。 / 留意点: Tablesの登録表ではなくFilesのDeltaフォルダー。SQL endpointには自動公開しない。 / 初期設定: write_output=false

項目: 保存期間 / 仕様: 出力/証跡の保存・削除方針は運用担当が確定。 / 留意点: 本版に自動削除は含まない。 / 初期設定: 未確定

項目: 大量データ / 仕様: 戻り値は集計メタデータのみ。collectは小さな検証ケースだけ。 / 留意点: 全件スキャンとpersistの容量を実環境で測定。 / 初期設定: SLA未確定

## 入出力定義

### 入出力仕様

項目: param_json / 方向 / 型: IN / str / 必須 / 内容: 設定JSON。未指定キーはDEFAULT_CONFIGで補う。 / 備考: JSON booleanを使用

項目: execution_id / 方向 / 型: IN / str / 必須（子） / 内容: 親が空ならUUIDを生成して子へ渡す。 / 備考: 1～64文字

項目: timeout_seconds / 方向 / 型: IN / int（親のみ） / 内容: 同期呼出しの期限。 / 備考: 既定600

項目: contract_version / 方向 / 型: OUT / str / 内容: 戻り値スキーマの版。 / 備考: 1.0

項目: status / 方向 / 型: OUT / str / 内容: 成功のみSUCCESS。失敗は例外終了。 / 備考: 非SUCCESS/空戻り値を拒否

項目: execution_id / mode / 方向 / 型: OUT / str / str / 内容: 要求と一致していることを親で確認。 / 備考: parameterセル設定漏れも検知

項目: row_count / changed_count / null_count / 方向 / 型: OUT / int / int / int / 内容: 非負整数。変更件数＋NULL件数≦総件数。 / 備考: sample期待値=6 / 4 / 1

項目: output_column / 方向 / 型: OUT / str / 内容: 追加列名。 / 備考: 要求と一致

項目: output_path / 方向 / 型: OUT / str|null / 内容: write_output=true時の固定ルート/実行ID。 / 備考: false時はnull

項目: write_output / library_version / 方向 / 型: OUT / bool / str / 内容: 出力実施フラグと実装版。 / 備考: falseまたはtrue / 2.0.0

項目: normalized_df / 方向 / 型: 親内部 / DataFrame|None / 内容: write_output=true時のみDeltaから再読込。 / 備考: run()でDataFrame自体を返さない

## テスト仕様

### 文字列整形の期待値

ケース / 観点: TXT01 NULL / 入力（JSON表記）: NULL / None / 期待結果（JSON表記）: NULL / None / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT02 空文字 / 入力（JSON表記）: "" / 期待結果（JSON表記）: "" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT03 半角空白のみ / 入力（JSON表記）: "   " / 期待結果（JSON表記）: "" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT04 全角空白のみ / 入力（JSON表記）: "<全角空白><全角空白>" / 期待結果（JSON表記）: "" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT05 NBSPのみ / 入力（JSON表記）: "<NBSP><NBSP>" / 期待結果（JSON表記）: "" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT06 混在した前後空白 / 入力（JSON表記）: " <全角空白><NBSP>製品A<全角空白> <NBSP>" / 期待結果（JSON表記）: "製品A" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT07 引用符 / 入力（JSON表記）: " A\"B " / 期待結果（JSON表記）: "A\"\"B" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT08 連続引用符 / 入力（JSON表記）: "\"\"" / 期待結果（JSON表記）: "\"\"\"\"" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT09 内部空白保持 / 入力（JSON表記）: " A B<NBSP>C<全角空白>D " / 期待結果（JSON表記）: "A B<NBSP>C<全角空白>D" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT10 タブ保持 / 入力（JSON表記）: "\tA\t" / 期待結果（JSON表記）: "\tA\t" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT11 改行保持 / 入力（JSON表記）: "\nA\n" / 期待結果（JSON表記）: "\nA\n" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT12 CRLF保持 / 入力（JSON表記）: " A\r\nB " / 期待結果（JSON表記）: "A\r\nB" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT13 最終改行の直前空白を保持 / 入力（JSON表記）: " A \n" / 期待結果（JSON表記）: "A \n" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT14 先頭タブ直後の空白を保持 / 入力（JSON表記）: "\t A " / 期待結果（JSON表記）: "\t A" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT15 シングルクォート保持 / 入力（JSON表記）: " O'Brien " / 期待結果（JSON表記）: "O'Brien" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT16 絵文字 / 入力（JSON表記）: " 😀製品 " / 期待結果（JSON表記）: "😀製品" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT17 除去対象外の細い空白 / 入力（JSON表記）: "<細い空白>A<細い空白>" / 期待結果（JSON表記）: "<細い空白>A<細い空白>" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT18 大小文字保持 / 入力（JSON表記）: " aBc " / 期待結果（JSON表記）: "aBc" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT19 全角二重引用符保持 / 入力（JSON表記）: " ＂A＂ " / 期待結果（JSON表記）: "＂A＂" / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT20 8000バイト超の引用符展開 / 入力（JSON表記）: ASCII二重引用符×5,000 / 期待結果（JSON表記）: ASCII二重引用符×10,000 / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

ケース / 観点: TXT21 非冪等性 / 入力（JSON表記）: 二重引用符1個を2回適用 / 期待結果（JSON表記）: 二重引用符4個 / 実施状態: 単一値Python成功 / 共通ジョブSpark未実施

### 機能固有の試験

ID: CALL01 / 観点 / 条件: サンプル成功（保存なし） / 期待結果: SUCCESS / row=6 / changed=4 / null=1 / output_path=null。 / 実施状態: Fabric未実施 / モック成功

ID: CALL02 / 観点 / 条件: 子へ不正modeを直接渡す / 期待結果: 子が例外終了し親が例外を受ける。 / 実施状態: NB_CommonCall_Precheck / 未実施

ID: CALL03 / 観点 / 条件: 戻り値が空/不正JSON/ID不一致 / 期待結果: 親がCMN007で停止。 / 実施状態: ローカルモック試験成功

ID: CALL04 / 観点 / 条件: タイムアウト / 期待結果: 例外を伝播し、自動再試行しない。 / 実施状態: ローカルモック成功 / Fabric未実施

ID: CALL05 / 観点 / 条件: 元列なし/出力衝突/型不一致 / 期待結果: CMN004/CMN005。データ書込なし。 / 実施状態: Spark手動試験 / 未実施

ID: CALL06 / 観点 / 条件: 0件 allow_empty=false/true / 期待結果: falseはCMN006、trueは0件SUCCESS。 / 実施状態: Spark手動試験 / 未実施

ID: CALL07 / 観点 / 条件: write_output=true / 期待結果: 新規Deltaへ保存し、親で再読込・件数一致。 / 実施状態: 環境手動試験 / 未実施

ID: CALL08 / 観点 / 条件: 同一実行IDで再保存 / 期待結果: 既存パスを上書きせず失敗。 / 実施状態: 環境手動試験 / 未実施

ID: CALL09 / 観点 / 条件: 入力にU+0000 / 期待結果: CMN008で停止。出力なし。 / 実施状態: Spark手動試験 / 未実施

ID: CALL10 / 観点 / 条件: パラメータセル/Lakehouse不整合 / 期待結果: 不一致が検出され成功扱いされない。 / 実施状態: 環境手動試験 / 未実施

## 導入・運用

### 実行手順

順序: 1 / 操作: ②の合格後、NB_CommonTransformとNB_ProductItem_Mainを取込む。 / 確認内容: 同じワークスペース。親子の第1コードセルをパラメータ指定。 / 注意: 同一/継承Lakehouse

順序: 2 / 操作: NB_CommonCall_Precheckを実行する。 / 確認内容: サンプルの6/4/1と子異常の伝播を確認。 / 注意: データ書込みなし

順序: 3 / 操作: 実表用config/productitem.jsonをparam_jsonへ設定して確認。 / 確認内容: 元表名/列/権限/0件可否を確認。schemaなしLakehouseは表名を変更。 / 注意: 初回はwrite_output=false

順序: 4 / 操作: 出力が必要な場合のみwrite_output=trueを承認して指定。 / 確認内容: 新しい実行IDと書込先/容量/保存期限を確認。 / 注意: 元表を更新しない

順序: 5 / 操作: Pipeline Notebook activityに親を指定し同名パラメータを渡す。 / 確認内容: 失敗時通知/再実行は運用設計で設定。二重リトライを避ける。 / 注意: 資格情報は含めない

順序: 6 / 操作: 旧版へ戻す際は共通定義と親子を同一版で戻す。 / 確認内容: 出力済データは自動削除しない。実行IDで調査。 / 注意: 旧版定義の保存が前提

### 受入・証跡

項目: ソース整合 / 合格基準: 設計書記載の関数名・ファイル名・既定値と実装が一致。 / 証跡: ソース対応 / manifest.sha256 / 状態: 生成時照合済み

項目: ローカル試験 / 合格基準: 47テストメソッドすべて成功。 / 証跡: evidence/local_unittest.txt / 状態: 成功

項目: 構文検査 / 合格基準: Python原本/試験、Notebookコードセルの構文が妥当。 / 証跡: evidence/static_validation.txt / 状態: 成功（%runはFabric専用）

項目: 環境試験 / 合格基準: 各テスト仕様のSQL/Fabric/Spark試験を実環境で実施。 / 証跡: 実行ID/接続先/日時/実行者/結果 / 状態: 未実施

項目: 本番受入 / 合格基準: 型・権限・物理DDL・Preview許可・件数/性能・運用を承認。 / 証跡: レビュー/環境測定記録 / 状態: 未実施

## ソース対応

### 設計とソースの対応

ID: S01 / 役割: 共通関数・共通ジョブ / 相対パス: python/common_functions.py / 備考: run_transform_job / run_common_notebook

ID: S02 / 役割: 親Notebook / 相対パス: notebooks/NB_ProductItem_Main.ipynb / 備考: 呼出し/戻り値/任意再読込

ID: S03 / 役割: 子Notebook / 相対パス: notebooks/NB_CommonTransform.ipynb / 備考: パラメータ/実行/exit

ID: S04 / 役割: 親子結合試験 / 相対パス: notebooks/NB_CommonCall_Precheck.ipynb / 備考: 成功/異常伝播

ID: S05 / 役割: サンプル/実表設定 / 相対パス: config/sample.json / config/productitem.json / 備考: 両方とも既定は保存なし

ID: S06 / 役割: モック単体試験 / 相対パス: tests/test_common_functions.py / 備考: JSON契約/例外/タイムアウト

### コピー・実行方法

種別: .sql / 方法: 対象T-SQLエディターでファイル単位に実行。 / 注意: Spark SQLには貼らない。失敗時は停止。 / 用途: ① / ③

種別: .ipynb / 方法: FabricのNotebook取込みで使用する。 / 注意: 名前、PySpark、既定Lakehouse、パラメータセルを確認。 / 用途: ② / ④

種別: .cells.txt / 方法: CELL区切りを目印にセル単位でコピーする。 / 注意: %runは独立セル、パラメータ指定を忘れない。 / 用途: リモートPCへのコピー

種別: .py / 方法: python/common_functions.pyを原本として保守する。 / 注意: 単体ではFabricの親子Notebook実行は開始しない。 / 用途: ローカル試験 / 共通定義

## 参照・改訂

### 参考資料・技術根拠

ID: R02 / 資料: Lakehouse SQL分析エンドポイント / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-sql-analytics-endpoint / 適用事項: Function/Viewを作成可能。varchar(max)は新メタデータ同期対応が条件。従来の8KB切捨てに注意。 確認日:2026-11-05

ID: R06 / 資料: Notebook参照実行 / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/author-execute-notebook / 適用事項: %runは同一ワークスペースの参照先Notebookを現在のコンテキストで実行。 確認日:2026-11-05

ID: R07 / 資料: NotebookUtils run / exit / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/notebookutils/notebookutils-notebook-run / 適用事項: パラメータセル、終了文字列、同一/継承Lakehouse、try/except外のexit。 確認日:2026-11-05

ID: R08 / 資料: PySpark regexp_replace / 参照先URL: https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.functions.regexp_replace.html / 適用事項: Spark組込みの正規表現置換を利用。利用するFabricランタイム上で別途検証。 確認日:2026-11-05

ID: R09 / 資料: Notebook取込 / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook / 適用事項: 標準.ipynb形式を取込み可能。実際のUI/権限を環境で確認。 確認日:2026-11-05

### 改訂履歴

版 / 日付: 1.0 / 前回生成分 / 変更内容: 一般的なサンプル設計・コード。 / 検証状態: 今回のテンプレ形式には未対応。 / 備考: 既存ZIPは参考扱い

版 / 日付: 2.0.0 / 2026-11-05 / 変更内容: 添付の概要/パラメータ/事前チェック/処理ロジック形式で4設計書を整備。文字列整形・試験・導入手順を追加。 / 検証状態: Python47件成功。実環境未実施。 / 備考: 本成果物
