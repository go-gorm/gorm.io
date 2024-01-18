---
title: セキュリティ
layout: page
---

GORMは `database/sql` のプレースホルダ引数を使用してSQL文を構築しています。従って、SQLインジェクションを防げるよう引数は自動的にエスケープされます。

{% note warn %}
**注** Loggerから出力されたSQL は、実際に実行されたSQLのようにはエスケープされていません。SQLをコピーしてコンソールで実行するときは注意してください。
{% endnote %}

## クエリ条件

ユーザーの入力は引数としてのみ使用する必要があります。例:

```go
userInput := "jinzhu;drop table users;"

// safe, will be escaped
db.Where("name = ?", userInput).First(&user)

// SQL injection
db.Where(fmt.Sprintf("name = %v", userInput)).First(&user)
```

## インライン条件

```go
// エスケープされる
db.First(&user, "name = ?", userInput)

// SQLインジェクションが起こりうる
db.First(&user, fmt.Sprintf("name = %v", userInput))
```

ユーザ入力による主キーの数値を使用してオブジェクトを取得する場合は、変数の型を確認するべきです。

```go
userInputID := "1=1;drop table users;"
// safe, return error
id, err := strconv.Atoi(userInputID)
if err != nil {
    return err
}
db.First(&user, id)

// SQL injection
db.First(&user, userInputID)
// SELECT * FROM users WHERE 1=1;drop table users;
```

## SQLインジェクションが発生し得るメソッド

いくつかの機能をサポートするために、一部の入力はエスケープされません。それらのメソッドでユーザーの入力を使用する場合は注意が必要です。

```go
db.Select("name; drop table users;").First(&user)
db.Distinct("name; drop table users;").First(&user)

db.Model(&user).Pluck("name; drop table users;", &names)

db.Group("name; drop table users;").First(&user)

db.Group("name").Having("1 = 1;drop table users;").First(&user)

db.Raw("select name from users; drop table users;").First(&user)

db.Exec("select name from users; drop table users;")

db.Order("name; drop table users;").First(&user)
```

SQLインジェクションを避けるための一般的なルールは、ユーザーが送信したデータを信頼しないことです。 あらかじめ用意された入力データセットと比較することで、許可されたデータであるかを検証することができます。またユーザーの入力を使用する場合は、引数としてのみ使用するようにしてください。
