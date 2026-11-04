-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。

SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.fn_NormalizeText_Precheck', N'FN') IS NULL
    THROW 51003, N'検証用Functionが存在しないか、参照権限がありません。', 1;
IF OBJECT_ID(N'dbo.jp_dw_dsj_productitem_dim') IS NULL
    THROW 51004, N'対象テーブルが存在しないか、参照権限がありません。', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'dbo.jp_dw_dsj_productitem_dim')
                 AND name = N'productitemnamekanji')
    THROW 51005, N'対象列が存在しないか、メタデータが不可視です。', 1;
SELECT o.name, m.is_inlineable
FROM sys.objects AS o JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.object_id = OBJECT_ID(N'dbo.fn_NormalizeText_Precheck');

-- 定数SELECT成功だけでなく、実テーブルで分散実行できることを確認する。
-- 生データは証跡に出さず、長さだけを出力。0件の場合は事前検証未完了扱い。
SELECT TOP (100)
    DATALENGTH(productitemnamekanji) AS input_bytes,
    DATALENGTH(dbo.fn_NormalizeText_Precheck(productitemnamekanji)) AS output_bytes
FROM dbo.jp_dw_dsj_productitem_dim;
IF @@ROWCOUNT = 0
    THROW 51006, N'対象テーブルが0件です。非空の検証データで再実施してください。', 1;
-- これはスモーク試験。全量性能は実件数・容量・SLAを確定して測定する。
