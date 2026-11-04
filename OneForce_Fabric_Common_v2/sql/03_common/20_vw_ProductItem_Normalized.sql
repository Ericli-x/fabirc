-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。

-- 最小の共通View。元列と整形列の2列のみ。未提示のPKやDataverse差分列は創作しない。
-- 連携本体で利用するときは、PK/必要列を実テーブル定義に合わせて明示追加する。
CREATE OR ALTER VIEW dbo.vw_ProductItem_Normalized
AS
SELECT
    productitemnamekanji AS productitemnamekanji_raw,
    dbo.fn_NormalizeText(productitemnamekanji) AS productitemnamekanji
FROM dbo.jp_dw_dsj_productitem_dim;
