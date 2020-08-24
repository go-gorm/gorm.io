---
title: Belongs To
layout: страница
---

## Принадлежит к (Belongs To)

Связь `belongs to` устанавливает связь один к одному с другой моделью, таким образом, чтобы каждый экземпляр объявленной модели "belongs to" связывался с другой.

Например, если приложение включает пользователей и компании, и каждому пользователю можно указать только одну компанию

```go
// `User` belongs to `Company`, `CompanyID` это внешний ключ
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company
}

type Company struct {
  ID   int
  Name string
}
```

## Переопределить внешний ключ

Чтобы определить belongs to связь, внешний ключ должен существовать, по умолчанию внешний ключ использует имя типа владельца плюс его основное имя поля.

Для приведенного выше примера, чтобы определить связь belongs to между моделями `User` и `Company`, внешним ключом должно быть `CompanyID` в соответствии с правилами

GORM предоставляет способ настройки внешнего ключа, например:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // использовать CompanyRefer как внешний ключ
}

type Company struct {
  ID   int
  Name string
}
```

## Переопределить ссылки

Для связи belongs to, GORM обычно использует первичное поле владельца в качестве значения внешнего ключа, для приведенного выше примера в таблице `Company` поле `ID`.

Когда вы назначаете пользователя компании, GORM сохранит `ID` компании в поле пользователя `CompanyID`.

Вы можете изменить его с помощью тега `references`, например:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // использовать Code как ссылку
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

## CRUD с Belongs To

Пожалуйста, посмотрите [Association Mode](associations.html#Association-Mode) для работы со связями

## Нетерпеливая загрузка

GORM разрешает загрузку связей belongs to с помощью `Preload` или `Joins`, смотрите [Предварительная загрузка (Нетерпеливая загрузка)](preload.html) для получения подробной информации

## Ограничения внешних ключей

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type Company struct {
  ID   int
  Name string
}
```
