# ③ 共通Function・View

設計書ID: CMN-03 / 版: 2.0.0 / 作成日: 2026-11-05

事前検証①で合格した文字列整形をdbo.fn_NormalizeTextとして正式配置し、dbo.vw_ProductItem_Normalizedから共通参照する。元表を更新せず、原文列と整形列を提供する最小Viewとする。未提示のPK・Dataverse連携列は創作しない。

## 一覧

### 設計管理

項目: 設計書ID / 内容: CMN-03 / 項目: 版 / 内容: 2.0.0

項目: 作成日 / 内容: 2026-11-05 / 項目: 対象 / 内容: OneForce / Microsoft Fabric

項目: 文書状態 / 内容: レビュー用初版（環境未検証） / 項目: 承認者 / 内容: 未設定

項目: 原資料 / 内容: [ItemName]_DetailedDesign_テンプレート.xlsx / 項目: 参照サンプル / 内容: Warehouse_ProcedureDesign.xlsx

項目: 対象機能 / 内容: ③ 共通Function・View / 項目: 実装原本 / 内容: ソース対応シートを参照

項目: ローカル検証 / 内容: Python単体47件成功 / Notebook構文確認済み / 項目: 実環境検証 / 内容: SQL / Fabric / Spark は未実施

### 本書の前提・未確定事項

ID: U01 / 項目: 接続先・実体 / 内容: 前回のGoldLakehouse SQL分析エンドポイントを基準。Warehouseサンプル名はDataWarehouse。実際の配置先は導入時に確定。 / 状態: 実装前確認

ID: U02 / 項目: テーブル完全定義 / 内容: dbo.jp_dw_dsj_productitem_dim / productitemnamekanjiを引継ぐ。PK・全列・データ量・連携先型長は未提示。 / 状態: 本番適用前確認

ID: U03 / 項目: 承認・権限 / 内容: Preview利用可否、DDL/実行/読取/出力権限、担当者・承認者を確定。資格情報はソースに保持しない。 / 状態: 管理者確認

ID: U04 / 項目: 非機能 / 内容: 容量/件数/SLA/ログ保管/出力保存期間/監視通知の業務値は未確定。測定・運用設計後に確定。 / 状態: 運用前確認

ID: U05 / 項目: 業務範囲 / 内容: 税込計算・コード大文字化の汎用サンプルではなく、前回の文字列整形を実装対象とする。 / 状態: 本版の対象

ID: U06 / 項目: MERGE対象外 / 内容: Warehouseサンプル一覧の2026-10-27メモ（Fabric内MERGE不要）を踏まえ、MERGE/削除/既存表更新を実装しない。 / 状態: 参照は書式・記述粒度

## 詳細設計

### オブジェクト一覧

種別: Function / オブジェクト名: dbo.fn_NormalizeText / 役割: 原文の空白除去・引用符二重化。 / 依存先: 組込みTRIM / REPLACE

種別: View / オブジェクト名: dbo.vw_ProductItem_Normalized / 役割: 原文と整形値の2列を共通公開。 / 依存先: 元表＋dbo.fn_NormalizeText

種別: 入力テーブル / オブジェクト名: dbo.jp_dw_dsj_productitem_dim / 役割: 前回仕様から引継ぐ製品原文データ。 / 依存先: productitemnamekanji

### パラメータ・実行条件

項目: 配置DB / 説明: ①で検証した接続先を利用する。 / デフォルト / 値: GoldLakehouse SQL分析エンドポイント / 備考: Warehouseは元表の配置を別途確認

項目: Function入力 / 説明: 原文を1引数で受ける。 / デフォルト / 値: @InputText varchar(max) / 備考: NULL可

項目: Function出力 / 説明: 整形後の文字列を返す。 / デフォルト / 値: varchar(max) / 備考: 元列取得時の切捨ては回復不可

項目: View引数 / 説明: Viewはパラメータなし。 / デフォルト / 値: なし / 備考: フィルターは呼出元SELECT

