---
title: Logger
layout: page
---

## ロガー

Gormはビルトインのロガーサポートをしていますが、デフォルトモードではエラーが起きた場合のみ出力します。

```go
// ロガーを有効にすると、詳細なログを表示します
db.LogMode(true)

// ロガーを無効化すると、エラーさえも出力しなくなります
db.LogMode(false)

// 1回だけ操作をデバッグしてこの操作中の詳細なログのみ出力します
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## ロガーのカスタマイズ

GORMのデフォルトロガーをカスタムする方法を参照してください <https://github.com/jinzhu/gorm/blob/master/logger.go>

例えば、[Revel](https://revel.github.io/)のロガーをGORMのバックエンドとして使う場合

```go
db.SetLogger(gorm.Logger{revel.TRACE})
```

`os.Stdout`をバックエンドに使う場合

```go
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```