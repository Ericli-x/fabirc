# OneForce / Microsoft Fabric 共通設計書・ソースコード 4件

版: **2.0.0** / 作成日: **2026-11-05**

## 1. 成果物と対象

添付の `[ItemName]_DetailedDesign_テンプレート.xlsx` と `Warehouse_ProcedureDesign.xlsx` の「概要・パラメータ・事前チェック・処理ロジック・設計上の注意点」の構成、青色見出し、4列の記述形式を参考に作成しました。各設計書は7シートです。テンプレートに記載されたBronze/SilverのETL処理やMERGE処理そのものを複製したものではありません。

| No. | 設計書 | 主な実装 |
|---|---|---|
| ① | design/01_SQL共通Function_作成呼出事前検証.xlsx | sql/01_precheck/ の環境検査・検証用Function・21ケース試験・実表呼出し |
| ② | design/02_別Notebook共通関数_参照呼出事前検証.xlsx | NB_CommonFunctions / NB_CommonReference_Precheck / Python共通関数 |
| ③ | design/03_共通Function_View.xlsx | dbo.fn_NormalizeText / dbo.vw_ProductItem_Normalized / 回帰試験 |
| ④ | design/04_共通Notebook_呼び出す.xlsx | NB_ProductItem_Main / NB_CommonTransform / NB_CommonCall_Precheck |

Excel各ブックのシート: `一覧`、`詳細設計`、`入出力定義`、`テスト仕様`、`導入・運用`、`ソース対応`、`参照・改訂`。
同内容のMarkdown設計書も `design/` にあります。`notebooks/*.cells.txt` はリモートPCへのセル単位コピー用です。

### 今回の共通処理

前回のOneForceの仕様として扱っていた、`dbo.jp_dw_dsj_productitem_dim.productitemnamekanji` の文字列整形を共通化しています。旧ZIPの汎用例（コード大文字化・税込計算・sample_orders）ではなく、`dbo.fn_NormalizeText`、`NB_CommonFunctions`、`NB_ProductItem_Main` の名称を使用します。

1. NULL/NoneはNULL/Noneのまま返す。空文字とは区別する。
2. 両端の半角スペースU+0020、NBSP U+00A0、全角スペースU+3000だけを除去する。
3. ASCIIの二重引用符 `"` を `""` にする。
4. 内部空白、タブ、CR、LF、大文字/小文字、全角引用符は保持する。

**この処理は非冪等です。** 引用符を含む整形済み文字列にもう一度適用すると、引用符がさらに二重化されます。必ず未加工の原文を入力し、同一値に一度だけ適用します。CSVレコード全体の生成やSQLインジェクション防止を目的とした関数ではありません。CSV writerの自動エスケープと二重適用しないでください。

U+0000はSQL/Python共通契約の対象外です。Python単一値・共通SparkジョブではCMN008で拒否します。SQL関数および低レベルColumn関数は入力品質保証を呼出側に求めます。

## 2. 実行環境と未確定事項

- SQL: **GoldLakehouseのSQL分析エンドポイント**を前回前提として記載しています。Warehouseで使用する場合は、対象元表が存在するWarehouseに接続してください。サンプルのWarehouse名は `DataWarehouse` ですが、実DB名の確定値として埋め込んでいません。SQLとSparkの表が自動的に同じものになるわけではありません。
- Notebook: 同一ワークスペースのFabric **PySpark**。同一の既定Lakehouse、または親の既定Lakehouseを継承する構成を使用します。接続先IDや資格情報はソースに含めていません。
- Python原本: Python 3.10以上。ローカル単体試験は標準ライブラリだけで動作します。Spark用関数は使用時にPySparkをimportします。
- SQLのデータベース照合順序はUTF-8を前提とし、関数内部の比較には `Latin1_General_100_BIN2_UTF8` を使用します。

