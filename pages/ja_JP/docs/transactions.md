---
title: トランザクション
layout: page
---

GORMはデフォルトで1つの`create`, `update`, `delete`操作をトランザクション内で行います。これはデータベース上のデータ整合性を確保するためです。

複数の `create`, `update`, `delete` を1つの不可分操作として扱いたい場合は、 `Transaction` が向いています。

## トランザクション

トランザクション内で複数操作をまとめて実行するための、一般的なフローは以下の通りです。

```go
func CreateAnimals(db *gorm.DB) error {
  return db.Transaction(func(tx *gorm.DB) error {
    // データベース操作をトランザクション内で行います（ここからは'db'ではなく'tx'を使います）
    if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
      // エラーを返した場合はロールバックされます
      return err
    }

    if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
      return err
    }

    // nilを返すとコミットされます
    return nil
  })
}
```

## 手動でのトランザクション

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
  // 一度トランザクション内に入ったら、txをデータベースハンドラとして使いましょう
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