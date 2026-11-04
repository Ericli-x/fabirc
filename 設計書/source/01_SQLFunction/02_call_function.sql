-- OneForce Fabric 共通処理 / 簡易版 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一元表を持つWarehouse。
-- Spark SQLではなくT-SQLで、各ファイルを別バッチとして実行する。
-- UTF-8 DB照合順序・スカラーUDF・varchar(max)対応を前提とする。
-- U+0000は入力対象外。SQL分析エンドポイントの元列の長さ制約は環境に依存する。
-- 本ファイルの適用・実行は行っていない。

-- 呼出しソースのみ。期待値照合・自動合否判定は含まない。
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.fn_NormalizeText_Precheck', N'FN') IS NULL
    THROW 51003, N'検証用Functionが存在しないか、参照権限がありません。', 1;
IF OBJECT_ID(N'dbo.jp_dw_dsj_productitem_dim') IS NULL
    THROW 51004, N'対象テーブルが存在しないか、参照権限がありません。', 1;
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.jp_dw_dsj_productitem_dim')
      AND name = N'productitemnamekanji'
)
    THROW 51005, N'対象列が存在しないか、メタデータが不可視です。', 1;

DECLARE @InputText varchar(max) = '  A"B  ';
SELECT dbo.fn_NormalizeText_Precheck(@InputText) AS normalized_text;

SELECT o.name, m.is_inlineable
FROM sys.objects AS o
JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.object_id = OBJECT_ID(N'dbo.fn_NormalizeText_Precheck');

-- 実テーブルからの呼出し例。原文は表示せず、前後のバイト数だけを返す。
SELECT TOP (100)
    DATALENGTH(productitemnamekanji) AS input_bytes,
    DATALENGTH(dbo.fn_NormalizeText_Precheck(productitemnamekanji)) AS output_bytes
FROM dbo.jp_dw_dsj_productitem_dim;
