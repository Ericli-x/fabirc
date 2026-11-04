-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。
-- 検証専用名。既存オブジェクトが本パッケージ所有であることを事前確認する。
CREATE OR ALTER FUNCTION dbo.fn_NormalizeText_Precheck (@InputText varchar(max))
RETURNS varchar(max)
WITH SCHEMABINDING
AS
BEGIN
    RETURN REPLACE(
        TRIM(
            CAST((N' ' + NCHAR(160) + NCHAR(12288))
                 COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(6))
            FROM @InputText COLLATE Latin1_General_100_BIN2_UTF8
        ),
        '"', '""'
    );
END;
