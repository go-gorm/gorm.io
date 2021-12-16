---
title: Belongs To
layout: страница
---

## Принадлежит к (Belongs To)

Отношение `belongs to` устанавливает связь один к одному с другой моделью, таким образом, чтобы каждый экземпляр объявленной модели "принадлежал" одному экземпляру другой модели.

Например, если в вашем приложении есть пользователи и компании, и каждый пользователь может быть только в одной компании, то следующие типы отражают это отношение. Обратите внимание, что у объекта `User` есть `CompanyID` и `Company`. По умолчанию, `CompanyID` неявно используется для создания отношения внешнего ключа между таблицами `User` и `Company`, и поэтому должен быть включен в структуру `User` для заполнения внутренней структуры `Company`.

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

Подробнее о заполнении внутренней структуры см. в [Нетерпеливая загрузка](belongs_to.html#Eager-Loading).

## Переопределение внешнего ключа

Чтобы определить отношение "belongs to", внешний ключ должен существовать, внешний ключ по умолчанию использует имя типа владельца плюс имя его первичного поля.

Для приведенного выше примера, чтобы определить модель `User`, которая принадлежит `Company`, внешний ключ должен быть `CompanyID` по соглашению

GORM предоставляет возможность настраивать внешний ключ, например:

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

Для отношения belongs to GORM обычно использует первичное поле владельца в качестве значения внешнего ключа, в приведенном выше примере это поле `Company` `ID`.

Когда вы назначаете пользователя в компанию, GORM сохраняет `ID` компании в поле `CompanyID` пользователя.

Вы можете изменить это с помощью тега `references`, например:

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

Пожалуйста, ознакомьтесь с [Режим связи](associations.html#Association-Mode) для работы с отношениями один к одному

## Нетерпеливая загрузка

GORM позволяет использовать нетерпеливую загрузку для отношений belongs to с `Preload` или `Joins`, подробнее смотрите [Предзагрузка (Нетерпеливая загрузка)](preload.html).

## Ограничения внешних ключей

Вы можете установить ограничения `OnUpdate`, `OnDelete` с помощью тега `constraint`. Они будут созданы при миграции с помощью GORM, например:

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