**SQL実行前の確認:** Microsoft LearnではスカラーUDFはPreviewとして説明されています。また、SQL分析エンドポイントの `varchar(max)` 対応は新メタデータ同期の条件に依存します。関数内でMAX型を使用していても、元の列がSQL側で8KBに切り捨てられて取得された値は復元できません。管理者のPreview利用承認、メタデータ同期、元列の型、Spark側の元データ長を確認してください。

**実体未確認:** 元表の完全DDL、PK、全列、データ量、連携先の許容長、ワークスペース/既定LakehouseのID、権限、SLA、ログ/出力保持期間は未提示です。設計書の「未確定事項」で明示しています。③のViewは確認対象の原文列と整形列の2列だけを持つ最小構成です。Dataverse差分連携用のPKやその他の列は本番用途に合わせて追加設計してください。

`Warehouse_ProcedureDesign.xlsx` の一覧にある2026-10-27の「Fabric内でのマージは必要ない」のメモを踏まえ、既存業務テーブルへのMERGE、UPDATE、DELETE、TRUNCATEは本ソースに含めていません。

## 3. ディレクトリー

```text
OneForce_Fabric_Common_v2/
  README.md
  ALL_SOURCES.txt                    # SQL/Python/セルコピー用テキストをまとめたもの
  design/                           # 4 Excel設計書 + 同内容のMarkdown
  sql/01_precheck/                   # ① 5ファイル
  sql/03_common/                     # ③ 5ファイル
  python/common_functions.py        # 共通実装原本
  notebooks/                        # 5 ipynb + 5 cells.txt
  config/sample.json                # サンプル6行、保存なし
  config/productitem.json           # 実テーブル、保存なし
  tests/test_common_functions.py    # 純Python 47テストメソッド
  tests/normalization_cases.json    # 整形期待値20ケース
  evidence/                         # 実施したローカル検証の証跡
  manifest.sha256                   # 配布ファイルのハッシュ
```

## 4. ① SQL共通Functionの事前検証

対象のSQL分析エンドポイントまたはWarehouseのT-SQLクエリエディターで実行します。**NotebookのSpark SQL（%%sql）セルには貼り付けません。** ファイルにはGO区切りを含めていません。各ファイルを1バッチとして番号順に個別実行し、成功を確認してから次へ進みます。

```text
sql/01_precheck/00_environment.sql
sql/01_precheck/01_create_probe.sql
sql/01_precheck/02_scalar_tests.sql
sql/01_precheck/03_table_call_test.sql
```

`00_environment.sql` はDB名、バージョン、照合順序、権限、長文評価、対象列メタデータを出力します。権限チェックのNULLや元列情報0行は「問題なし」を意味しません。権限不足・メタデータ不可視・未同期を確認してください。

`01_create_probe.sql` は `dbo.fn_NormalizeText_Precheck` をCREATE OR ALTERします。他用途の同名Functionがないことを必ず確認してください。

`02_scalar_tests.sql` はTXT01～TXT21を検査します。ASCII二重引用符5,000個→10,000個の長文テストを含み、末尾空白比較の見逃しを防ぐため、SQLの値比較とDATALENGTHを組み合わせています。不一致はTHROWで停止します。

`03_table_call_test.sql` は、実テーブルに対して最大100行で関数評価を行います。結果は原文ではなく入力/出力バイト数だけを出します。0行の場合は51006で停止します。作成・定数SELECTが成功しても、非空の実テーブル呼出しが確認できるまで事前検証合格とはしません。

合格後、必要な場合のみ `09_cleanup_probe.sql` を手動実行して検証専用Functionを削除します。正式Functionや元表は削除しません。

## 5. ③ 正式Function・Viewの配置

①の合格後、変更前の定義、権限、依存するSQLを退避し、同じ対象DBで実行します。

```text
sql/03_common/00_prerequisites.sql
sql/03_common/10_fn_NormalizeText.sql
sql/03_common/20_vw_ProductItem_Normalized.sql
sql/03_common/30_verify_common.sql
sql/03_common/31_regression_tests.sql
```

公開するView:

```sql
SELECT productitemnamekanji_raw, productitemnamekanji
FROM dbo.vw_ProductItem_Normalized;
```

