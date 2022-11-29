---
title: GORM 가이드
layout: page
---

개발자 친화적인 것을 목표로 하는 Go언어 ORM 라이브러리

## 개요

* 완전한 기능을 가진 ORM
* Associations (Has One, Has Many, Belongs To, Many To Many, Polymorphism, Single-table inheritance)
* Hooks (Before/After Create/Save/Update/Delete/Find)
* `Preload`, `Joins`를 통한 데이터 가져오기
* Transactions, Nested Transactions, Save Point, RollbackTo to Saved Point
* Context, Prepared Statement 모드, DryRun 모드
* Batch Insert, FindInBatches, Find/Create with Map, CRUD with SQL Expr and Context Valuer
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints, Named Argument, SubQuery
* Composite Primary Key, Indexes, Constraints
* Auto Migrations
* Logger
* 확장 가능하고 유연한 플러그인 API: Database Resolver (다중 데이터베이스, 읽기 / 쓰기 분할) / Prometheus...
* 모든 기능들은 테스트와 함께 제공됩니다
* 개발자 친화적

## 설치

```sh
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## 빠르게 시작하기

```go
package main

import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
)

type Product struct {
  gorm.Model
  Code  string
  Price uint
}

func main() {
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic("Db 연결에 실패하였습니다.")
  }

  // 테이블 자동 생성
  db.AutoMigrate(&Product{})

  // 생성
  db.Create(&Product{Code: "D42", Price: 100})

  // 읽기
  var product Product
  db.First(&product, 1) // primary key기준으로 product 찾기
  db.First(&product, "code = ?", "D42") // code가 D42인 product 찾기

  // 수정 - product의 price를 200으로
  db.Model(&product).Update("Price", 200)
  // 수정 - 여러개의 필드를 수정하기
  db.Model(&product).Updates(Product{Price: 200, Code: "F42"})
  db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

  // 삭제 - product 삭제하기
  db.Delete(&product, 1)
}
```
