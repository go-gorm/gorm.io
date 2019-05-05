---
title: トランザクション
layout: page
---

GORMはデフォルトで1つの`create`, `update`, `delete`操作をトランザクション内で行います。これはデータベース上のデータ整合性を確保するためです。

If you want to treat multiple `create`, `update`, `delete` as one atomic operation, `Transaction` is made for that.

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
func CreateAnimals(db *gorm.DB) error {
  // Note the use of tx as the database handle once you are within a transaction
  tx := db.Begin()
  defer func() {
    if r := recover(); r != nil {
      tx.Rollback()
    }
  }()

  if err := tx.Error; err != nil {
    return err
  }

  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  return tx.Commit().Error
}
```