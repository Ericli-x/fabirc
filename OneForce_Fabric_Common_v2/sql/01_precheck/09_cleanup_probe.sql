-- OneForce / Microsoft Fabric T-SQL / v2.0 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一ソースを持つWarehouse。
-- Spark SQLセルでは実行しない。接続先DBを確認し、このファイルを1バッチで実行。
-- UTF-8 DB照合順序、スカラーUDF、varchar(max)対応が前提。
-- 元データのU+0000は入力契約外。元データへのDMLは行わない。

-- 明示的な手動後片付け。検証証跡を保存し、この名前の所有者を確認してから実行する。
-- 正式Function/Viewや業務テーブルには作用しない。
DROP FUNCTION IF EXISTS dbo.fn_NormalizeText_Precheck;
