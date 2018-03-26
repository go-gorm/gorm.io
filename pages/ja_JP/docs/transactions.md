---
title: トランザクション
layout: page
---
GORMはデフォルトで1つの`create`, `update`, `delete`操作をトランザクション内で行います。これはデータベース上のデータ整合性を確保するためです。

複数の `create`, `update`, `delete`を1つのアトミック操作として扱いたい場合には、` Transaction`が使えます。

## トランザクション

トランザクション内で複数操作をまとめて実行するための、一般的なフローは以下の通りです。

```go
// トランザクションを開始します
tx := db.Begin()

// データベース操作をトランザクション内で行います(ここからは'db'でなく'tx'を使います)
tx.Create(...)

// ...

// エラーが起きた場合はトランザクションをロールバックします
tx.Rollback()

// もしくはトランザクションをコミットします
tx.Commit()
```

## 具体例

```go
func CreateAnimals(db *gorm.DB) err {
  // 一度トランザクション内に入ったらtxをデータベースハンドラとして使いましょう
  tx := db.Begin()
  defer func() {
    if r := recover(); r != nil {
      tx.Rollback()
    }
  }()

  if tx.Error != nil {
    return err
  }

  if err := tx.Create(&Animal{Name: "キリン"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "ライオン"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  return tx.Commit().Error
}
```