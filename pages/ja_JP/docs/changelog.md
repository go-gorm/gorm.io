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

破壊的変更

* `gorm.Open` は `*gorm.DB` 型 ではなく`gorm.DB` 型を返すようになります
* 更新は変更されたフィールドのみ反映されるようになります
* 論理削除は `deleted_at IS NULL` のチェックのみ行われるようになります
* データベース名への変換ロジックの更新： [golint](https://github.com/golang/lint/blob/master/lint.go#L702) にある `HTTP` や `URI` のような省略形の名称は今までも問題なく lowercase に変換されていました。つまり `HTTP` は `h_t_t_p`ではなく `http` へ変換ができていました。しかし、リストにないその他の省略形の名称はその限りではなく、例えば `SKU` は `s_k_u` に変換されてしまっていました。今回の変更でそれが `sku` となるようになります。
* `RecordNotFound`エラー が `ErrRecordNotFound` に改名されました
* `mssql` 固有の設定は `github.com/jinzhu/gorm/dialects/mssql` に変更されました
* `Hstore` は `github.com/jinzhu/gorm/dialects/postgres` パッケージに移動されました