項目: 更新処理 / 説明: 元表へのINSERT/UPDATE/DELETE/MERGEは実施しない。 / デフォルト / 値: 読取のみ / 備考: SQLオブジェクトDDLは行う

### 事前チェック

ID: P01 / チェック内容: ①の環境/単体/実表検証が合格している。 / NG時の動作: 正式配置を行わない。 / ソース: ①の証跡

ID: P02 / チェック内容: 元表とproductitemnamekanji列が存在し、対応文字列型。 / NG時の動作: 51004/51005またはエンジンエラーで停止。 / ソース: 00_prerequisites.sql

ID: P03 / チェック内容: 既存Function/Viewの定義・利用先・権限を保存済み。 / NG時の動作: レビューまでDDLを適用しない。 / ソース: 手動退避

ID: P04 / チェック内容: CREATE FUNCTION/CREATE VIEW/スキーマ変更権限と利用権限。 / NG時の動作: 管理者へ確認。 / ソース: 権限チェック/DDL

ID: P05 / チェック内容: SQL分析エンドポイントの元列長とSpark元データ長が整合。 / NG時の動作: 旧同期の切捨てなら対象環境を整備する。 / ソース: R02/R03

### 処理ロジック

ステップ: 1 / 処理内容: FunctionをCREATE OR ALTERで配置する。 / 結果: Single RETURN / SCHEMABINDING。 / ソース: 10_fn_NormalizeText.sql

ステップ: 2 / 処理内容: 原文の3種類の両端空白をTRIMする。 / 結果: 内部空白やタブ/改行は保持。 / ソース: C02/C04

ステップ: 3 / 処理内容: ASCII二重引用符を二重化して返す。 / 結果: NULLはNULL。MAX型で評価。 / ソース: C03/C07

ステップ: 4 / 処理内容: ViewをCREATE OR ALTERで配置する。 / 結果: 元列をraw名、整形値を元業務名として公開。 / ソース: 20_vw_ProductItem_Normalized.sql

ステップ: 5 / 処理内容: 元表とViewの件数・NULL・整形値を検証する。 / 結果: SQL比較の末尾空白問題をDATALENGTHでも検査。 / ソース: 30_verify_common.sql

ステップ: 6 / 処理内容: 正式Function名で21ケースの回帰試験を行う。 / 結果: 全件PASS。 / ソース: 31_regression_tests.sql

### View出力項目

項目名: productitemnamekanji_raw / 型 / NULL可否: 元列の型を継承 / 元列に従う / 編集内容: dbo.jp_dw_dsj_productitem_dim.productitemnamekanjiをそのまま公開。 / 備考: 未加工値・再処理の入力に使用

項目名: productitemnamekanji / 型 / NULL可否: varchar(max) / NULL可 / 編集内容: dbo.fn_NormalizeText(productitemnamekanji)の結果。 / 備考: 再度同じ整形関数にかけない

項目名: 行粒度 / 型 / NULL可否: 元表1行 → View1行 / 編集内容: WHERE/JOIN/DISTINCT/GROUP BYなし。元表の重複も保持。 / 備考: PK・全項目は別途追加設計

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

番号: 51001 / 条件: DB照合順序がUTF-8でない/取得不可 / 処理内容: 00_environment.sqlで停止。接続先・照合順序を管理者確認。 / 備考: データ変更なし

番号: 51002 / 条件: 長文評価のバイト数不一致 / 処理内容: varchar(max)・環境制約を確認。長文を短縮して通さない。 / 備考: 環境検証不合格

番号: 51003 / 条件: Functionが存在しない/不可視 / 処理内容: 先行DDL・接続DB・権限を確認。 / 備考: 後続処理停止

番号: 51004 / 51005 / 条件: 元表・列の不存在/型不一致/不可視 / 処理内容: 対象DDL、同期状態、権限を確認。 / 備考: 後続処理停止

番号: 51006 / 条件: 実テーブルが0件 / 処理内容: 非空データで実テーブル呼出しを再検証。 / 備考: 作成だけでは合格にしない

