---
title: マイグレーション
layout: page
---

## 自動マイグレーション

スキーマ定義のマイグレーションを自動で行い、スキーマを最新の状態に保ちます。

{% note warn %}
**注意:** AutoMigrate はテーブル、外部キー、制約、カラム、インデックスを作成します。 カラムのサイズまたは精度が変更されていた場合、および非 null 型からnull 許容型に変更されていた場合、既存のカラムの型が変更されます。 しかし、データを守るために、使われなくなったカラムの削除は**実行されません**。
{% endnote %}

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// テーブル作成時、末尾に語句を追加
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

{% note warn %}
**注意** AutoMigrate はデータベースの外部キー制約を自動的に作成します。初期化時にこの機能を無効にすることができます。例：
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

## Migrator Interface

GORMは、データベースに依存しないスキーママイグレーションを構築するために使用できる、各データベースのための統一されたAPIインタフェースを含むmigratorインタフェースを提供します。例：

SQLiteは`ALTER COLUMN`, `DROP COLUMN`をサポートしていませんが、GORMは変更しようとしているテーブルを新しいテーブルとして作成し、すべてのデータをコピーし、古いテーブルを削除し、新しいテーブルの名前を変更します。

MySQLは、いくつかのバージョンではカラム名変更、インデックス変更をサポートしていませんが、GORMは使用しているMySQLのバージョンに応じて異なるSQLを実行します。

```go
type Migrator interface {
  // 自動マイグレーション
  AutoMigrate(dst ...interface{}) error

  // データベース
  CurrentDatabase() string
  FullDataTypeOf(*schema.Field) clause.Expr

  // テーブル
  CreateTable(dst ...interface{}) error
  DropTable(dst ...interface{}) error
  HasTable(dst interface{}) bool
  RenameTable(oldName, newName interface{}) error
  GetTables() (tableList []string, err error)

  // カラム
  AddColumn(dst interface{}, field string) error
  DropColumn(dst interface{}, field string) error
  AlterColumn(dst interface{}, field string) error
  MigrateColumn(dst interface{}, field *schema.Field, columnType ColumnType) error
  HasColumn(dst interface{}, field string) bool
  RenameColumn(dst interface{}, oldName, field string) error
  ColumnTypes(dst interface{}) ([]ColumnType, error)

  // ビュー
  CreateView(name string, option ViewOption) error
  DropView(name string) error

  // 制約
  CreateConstraint(dst interface{}, name string) error
  DropConstraint(dst interface{}, name string) error
  HasConstraint(dst interface{}, name string) bool

  // インデックス
  CreateIndex(dst interface{}, name string) error
  DropIndex(dst interface{}, name string) error
  HasIndex(dst interface{}, name string) bool
  RenameIndex(dst interface{}, oldName, newName string) error
}
```

### CurrentDatabase

使用中のデータベース名を取得できます

```go
db.Migrator().CurrentDatabase()
```

### Tables

```go
// `User` テーブルを作成する
db.Migrator().CreateTable(&User{})

// `User` テーブル作成時のSQLに "ENGINE=InnoDB" を追加する
db.Set("gorm:table_options", "ENGINE=InnoDB").Migrator().CreateTable(&User{})

// `User` テーブルが存在するかどうかをチェックする
db.Migrator().HasTable(&User{})
db.Migrator().HasTable("users")

// テーブルが存在する場合はDropする（外部キー制約は無視するか削除する）
db.Migrator().DropTable(&User{})
db.Migrator().DropTable("users")

// テーブル名を新しいものに変更する
db.Migrator().RenameTable(&User{}, &UserInfo{})
db.Migrator().RenameTable("users", "user_infos")
```

### Columns

```go
type User struct {
  Name string
}

// テーブルに name カラムを追加
db.Migrator().AddColumn(&User{}, "Name")
// テーブルから name カラムを削除
db.Migrator().DropColumn(&User{}, "Name")
// テーブルの name カラムの名前を変更
db.Migrator().AlterColumn(&User{}, "Name")
// テーブルにカラムがあることを確認
db.Migrator().HasColumn(&User{}, "Name")

type User struct {
  Name    string
  NewName string
}

// name カラムの名前を new_name カラムに変更
db.Migrator().RenameColumn(&User{}, "Name", "NewName")
db.Migrator().RenameColumn(&User{}, "name", "new_name")

// ColumnTypes
db.Migrator().ColumnTypes(&User{}) ([]gorm.ColumnType, error)

type ColumnType interface {
    Name() string
    DatabaseTypeName() string                 // varchar
    ColumnType() (columnType string, ok bool) // varchar(64)
    PrimaryKey() (isPrimaryKey bool, ok bool)
    AutoIncrement() (isAutoIncrement bool, ok bool)
    Length() (length int64, ok bool)
    DecimalSize() (precision int64, scale int64, ok bool)
    Nullable() (nullable bool, ok bool)
    Unique() (unique bool, ok bool)
    ScanType() reflect.Type
    Comment() (value string, ok bool)
    DefaultValue() (value string, ok bool)
}
```

