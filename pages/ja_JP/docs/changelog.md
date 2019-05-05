---
title: 変更履歴
layout: page
---

## v2.0

WIP

## v1.0 - 2016.04.27

破壊的変更

* `gorm.Open`は`gorm.DB`ではなく`*gorm.DB` 型を返します

* 更新は変更したフィールドのみ反映されます

* 論理削除は`deleted_at IS NULL`のチェックのみ行います

* 新ロジック ToDBName
    
    GORMを型やフィールド名からdb名に変換する際、[golint](https://github.com/golang/lint/blob/master/lint.go#L702)の`HTTP`や`URI`に対する処理と同様の短縮形を採用します。 よって、`HTTP`のdb名は`h_t_t_p`ではなく`http`となります。
    
    しかし`SKU`のようなリストにないその他の省略形においては、db名は`s_k_u`となります。この変更はそれを修正します。

* `RecordNotFound`エラーは`ErrRecordNotFound`にリネームされました

* `mssql`の方言は"github.com/jinzhu/gorm/dialects/mssql"にリネームされました

* `Hstore`は"github.com/jinzhu/gorm/dialects/postgres"パッケージに移動しました