番号: 51007～51009 / 条件: View不存在/件数差/結果差 / 処理内容: 定義・同時更新・権限を調査。 / 備考: ③で使用

番号: 51010 / 条件: 単体/回帰試験の期待値不一致 / 処理内容: エラーのTXTxxと入力契約・実装を照合。 / 備考: 不一致を無視して進めない

番号: Fabric固有エラー / 条件: 未対応構文、権限、inlineabilityなど / 処理内容: 元エラーを記録し、管理者または設計者へ連絡。 / 備考: 一般エラーへ隠蔽しない

### 設計上の注意点

項目: 最小投影 / 内容: PK未提示のため2列の共通参照View。Dataverse差分連携の完成形ではない。 / 受入条件: PK/連携項目を確定して追加レビュー。 / 備考: SELECT *は不使用

項目: 変更管理 / 内容: Function変更はView利用者全員へ影響する。原文仕様変更時は新版・回帰試験を検討。 / 受入条件: 変更前定義を保存し承認後に配置。 / 備考: DROP/CREATEによる権限喪失を避ける

項目: 件数照合 / 内容: 別SELECTの間に元表更新があると差が出る可能性。 / 受入条件: 検証時は元表更新を停止/固定。 / 備考: 差異を即不良と断定しない

項目: 性能 / 内容: スカラー関数のインライン化と全量件数・実行時間を実環境で確認。 / 受入条件: SLA/容量/実データ量は未確定。 / 備考: TOP100は性能保証ではない

項目: サンプルのMERGE / 内容: WarehouseのProcedureサンプルは書式を参照。MERGEロジックは本対象に取り込まない。 / 受入条件: 既存データを更新しない。 / 備考: 2026-10-27メモを反映

## 入出力定義

### 入出力仕様

項目: Function @InputText / 方向 / 型: IN / varchar(max) / NULL可 / 内容: 未加工の文字列。 / 備考: 共通規則C01～C08

項目: Function return / 方向 / 型: OUT / varchar(max) / NULL可 / 内容: TRIM＋引用符二重化。 / 備考: 正式名dbo.fn_NormalizeText

項目: View source / 方向 / 型: IN / 元表1列 / 内容: dbo.jp_dw_dsj_productitem_dim.productitemnamekanji / 備考: 同一DBに存在

項目: View raw / 方向 / 型: OUT / productitemnamekanji_raw / 内容: 元値を保持。 / 備考: 型は元列を継承

項目: View normalized / 方向 / 型: OUT / productitemnamekanji / 内容: 整形済み値。 / 備考: varchar(max)

## テスト仕様

### 文字列整形の期待値

