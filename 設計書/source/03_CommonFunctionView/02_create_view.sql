-- OneForce Fabric 共通処理 / 簡易版 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一元表を持つWarehouse。
-- Spark SQLではなくT-SQLで、各ファイルを別バッチとして実行する。
-- UTF-8 DB照合順序・スカラーUDF・varchar(max)対応を前提とする。
-- U+0000は入力対象外。SQL分析エンドポイントの元列の長さ制約は環境に依存する。
-- 本ファイルの適用・実行は行っていない。

-- 01_create_function.sql の適用後、別バッチとして実行する。
-- 元表名・列名は前回版の設定を引き継ぐ。利用前に実テーブル定義と照合する。
-- 本Viewは原文列・整形済み列の2列のみ。PK等の追加項目は実定義に合わせて追加する。
CREATE OR ALTER VIEW dbo.vw_ProductItem_Normalized
AS
SELECT
    productitemnamekanji AS productitemnamekanji_raw,
    dbo.fn_NormalizeText(productitemnamekanji) AS productitemnamekanji
FROM dbo.jp_dw_dsj_productitem_dim;
