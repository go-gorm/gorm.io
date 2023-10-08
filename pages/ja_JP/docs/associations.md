---
title: アソシエーション
layout: page
---

## アソシエーションの自動作成/更新

GORMはレコードの作成・更新時に[Upsert](create.html#upsert)を使用して自動的に関連データとその参照を保存します。

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Create(&user)
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH'), ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1), (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;

db.Save(&user)
```

すでに存在するアソシエーションレコードを更新したい場合は、 `FullSaveAssociations` を使用してください。

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## アソシエーションの自動作成/更新をスキップ

作成/更新時のアソシエーションレコードの自動保存をスキップするには、 `Select` または `Omit` を使用します。例：

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Select("Name").Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db.Omit("BillingAddress").Create(&user)
// ユーザ作成時に BillingAddress の作成をスキップする

db.Omit(clause.Associations).Create(&user)
// ユーザ作成時に全てのアソシエーションの保存をスキップする
```

{% note warn %}
**注意:** many2many（多対多）のアソシエーションの場合、中間テーブルのレコードを作成するより前に、アソシエーション先テーブルのレコードをupsertします。アソシエーション先へのupsertを省略したい場合は、以下のように記載します。

```go
db.Omit("Languages.*").Create(&user)
```

次のコードはアソシエーション先のレコードの作成と中間テーブルでの参照の作成の両方をスキップします。

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## アソシエーションフィールドの選択/省略

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Create user and his BillingAddress, ShippingAddress
// When creating the BillingAddress only use its address1, address2 fields and omit others
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Association Mode

Association Mode には、データの関連を処理するためによく使用されるヘルパーメソッドが含まれています。

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` は大元のモデルであるため、主キーを含んでいる必要があります
// `Languages` は関連フィールドの名前です
// 上記2つの条件が揃うと、 AssociationMode は正常に開始されます。条件が揃っていない場合はエラーが返却されます。
db.Model(&user).Association("Languages").Error
```

### 関連の取得

関連レコードを取得することができます。

```go
db.Model(&user).Association("Languages").Find(&languages)
```

条件を指定して関連を取得することも可能です。

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### 関連の追加

`many to many` や `has many` の場合には関連を追加し、 `has one` や `belongs to` の場合には現在の関連を置き換えます。

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### 関連を置き換える

現在の関連を新しいもので置き換えることができます。

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### 関連を削除する

引数で指定された値との関連がある場合、その値との関連を削除します。削除されるのは参照のみであり、参照先オブジェクトのレコードはDBから削除されません。

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### 関連を全て削除する

関連データとの参照を全て削除することができます。削除されるのは参照のみであり、参照先のレコードは削除されません。

```go
db.Model(&user).Association("Languages").Clear()
```

### 関連の数を取得する

現在の関連の数を取得することができます。

```go
db.Model(&user).Association("Languages").Count()

// 条件付きで件数を数える
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### 一括データ処理

Association Mode はデータの一括処理もサポートしています。例:

```go
// 全てのユーザの役割を全て取得する
db.Model(&users).Association("Role").Find(&roles)

// 全ユーザのチームからユーザAを削除する
db.Model(&users).Association("Team").Delete(&userA)

// 重複を取り除いた全ユーザのチームの件数を取得する
db.Model(&users).Association("Team").Count()

// 一括処理で `Append` や `Replace` を使用する場合は、それらの関数の引数とデータの数（以下でいう users の数）が一致している必要があります。
// 一致していない場合はエラーが返却されます。
var users = []User{user1, user2, user3}

// 例1: 3人のユーザABCを新たに追加するとした場合、以下のコードでは user1のチームにユーザA、user2のチームにユーザB、user3のチームにユーザABCを全員追加します
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})

// 例2: user1のチームをユーザAのみに、user2のチームをユーザBのみに、user3のチームをユーザABCのみにそれぞれリセットします
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">関連レコードを削除する</span>

デフォルトでは、`gorm.Association`の`Replace`/`Delete`/`Clear`は参照のみを削除します。つまり、古いアソシエーションの外部キーをNULLに設定します。

`Unscoped`を使用することで、オブジェクトを削除することができます。（`ManyToMany`の場合は挙動に変更はありません）

削除方法は、 `gorm.DB` の内部で判定します。

```go
// Soft delete
// UPDATE `languages` SET `deleted_at`= ...
db.Model(&user).Association("Languages").Unscoped().Clear()

// Delete permanently
// DELETE FROM `languages` WHERE ...
db.Unscoped().Model(&item).Association("Languages").Unscoped().Clear()
```

## <span id="delete_with_select">Selectを使って削除する</span>

レコード削除時に `Select` を使用することで、has one / has many / many2many 関係にある関連も同時に削除することができます。例:

```go
// ユーザ削除時に ユーザのアカウントも削除します
db.Select("Account").Delete(&user)

// ユーザ削除時に ユーザの注文とクレジットカードの関連レコードも削除します
db.Select("Orders", "CreditCards").Delete(&user)

// ユーザ削除時に ユーザの全ての has one / has many / many2many の関連レコードも削除します
db.Select(clause.Associations).Delete(&user)

// 複数ユーザ削除時に それぞれのユーザのアカウントも削除します
db.Select("Account").Delete(&users)
```

{% note warn %}
**注意:** レコード削除時の主キーが非ゼロ値の場合のみ、関連レコードの削除が可能となります。GORMは指定の関連を削除するための条件として主キーを使用するためです。

```go
// DOESN'T WORK
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// 名前が `jinzhu` である全てのユーザは削除されますが、ユーザのアカウントは削除されません

db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// 名前が `jinzhu` で id が `1` のユーザが削除され、そのユーザのアカウントも削除されます

db.Select("Account").Delete(&User{ID: 1})
// id が `1` のユーザが削除され、そのユーザのアカウントも削除されます
```
{% endnote %}

## <span id="tags">Association Tags</span>

| タグ               | 説明                                                |
| ---------------- | ------------------------------------------------- |
| foreignKey       | テーブル結合時に、これを指定したモデルの外部キーとして使用するフィールド名を指定できます      |
| references       | テーブル結合時に、参照先テーブルの外部キーとして使用するフィールド名を指定できます         |
| polymorphic      | モデル名などのポリモーフィック関連の種別を指定できます                       |
| polymorphicValue | ポリモーフィック関連ので使用される値を指定できます。デフォルトはテーブル名です。          |
| many2many        | 結合テーブル名を指摘できます                                    |
| joinForeignKey   | テーブル結合時に、これを指定したモデルの外部キーとして使用する結合テーブルのカラム名を指定できます |
| joinReferences   | テーブル結合時に、参照先テーブルの外部キーとして使用する結合テーブルのカラム名を指定できます    |
| constraint       | 参照制約を指定できます。例：`OnUpdate`, `OnDelete`              |
