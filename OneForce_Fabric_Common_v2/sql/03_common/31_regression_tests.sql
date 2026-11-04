-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。

SET NOCOUNT ON;
DECLARE @actual varchar(max), @expected varchar(max);

-- TXT01: NULL
SET @actual = dbo.fn_NormalizeText(CAST(NULL AS varchar(max)));
SET @expected = CAST(NULL AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT01: 期待値不一致', 1;
SELECT 'TXT01' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT02: 空文字
SET @actual = dbo.fn_NormalizeText(CAST((N'') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT02: 期待値不一致', 1;
SELECT 'TXT02' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT03: 半角空白のみ
SET @actual = dbo.fn_NormalizeText(CAST((N'   ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT03: 期待値不一致', 1;
SELECT 'TXT03' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT04: 全角空白のみ
SET @actual = dbo.fn_NormalizeText(CAST((NCHAR(12288) + NCHAR(12288)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT04: 期待値不一致', 1;
SELECT 'TXT04' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT05: NBSPのみ
SET @actual = dbo.fn_NormalizeText(CAST((NCHAR(160) + NCHAR(160)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT05: 期待値不一致', 1;
SELECT 'TXT05' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT06: 混在した前後空白
SET @actual = dbo.fn_NormalizeText(CAST((N' ' + NCHAR(12288) + NCHAR(160) + N'製品A' + NCHAR(12288) + N' ' + NCHAR(160)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'製品A') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT06: 期待値不一致', 1;
SELECT 'TXT06' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT07: 引用符
SET @actual = dbo.fn_NormalizeText(CAST((N' A"B ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'A""B') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT07: 期待値不一致', 1;
SELECT 'TXT07' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT08: 連続引用符
SET @actual = dbo.fn_NormalizeText(CAST((N'""') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'""""') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT08: 期待値不一致', 1;
SELECT 'TXT08' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT09: 内部空白保持
SET @actual = dbo.fn_NormalizeText(CAST((N' A B' + NCHAR(160) + N'C' + NCHAR(12288) + N'D ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'A B' + NCHAR(160) + N'C' + NCHAR(12288) + N'D') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT09: 期待値不一致', 1;
SELECT 'TXT09' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT10: タブ保持
SET @actual = dbo.fn_NormalizeText(CAST((NCHAR(9) + N'A' + NCHAR(9)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((NCHAR(9) + N'A' + NCHAR(9)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT10: 期待値不一致', 1;
SELECT 'TXT10' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT11: 改行保持
SET @actual = dbo.fn_NormalizeText(CAST((NCHAR(10) + N'A' + NCHAR(10)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((NCHAR(10) + N'A' + NCHAR(10)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT11: 期待値不一致', 1;
SELECT 'TXT11' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT12: CRLF保持
SET @actual = dbo.fn_NormalizeText(CAST((N' A' + NCHAR(13) + NCHAR(10) + N'B ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'A' + NCHAR(13) + NCHAR(10) + N'B') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT12: 期待値不一致', 1;
SELECT 'TXT12' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT13: 最終改行の直前空白を保持
SET @actual = dbo.fn_NormalizeText(CAST((N' A ' + NCHAR(10)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'A ' + NCHAR(10)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT13: 期待値不一致', 1;
SELECT 'TXT13' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT14: 先頭タブ直後の空白を保持
SET @actual = dbo.fn_NormalizeText(CAST((NCHAR(9) + N' A ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((NCHAR(9) + N' A') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT14: 期待値不一致', 1;
SELECT 'TXT14' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT15: シングルクォート保持
SET @actual = dbo.fn_NormalizeText(CAST((N' O''Brien ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'O''Brien') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT15: 期待値不一致', 1;
SELECT 'TXT15' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT16: 絵文字
SET @actual = dbo.fn_NormalizeText(CAST((N' 😀製品 ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'😀製品') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT16: 期待値不一致', 1;
SELECT 'TXT16' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT17: 除去対象外の細い空白
SET @actual = dbo.fn_NormalizeText(CAST((NCHAR(8201) + N'A' + NCHAR(8201)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((NCHAR(8201) + N'A' + NCHAR(8201)) COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT17: 期待値不一致', 1;
SELECT 'TXT17' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT18: 大小文字保持
SET @actual = dbo.fn_NormalizeText(CAST((N' aBc ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'aBc') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT18: 期待値不一致', 1;
SELECT 'TXT18' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT19: 全角二重引用符保持
SET @actual = dbo.fn_NormalizeText(CAST((N' ＂A＂ ') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max)));
SET @expected = CAST((N'＂A＂') COLLATE Latin1_General_100_BIN2_UTF8 AS varchar(max));
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT19: 期待値不一致', 1;
SELECT 'TXT19' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT20: 8000バイト超の引用符展開
SET @actual = dbo.fn_NormalizeText(REPLICATE(CAST('"' AS varchar(max)), 5000));
SET @expected = REPLICATE(CAST('"' AS varchar(max)), 10000);
IF (@actual IS NULL AND @expected IS NOT NULL)
   OR (@actual IS NOT NULL AND @expected IS NULL)
   OR (@actual IS NOT NULL AND @expected IS NOT NULL AND (
       DATALENGTH(@actual) <> DATALENGTH(@expected)
       OR @actual COLLATE Latin1_General_100_BIN2_UTF8 <> @expected COLLATE Latin1_General_100_BIN2_UTF8))
    THROW 51010, N'TXT20: 期待値不一致', 1;
SELECT 'TXT20' AS case_id, 'PASS' AS status, DATALENGTH(@actual) AS result_bytes;

-- TXT21: 再適用により引用符が更に二重化される（非冪等）。
IF dbo.fn_NormalizeText(dbo.fn_NormalizeText('"')) <> '""""'
    THROW 51010, N'TXT21: 非冪等性の期待値不一致', 1;
SELECT 'TXT21' AS case_id, 'PASS' AS status;
SELECT 'ALL_PASS' AS summary, 21 AS test_count;