`productitemnamekanji_raw` は未加工値、`productitemnamekanji` は整形済み値です。Viewは元表の行をフィルター/結合/重複除去せず1対1で投影します。連携に必要なPK等は未提示のため含めていません。

件数比較時は、元表の更新を止めるなど安定した検証条件を確保してください。2回のSELECTの間に元表が更新されると件数が異なることがあります。性能試験はTOP100では代替できません。容量・実件数・SLAを確定して全量で測定してください。

## 6. ② Notebook共通関数の参照

1. `notebooks/NB_CommonFunctions.ipynb` を同一ワークスペースへ取り込みます。Notebook名を `NB_CommonFunctions` とし、取込時の自動改名がないか確認します。
2. `NB_CommonReference_Precheck.ipynb` を取り込み、PySparkと既定Lakehouse設定を確認します。
3. 検証Notebookを先頭から実行します。

関数を参照するセルは単独で配置します。

```python
%run NB_CommonFunctions
```

後続のPythonセルで利用できます。

```python
value = normalize_text('  製品"A"　')
# value == '製品""A""'

normalized_df = transform_dataframe(
    source_df, "productitemnamekanji", "productitemnamekanji_normalized"
)
```

参照先Notebookは定義だけを持ち、参照時にデータの読書き、Sparkセッション新規作成、exitを行いません。共通公開名を呼出元で再定義しないでください。`transform_dataframe` は遅延評価する低レベル関数です。U+0000の品質確認は利用側で行います。④の共通ジョブでは実行時に確認しています。

検証Notebookは純Python20ケース、Spark20ケース、入力型/識別子の異常系、非冪等性を確認します。実データのテーブルは不要です。

## 7. ④ 共通Notebookの呼出し

### 配置順とパラメータセル

②に加え、次のNotebookを同じワークスペースに配置します。

```text
NB_CommonTransform.ipynb
NB_ProductItem_Main.ipynb
NB_CommonCall_Precheck.ipynb
```

親子の**第1コードセル**はパラメータセルです。ipynbにはparametersタグを付けていますが、取込後にFabric UIで「パラメータとしてマーク」が有効か必ず確認してください。`%run`をパラメータセルに混在させません。

`NB_ProductItem_Main` の入力:

```python
param_json = '{"mode":"sample","write_output":false}'
execution_id = ""       # 空なら親でUUIDを採番
# 注:同一IDの出力先は上書きしない。
timeout_seconds = 600
```

まず `NB_CommonCall_Precheck` を実行し、正常系と、子Notebookに不正modeを渡した際の例外伝播を確認します。

### 実テーブルでの実行

`config/productitem.json` のJSON全体を `param_json` に設定してください。初期設定は保存なしです。

```json
{
  "mode": "table",
  "source_table": "dbo.jp_dw_dsj_productitem_dim",
  "source_column": "productitemnamekanji",
  "output_column": "productitemnamekanji_normalized",
  "allow_empty": false,
  "write_output": false
}
```

Schema対応Lakehouseでは `dbo.table`、SchemaなしLakehouseでは `table` のように環境に合わせます。登録先が異なる場合は対応する1～3階層のSparkテーブル識別子を指定します。本版は同一ワークスペース・既定Lakehouseを基本とし、4階層の越境参照は対象外です。

`source_column` はStringTypeを要求します。列名は厳密一致で確認し、既存列の上書きを防ぐため、`output_column` は大小文字を無視して既存列と衝突しない名前にします。数値等を自動的に文字列へ変換しません。

### 戻り値と任意出力

サンプル実行の期待結果:

```json
{
  "contract_version": "1.0",
  "status": "SUCCESS",
  "execution_id": "親から受け取ったID",
  "mode": "sample",
  "row_count": 6,
  "changed_count": 4,
  "null_count": 1,
  "output_column": "productitemnamekanji_normalized",
  "output_path": null,
  "write_output": false,
  "library_version": "2.0.0"
}
```

`run()` の終了値は文字列のため、子はJSON文字列を返し、親が内容を検証します。DataFrameや子のPython変数をそのまま親へ共有する設計ではありません。

