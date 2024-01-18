---
title: トランザクション
layout: page
---

## デフォルトトランザクションを無効にする

GORMは、データの一貫性を確保するために書き込み操作(作成/更新/削除) をトランザクション内で実行します。必要でなければ、初期化時に無効にできます。無効にすると、30%以上のパフォーマンス向上を得られる可能性があります。

```go
// Globally disable
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})

// Continuous session mode
tx := db.Session(&Session{SkipDefaultTransaction: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

## トランザクション

トランザクション内で一連の操作を実行する場合、一般的なフローは以下のようになります。

```go
db.Transaction(func(tx *gorm.DB) error {
  // トランザクション内でのデータベース処理を行う(ここでは `db` ではなく `tx` を利用する)
  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
    // 何らかのエラーを返却するとロールバックされる
    return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
    return err
  }

  // nilが返却されるとトランザクション内の全処理がコミットされる
  return nil
})
```

### トランザクションのネスト

GORMはネストしたトランザクションをサポートしており、トランザクションのスコープ内で実行されるサブセットをロールバックすることができます。例:

```go
db.Transaction(func(tx *gorm.DB) error {
  tx.Create(&user1)

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx2.Create(&user2)
    return errors.New("rollback user2") // Rollback user2
  })

  tx.Transaction(func(tx3 *gorm.DB) error {
    tx3.Create(&user3)
    return nil
  })

  return nil
})

// Commit user1, user3
```

## トランザクションを手動で制御する

Gormでは、トランザクションを制御する関数 (commit / rollback) を直接呼び出すことができます。

```go
// begin a transaction
tx := db.Begin()

// do some database operations in the transaction (use 'tx' from this point, not 'db')
tx.Create(...)

// ...

// rollback the transaction in case of error
tx.Rollback()

// Or commit the transaction
tx.Commit()
```

### 具体例

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

## SavePoint, RollbackTo

GORMは `SavePoint`, `RollbackTo` メソッドを提供しています。これらのメソッドはそれぞれ、トランザクションの特定の地点を保存、保存された地点までロールバックが可能です。例:

```go
tx := db.Begin()
tx.Create(&user1)

tx.SavePoint("sp1")
tx.Create(&user2)
tx.RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```