ケース / 観点: TXT01 NULL / 入力（JSON表記）: NULL / None / 期待結果（JSON表記）: NULL / None / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT02 空文字 / 入力（JSON表記）: "" / 期待結果（JSON表記）: "" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT03 半角空白のみ / 入力（JSON表記）: "   " / 期待結果（JSON表記）: "" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT04 全角空白のみ / 入力（JSON表記）: "<全角空白><全角空白>" / 期待結果（JSON表記）: "" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT05 NBSPのみ / 入力（JSON表記）: "<NBSP><NBSP>" / 期待結果（JSON表記）: "" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT06 混在した前後空白 / 入力（JSON表記）: " <全角空白><NBSP>製品A<全角空白> <NBSP>" / 期待結果（JSON表記）: "製品A" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT07 引用符 / 入力（JSON表記）: " A\"B " / 期待結果（JSON表記）: "A\"\"B" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT08 連続引用符 / 入力（JSON表記）: "\"\"" / 期待結果（JSON表記）: "\"\"\"\"" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT09 内部空白保持 / 入力（JSON表記）: " A B<NBSP>C<全角空白>D " / 期待結果（JSON表記）: "A B<NBSP>C<全角空白>D" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT10 タブ保持 / 入力（JSON表記）: "\tA\t" / 期待結果（JSON表記）: "\tA\t" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT11 改行保持 / 入力（JSON表記）: "\nA\n" / 期待結果（JSON表記）: "\nA\n" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT12 CRLF保持 / 入力（JSON表記）: " A\r\nB " / 期待結果（JSON表記）: "A\r\nB" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT13 最終改行の直前空白を保持 / 入力（JSON表記）: " A \n" / 期待結果（JSON表記）: "A \n" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT14 先頭タブ直後の空白を保持 / 入力（JSON表記）: "\t A " / 期待結果（JSON表記）: "\t A" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT15 シングルクォート保持 / 入力（JSON表記）: " O'Brien " / 期待結果（JSON表記）: "O'Brien" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT16 絵文字 / 入力（JSON表記）: " 😀製品 " / 期待結果（JSON表記）: "😀製品" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT17 除去対象外の細い空白 / 入力（JSON表記）: "<細い空白>A<細い空白>" / 期待結果（JSON表記）: "<細い空白>A<細い空白>" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT18 大小文字保持 / 入力（JSON表記）: " aBc " / 期待結果（JSON表記）: "aBc" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT19 全角二重引用符保持 / 入力（JSON表記）: " ＂A＂ " / 期待結果（JSON表記）: "＂A＂" / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT20 8000バイト超の引用符展開 / 入力（JSON表記）: ASCII二重引用符×5,000 / 期待結果（JSON表記）: ASCII二重引用符×10,000 / 実施状態: SQL未実施（期待値を定義済み）

ケース / 観点: TXT21 非冪等性 / 入力（JSON表記）: 二重引用符1個を2回適用 / 期待結果（JSON表記）: 二重引用符4個 / 実施状態: SQL未実施（期待値を定義済み）

### 機能固有の試験

ID: VW01 / 観点 / 条件: 元表とView件数 / 期待結果: 更新を止めた状態で件数一致。 / 実施状態: SQL未実施

ID: VW02 / 観点 / 条件: 原文NULL・整形値NULL / 期待結果: NULL同士を同値と扱い、空文字とは区別。 / 実施状態: SQL未実施

ID: VW03 / 観点 / 条件: 整形値の照合 / 期待結果: rawを関数へ一度適用した結果と長さ/値一致。 / 実施状態: SQL未実施

ID: VW04 / 観点 / 条件: 依存関係・権限 / 期待結果: Function先行→View作成、利用者からSELECT成功。 / 実施状態: SQL未実施

ID: VW05 / 観点 / 条件: スキーマ変更影響 / 期待結果: 元列変更時にView/型長/利用者影響を確認。 / 実施状態: 変更時の運用試験

## 導入・運用

### 実行手順

順序: 1 / 操作: ①の合格証跡を確認。既存定義と権限・依存先を退避。 / 確認内容: 物理DDL/PK/利用先をレビューする。 / 注意: 新規作成でも衝突確認

順序: 2 / 操作: 00_prerequisites→10_fn→20_vwの順に各ファイル実行。 / 確認内容: 失敗時は次のファイルへ進まない。 / 注意: 接続先同一DB

順序: 3 / 操作: 30_verify_common→31_regression_testsを実行。 / 確認内容: 全量照合は安定した検証データで実施。 / 注意: 証跡を保存

順序: 4 / 操作: 利用者権限で利用SQLを確認し、リリース承認。 / 確認内容: 既存版へ戻す際は保存した定義を再適用。 / 注意: 新規削除は依存先確認後、View→Function

### 受入・証跡

項目: ソース整合 / 合格基準: 設計書記載の関数名・ファイル名・既定値と実装が一致。 / 証跡: ソース対応 / manifest.sha256 / 状態: 生成時照合済み

項目: ローカル試験 / 合格基準: 47テストメソッドすべて成功。 / 証跡: evidence/local_unittest.txt / 状態: 成功

項目: 構文検査 / 合格基準: Python原本/試験、Notebookコードセルの構文が妥当。 / 証跡: evidence/static_validation.txt / 状態: 成功（%runはFabric専用）