`write_output=true` を明示した場合のみ、既定Lakehouseの次のパスにDeltaフォルダーを新規作成します。

```text
Files/oneforce_common/normalized/<execution_id>
```

出力は `mode("errorifexists")` で保存し、既存パスを上書きしません。親は成功後にそのDeltaを読み直し、`normalized_df` に保持します。既存業務テーブルへの投入処理は含みません。Files配下のDeltaなのでSQL分析エンドポイントのTablesへは自動公開されません。SQLから参照する登録表が必要な場合は別途設計します。

### 異常終了・再実行

子の異常はログ後に再raiseし、親にも例外を伝播します。失敗を成功扱いのexitに変換しません。`notebookutils.notebook.exit()` はtry/exceptの外にある独立セルから呼びます。親は空戻り値、JSON不正、版・ID・件数・出力先・要求設定の不一致を拒否します。

自動再試行はありません。書込ありの再実行で同じIDのパスが存在すれば失敗します。タイムアウトが起きた場合も、書込済みかどうかを実行IDと出力先で調査してください。新しいIDで再実行すると別成果物ができる可能性があります。Exactly-once処理や複数の資源を跨ぐトランザクションは保証しません。出力の保持/削除は運用承認後に別途実施します。

ログはUTC時刻、イベント、実行ID、件数、エラーコード/型を出力し、通常ログに原文や変換値を含めません。Fabricが保存する例外トレースや実行履歴にもアクセス制御を行ってください。

## 8. ローカル検証と実環境で残る確認

ローカル実行:

```bash
cd OneForce_Fabric_Common_v2
python -m unittest discover -s tests -v
```

作成時に実施した検証:

| 項目 | 結果 |
|---|---|
| 純Python単体テスト | **47件成功**。20種の文字列ケース、型、設定、識別子、戻り値契約、モックによる呼出し/例外/タイムアウト等 |
| Python構文 | 共通実装とテストソースの構文確認済み |
| Notebook | 5ファイルのJSON形式、Pythonコードセル9個の構文を確認。%runセル4個はFabric実行待ち |
| Excel | 4ブック・各7シート。要所の値と表示を確認、数式エラー検索0件 |
| SQL・Fabric・Spark実行 | **未実施**。この作業環境は利用者のFabricへ接続していないため、成功を主張していません |

`evidence/` にローカル試験結果と構文確認結果を格納しています。ローカル47件の成功は、SQL構文/スカラーUDF可用性/Notebook参照/PySpark/Delta書込み/権限の実環境検証を代替しません。設計書「テスト仕様」に環境試験の期待値と未実施状態を記載しています。

## 9. リモートPCへコピーする場合

`ALL_SOURCES.txt` はファイル名見出し付きのUTF-8テキストです。SQLは対応ファイルの単位で、Notebookは `.cells.txt` のCELL区切りに従ってコピーします。全体を1つのNotebookセルやPythonプロセスへまとめて実行しないでください。画面からのコピーでNBSP/全角空白が欠落しないよう、可能な限り配布したipynb/ファイルをそのまま取り込んでください。

## 10. 技術資料（2026-11-05確認）

- CREATE FUNCTION: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-sql-data-warehouse?view=fabric
- SQL分析エンドポイント: https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-sql-analytics-endpoint
- Fabricデータ型: https://learn.microsoft.com/en-us/fabric/data-warehouse/data-types
- TRIM: https://learn.microsoft.com/en-us/sql/t-sql/functions/trim-transact-sql?view=fabric
- REPLACE: https://learn.microsoft.com/en-us/sql/t-sql/functions/replace-transact-sql?view=fabric
- Notebook参照: https://learn.microsoft.com/en-us/fabric/data-engineering/author-execute-notebook
- NotebookUtils: https://learn.microsoft.com/en-us/fabric/data-engineering/notebookutils/notebookutils-notebook-run
- Notebook取込: https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook
- PySpark regexp_replace: https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.functions.regexp_replace.html
