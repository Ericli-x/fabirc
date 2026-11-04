-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。
-- 正式版。変更前の定義/権限を退避し、レビュー後に適用する。
-- 前後U+0020/U+00A0/U+3000を除去、ASCII二重引用符を二重化。
-- NULL/空文字/内部空白/タブ/CR/LF/大小文字を維持。非冪等のため原文に一度だけ適用。
CREATE OR ALTER FUNCTION dbo.fn_NormalizeText (@InputText varchar(max))
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
