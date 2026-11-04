-- OneForce Fabric 共通処理 / 簡易版 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一元表を持つWarehouse。
-- Spark SQLではなくT-SQLで、各ファイルを別バッチとして実行する。
-- UTF-8 DB照合順序・スカラーUDF・varchar(max)対応を前提とする。
-- U+0000は入力対象外。SQL分析エンドポイントの元列の長さ制約は環境に依存する。
-- 本ファイルの適用・実行は行っていない。

SET NOCOUNT ON;

SELECT DB_NAME() AS database_name,
       @@VERSION AS engine_version,
       CONVERT(varchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation')) AS database_collation;

DECLARE @collation varchar(128) =
    CONVERT(varchar(128), DATABASEPROPERTYEX(DB_NAME(), 'Collation'));
IF @collation IS NULL OR @collation NOT LIKE '%UTF8'
    THROW 51001, N'UTF-8のDB照合順序が必要です。接続先を確認してください。', 1;

-- 権限の有無を表示する。NULLの場合も接続先・権限を確認する。
SELECT HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE FUNCTION') AS can_create_function,
       HAS_PERMS_BY_NAME('dbo', 'SCHEMA', 'ALTER') AS can_alter_schema;

SELECT s.name AS schema_name, o.name AS object_name,
       c.name AS column_name, t.name AS data_type,
       c.max_length, c.collation_name
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
JOIN sys.columns AS c ON c.object_id = o.object_id
JOIN sys.types AS t ON t.user_type_id = c.user_type_id
WHERE s.name = 'dbo' AND o.name = 'jp_dw_dsj_productitem_dim'
  AND c.name = 'productitemnamekanji';