### ビュー

`ViewOption` でビューを作成します。 `ViewOption` では

- `Query` は[サブクエリ](https://gorm.io/docs/advanced_query.html#SubQuery)であり、必須です。
- `Replace` が true なら `CREATE OR REPLACE` を実行し、false なら `CREATE` を実行します。
- `CheckOption` が空でない場合、SQLに追加します。例: ` WITH LOCAL CHECK OPTION `

{% note warn %}
**注意** 現在、SQLiteでは `ViewOption` の `Replace` はサポートされていません。
{% endnote %}

```go
query := db.Model(&User{}).Where("age > ?", 20)

// ビューを作成
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query})
// CREATE VIEW `users_view` AS SELECT * FROM `users` WHERE age > 20

// ビューを作成または置換
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query, Replace: true})
// CREATE OR REPLACE VIEW `users_pets` AS SELECT * FROM `users` WHERE age > 20

// チェックオプション付きのビューを作成
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query, CheckOption: "WITH CHECK OPTION"})
// CREATE VIEW `users_pets` AS SELECT * FROM `users` WHERE age > 20 WITH CHECK OPTION

// ビューを削除
db.Migrator().DropView("users_pets")
// DROP VIEW IF EXISTS "users_pets"
```

### 制約

```go
type UserIndex struct {
  Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
}

// 制約を作成
db.Migrator().CreateConstraint(&User{}, "name_checker")

// 制約を削除
db.Migrator().DropConstraint(&User{}, "name_checker")

// 制約があることを確認
db.Migrator().HasConstraint(&User{}, "name_checker")
```

リレーション用の外部キーを作成

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}

// user と credit_cards のための外部キー制約を作成
db.Migrator().CreateConstraint(&User{}, "CreditCards")
db.Migrator().CreateConstraint(&User{}, "fk_users_credit_cards")
// ALTER TABLE `credit_cards` ADD CONSTRAINT `fk_users_credit_cards` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)

// user と credit_cards のための外部キー制約が存在しているかどうかを確認
db.Migrator().HasConstraint(&User{}, "CreditCards")
db.Migrator().HasConstraint(&User{}, "fk_users_credit_cards")

// user と credit_cards のための外部キー制約を削除
db.Migrator().DropConstraint(&User{}, "CreditCards")
db.Migrator().DropConstraint(&User{}, "fk_users_credit_cards")
```

### インデックス

```go
type User struct {
  gorm.Model
  Name string `gorm:"size:255;index:idx_name,unique"`
}

// Name フィールドにインデックスを作成
db.Migrator().CreateIndex(&User{}, "Name")
db.Migrator().CreateIndex(&User{}, "idx_name")

// Name フィールドのインデックスを削除
db.Migrator().DropIndex(&User{}, "Name")
db.Migrator().DropIndex(&User{}, "idx_name")

// インデックスがあることを確認
db.Migrator().HasIndex(&User{}, "Name")
db.Migrator().HasIndex(&User{}, "idx_name")

type User struct {
  gorm.Model
  Name  string `gorm:"size:255;index:idx_name,unique"`
  Name2 string `gorm:"size:255;index:idx_name_2,unique"`
}
// インデックスの名前を変更
db.Migrator().RenameIndex(&User{}, "Name", "Name2")
db.Migrator().RenameIndex(&User{}, "idx_name", "idx_name_2")
```

## 制約

GORMは、テーブルの自動マイグレーション時およびテーブル作成時に制約を作成することがあります。詳細は [制約](constraints.html) または [データベースインデックス](indexes.html) を参照してください。

## Atlas との統合

[Atlas](https://atlasgo.io) はオープンソースのデータベース移行ツールであり、GORMと公式に統合されています。

GORMの `AutoMigrate` 機能はたいていの場合機能しますが、ある時点で[バージョン管理型マイグレーション](https://atlasgo.io/concepts/declarative-vs-versioned#versioned-migrations)方式に切り替える必要があるでしょう。

ひとたび方式を切り替えたあとは、開発者は責任を持ってマイグレーションを計画し、アプリケーション実行時にはGORMの期待に沿うマイグレーションとなることを確認することになります。

Atlasは、公式の[GORMプロバイダ](https://github.com/ariga/atlas-provider-gorm)を使用して、開発者向けのデータベーススキーマのマイグレーションを自動的に計画することができます。  プロバイダの設定後、次のコマンドを実行するとマイグレーションを自動的に計画することができます。
```bash
atlas migrate diff --env gorm
```

GORMでAtlasを使用する方法については、[公式ドキュメント](https://atlasgo.io/guides/orms/gorm) を参照してください。



## その他のマイグレーションツール

その他のGoベースのマイグレーションツールとともにGORMを使用するために、GORMはあなたのお役に立てるよう汎用的なDBインターフェースを提供しています。

```go
// `*sql.DB` を返す
db.DB()
```

詳細については[汎用インターフェース](generic_interface.html)を参照してください。
