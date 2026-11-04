-- OneForce Fabric 共通処理 / 簡易版 / 2026-11-05
-- 対象: GoldLakehouse SQL分析エンドポイント、または同一元表を持つWarehouse。
-- Spark SQLではなくT-SQLで、各ファイルを別バッチとして実行する。
-- UTF-8 DB照合順序・スカラーUDF・varchar(max)対応を前提とする。
-- U+0000は入力対象外。SQL分析エンドポイントの元列の長さ制約は環境に依存する。
-- 本ファイルの適用・実行は行っていない。

-- 正式版。既存定義を退避し、変更可否を確認してから適用する。
-- 半角スペース・NBSP・全角スペースの前後除去と二重引用符の二重化。
-- NULL・内部空白・タブ・改行は保持する。原文に一度だけ適用する。
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