項目: 環境試験 / 合格基準: 各テスト仕様のSQL/Fabric/Spark試験を実環境で実施。 / 証跡: 実行ID/接続先/日時/実行者/結果 / 状態: 未実施

項目: 本番受入 / 合格基準: 型・権限・物理DDL・Preview許可・件数/性能・運用を承認。 / 証跡: レビュー/環境測定記録 / 状態: 未実施

## ソース対応

### 設計とソースの対応

ID: S01 / 役割: 前提チェック / 相対パス: sql/03_common/00_prerequisites.sql / 備考: 元表/型/権限

ID: S02 / 役割: 正式Function / 相対パス: sql/03_common/10_fn_NormalizeText.sql / 備考: dbo.fn_NormalizeText

ID: S03 / 役割: 共通View / 相対パス: sql/03_common/20_vw_ProductItem_Normalized.sql / 備考: 2列の最小投影

ID: S04 / 役割: 検証 / 相対パス: sql/03_common/30_verify_common.sql / 備考: 件数/結果/メタデータ

ID: S05 / 役割: 回帰試験 / 相対パス: sql/03_common/31_regression_tests.sql / 備考: 21ケース

### コピー・実行方法

種別: .sql / 方法: 対象T-SQLエディターでファイル単位に実行。 / 注意: Spark SQLには貼らない。失敗時は停止。 / 用途: ① / ③

種別: .ipynb / 方法: FabricのNotebook取込みで使用する。 / 注意: 名前、PySpark、既定Lakehouse、パラメータセルを確認。 / 用途: ② / ④

種別: .cells.txt / 方法: CELL区切りを目印にセル単位でコピーする。 / 注意: %runは独立セル、パラメータ指定を忘れない。 / 用途: リモートPCへのコピー

種別: .py / 方法: python/common_functions.pyを原本として保守する。 / 注意: 単体ではFabricの親子Notebook実行は開始しない。 / 用途: ローカル試験 / 共通定義

## 参照・改訂

### 参考資料・技術根拠

ID: R01 / 資料: CREATE FUNCTION / Fabric / 参照先URL: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-sql-data-warehouse?view=fabric / 適用事項: スカラーUDFはPreview。実テーブル参照時のinlineability、CREATE OR ALTER、権限。 確認日:2026-11-05

ID: R02 / 資料: Lakehouse SQL分析エンドポイント / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-sql-analytics-endpoint / 適用事項: Function/Viewを作成可能。varchar(max)は新メタデータ同期対応が条件。従来の8KB切捨てに注意。 確認日:2026-11-05

ID: R03 / 資料: Fabricデータ型 / 参照先URL: https://learn.microsoft.com/en-us/fabric/data-warehouse/data-types / 適用事項: UTF-8 varchar、LakehouseとSQLの型マッピング、永続型と変数の違い。 確認日:2026-11-05

ID: R04 / 資料: TRIM / 参照先URL: https://learn.microsoft.com/en-us/sql/t-sql/functions/trim-transact-sql?view=fabric / 適用事項: 指定した文字集合を両端から除去する。文字集合側は非LOB型を使用。 確認日:2026-11-05

ID: R05 / 資料: REPLACE / 参照先URL: https://learn.microsoft.com/en-us/sql/t-sql/functions/replace-transact-sql?view=fabric / 適用事項: 非MAX入力の8,000バイト切捨て、NULL伝播、照合順序、U+0000の制約。 確認日:2026-11-05

### 改訂履歴

版 / 日付: 1.0 / 前回生成分 / 変更内容: 一般的なサンプル設計・コード。 / 検証状態: 今回のテンプレ形式には未対応。 / 備考: 既存ZIPは参考扱い

版 / 日付: 2.0.0 / 2026-11-05 / 変更内容: 添付の概要/パラメータ/事前チェック/処理ロジック形式で4設計書を整備。文字列整形・試験・導入手順を追加。 / 検証状態: Python47件成功。実環境未実施。 / 備考: 本成果物
