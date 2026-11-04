-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。

SET NOCOUNT ON;
SELECT DB_NAME() AS database_name, @@VERSION AS engine_version,
       CONVERT(varchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation')) AS database_collation;
DECLARE @collation varchar(128) =
    CONVERT(varchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation'));
IF @collation IS NULL OR @collation NOT LIKE '%UTF8'
    THROW 51001, N'UTF-8のDB照合順序が必要です。接続先を確認してください。', 1;

-- scalar UDF本体とは別の環境検査。NULLは権限不足/メタデータ不可視の可能性がある。
SELECT HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE FUNCTION') AS can_create_function,
       HAS_PERMS_BY_NAME('dbo', 'SCHEMA', 'ALTER') AS can_alter_schema;

-- 型の式評価テストだけでendpointの元列切捨てがないことは証明できない。
DECLARE @wide varchar(max) = REPLICATE(CAST('X' AS varchar(max)), 10000);
IF DATALENGTH(@wide) <> 10000
    THROW 51002, N'長文の評価結果が想定と異なります。varchar(max)対応を確認してください。', 1;
SELECT DATALENGTH(@wide) AS long_string_bytes;

SELECT s.name AS schema_name, o.name AS object_name,
       c.name AS column_name, t.name AS data_type, c.max_length, c.collation_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS t ON t.user_type_id = c.user_type_id
WHERE s.name = 'dbo' AND o.name = 'jp_dw_dsj_productitem_dim'
  AND c.name = 'productitemnamekanji';
-- 元列が未同期/不可視でもここは0行となる。実テーブル検証03で判定する。
-- endpointの新メタデータ同期有効化、Preview利用許可は管理者が別途確認する。
