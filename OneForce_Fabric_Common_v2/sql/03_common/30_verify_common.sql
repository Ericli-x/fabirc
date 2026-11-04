-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。

SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.fn_NormalizeText', N'FN') IS NULL
    THROW 51003, N'正式Functionが存在しません。', 1;
IF OBJECT_ID(N'dbo.vw_ProductItem_Normalized', N'V') IS NULL
    THROW 51007, N'共通Viewが存在しません。', 1;
SELECT o.name, o.type_desc, m.is_inlineable
FROM sys.objects AS o JOIN sys.sql_modules AS m ON m.object_id=o.object_id
WHERE o.object_id IN (OBJECT_ID(N'dbo.fn_NormalizeText'), OBJECT_ID(N'dbo.vw_ProductItem_Normalized'));

DECLARE @source_count bigint, @view_count bigint;
SELECT @source_count = COUNT_BIG(*) FROM dbo.jp_dw_dsj_productitem_dim;
SELECT @view_count = COUNT_BIG(*) FROM dbo.vw_ProductItem_Normalized;
IF @source_count <> @view_count
    THROW 51008, N'元表とViewの件数が一致しません。同時更新の有無も確認してください。', 1;
SELECT @source_count AS source_count, @view_count AS view_count;

-- 長さ・値の両方で比較し、SQLの末尾空白比較特性による見逃しを防止する。
-- 比較対象は未加工のraw列。既に整形済みの列を再整形しない。
IF EXISTS (
    SELECT 1 FROM dbo.vw_ProductItem_Normalized
    WHERE
      (productitemnamekanji_raw IS NULL AND productitemnamekanji IS NOT NULL)
      OR (productitemnamekanji_raw IS NOT NULL AND productitemnamekanji IS NULL)
      OR (productitemnamekanji_raw IS NOT NULL AND productitemnamekanji IS NOT NULL AND
          (DATALENGTH(productitemnamekanji) <> DATALENGTH(dbo.fn_NormalizeText(productitemnamekanji_raw))
           OR productitemnamekanji COLLATE Latin1_General_100_BIN2_UTF8 <>
              dbo.fn_NormalizeText(productitemnamekanji_raw) COLLATE Latin1_General_100_BIN2_UTF8))
)
    THROW 51009, N'Viewの整形結果が関数単体結果と一致しません。', 1;
SELECT TOP (100) DATALENGTH(productitemnamekanji_raw) AS raw_bytes,
                 DATALENGTH(productitemnamekanji) AS normalized_bytes
FROM dbo.vw_ProductItem_Normalized;
SELECT 'PASS' AS common_verification;
-- 件数照合はソース更新を止めた検証時間帯で実施する。
-- 受入にはさらに01/02_scalar_tests.sql内の関数名を正式名に替えて回帰試験を行う。
