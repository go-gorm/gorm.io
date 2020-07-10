---
title: 更新履歴
layout: page
---

## v2.0 - 2020.07

GORM2.0は、過去数年間で受け取ったフィードバックにもとづいて１から書き直されています。互換性のないAPIの変更や多くの改善点は以下です。

* パフォーマンスの改善
* モジュール性の向上
* Context、バッチインサート、プリペアードステイトメント、ドライランモード、プリロードジョイン、マップ検索、FindInBatches
* SavePoint/RollbackTo/Nested Transaction Support
* アソシエーションの改善 (On Delete/Update), N: Nテーブルの結合の修正 バッチデータのためのアソシエーションモード
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints サポート
* Multiple fields support for auto-creating/updating time, which also support UNIX (nano) seconds
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* 完全に新しいマイグレーター、ロガー
* 名前付け戦略(統合テーブル名、フィールド名、結合テーブル名、外部キー、チェッカー、インデックス名ルール)
* より良いカスタマイズされたデータ型のサポート（例：JSON）
* 完全に新しいプラグインシステム、Hooks API

## v1.0 - 2016.04

[GORM V1 ドキュメント](https://v1.gorm.io)

重大な変更

* `gorm.Open` は `*gorm.DB`型 ではなく`gorm.DB`型を返します

* 更新は変更されたフィールドのみ反映されます

* 論理削除は `deleted_at IS NULL`のチェックのみ行います

* 新しい ToDBName ロジック

  GORMを型やフィールド名からdb名に変換する際、 [golint](https://github.com/golang/lint/blob/master/lint.go#L702) の`HTTP`や`URI` に対する処理と同様の短縮形を採用します。よって、`HTTP`のdb名は`h_t_t_p`ではなく `http`になります

  しかし `SKU`のようなリストにないその他の省略形においては、db名は, `s_k_u`となります。この変更はそれを修正します。

* `RecordNotFound`エラー が `ErrRecordNotFound` に改名されました

* `mssql` の方言は以下に改名されました。"github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` は以下のパッケージに移動しました。"github.com/jinzhu/gorm/dialects/postgres"
