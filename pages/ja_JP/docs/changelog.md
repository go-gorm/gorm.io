---
title: 更新履歴
layout: page
---

## v2.0 - 2020.08

GORM2.0はスクラッチからの書き直しをしているため、互換性のないAPIの変更と多くの改善が導入されています。

* パフォーマンスの改善
* モジュール性の向上
* Contextへの対応、Batch Insertの追加、Prepared State Modeの追加、DryRun Modeの追加、Join Preload機能の追加、Find結果のマップへの変換、マップでのCreate、FindInBatchesのサポート
* トランザクションのネスト、セーブポイント、セーブポイントへのロールバックのサポート
* 名前付き引数、集約条件、Upsert、ロック、Optimizer/Index/Comment Hintsのサポート、サブクエリの改善
* 自己参照の完全なサポート、テーブル結合の改善、大量データでのAssociation Modeの対応
* 複数フィールドでの作成/更新時間をトラッキング、またUNIX（ミリ/ナノ）秒でのトラッキングのサポート
* フィールド権限のサポート：読み取り専用、書き込み専用、作成専用、更新専用、無視するフィールド
* 新しいプラグインシステム：複数データベースへの対応、Database Resolverプラグインでの読み取り/書き込み分離の対応、prometheusとの連携
* 新しいHooksのAPI：プラグインと統合されたインターフェイス
* 新しいマイグレーション処理：リレーション用の外部キーの作成への対応、制約/checkへの対応、強化されたインデックスのサポート
* 新しいLogger：contextへの対応、拡張性の向上
* 統一された命名規約：テーブル名、フィールド名、結合テーブル名、外部キー、Check制約、インデックス名のルール
* 独自のデータ型へのさらなるサポート（例：JSON）

[GORM 2.0 Release Note](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

Breaking Changes:

* `gorm.Open` returns `*gorm.DB` instead of `gorm.DB`
* Updating will only update changed fields
* Soft Delete's will only check `deleted_at IS NULL`
* New ToDBName logic Common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` was converted to lowercase, so `HTTP`'s db name is `http`, but not `h_t_t_p`, but for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it to `sku`
* `RecordNotFound`エラー が `ErrRecordNotFound` に改名されました
* `mssql` dialect has been renamed to `github.com/jinzhu/gorm/dialects/mssql`
* `Hstore` has been moved to package `github.com/jinzhu/gorm/dialects/postgres`
