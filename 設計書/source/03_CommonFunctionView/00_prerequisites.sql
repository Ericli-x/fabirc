-- OneForce Fabric 共通処理 / 簡易版 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一元表を持つWarehouse。
-- Spark SQLではなくT-SQLで、各ファイルを別バッチとして実行する。
-- UTF-8 DB照合順序・スカラーUDF・varchar(max)対応を前提とする。
-- U+0000は入力対象外。SQL分析エンドポイントの元列の長さ制約は環境に依存する。
-- 本ファイルの適用・実行は行っていない。
SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.jp_dw_dsj_productitem_dim') IS NULL
    THROW 51004, N'対象テーブルが存在しないか、参照権限がありません。', 1;
IF NOT EXISTS (
    SELECT 1 FROM sys.columns AS c JOIN sys.types AS t ON t.user_type_id=c.user_type_id
    WHERE c.object_id=OBJECT_ID(N'dbo.jp_dw_dsj_productitem_dim')
      AND c.name=N'productitemnamekanji' AND t.name IN ('char','varchar')
)
    THROW 51005, N'対象列が存在しないか、対応する文字列型ではありません。', 1;
SELECT HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE VIEW') AS can_create_view,
       HAS_PERMS_BY_NAME('dbo.jp_dw_dsj_productitem_dim', 'OBJECT', 'SELECT') AS can_select_source;
