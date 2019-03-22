---
title: Хуки
layout: страница
---
## Жизненный цикл объекта

Хуки - это функции, которые вызываются до или после создания/выборки/обновления/удаления.

Если вы определили специальные методы для модели, то они будут вызываться автоматически при создании, обновлении, запросе, удалении, а если какой-либо из вызовов возвращает ошибку, GORM остановит обработку и откатит текущую транзакцию.

## Хуки

### Создание объекта

Доступные хуки для создания

```go
// начало транзакции
BeforeSave
BeforeCreate
// сохранение перед связями
// обновление unix времени `CreatedAt`, `UpdatedAt`
// сохранение себя
// перезагрузка полей имеющие значения по умолчанию и их значения пусты
// сохранение после связей
AfterCreate
AfterSave
// фиксирование или откат транзакции
```

Примеры кода:

```go
func (u *User) BeforeSave() (err error) {
    if u.IsValid() {
        err = errors.New("can't save invalid data")
    }
    return
}

func (u *User) AfterCreate(scope *gorm.Scope) (err error) {
    if u.ID == 1 {
    scope.DB().Model(u).Update("role", "admin")
  }
    return
}
```

**ПРИМЕЧАНИЕ** Save/Delete в GORM выполняются в транзакции по умолчанию, поэтому изменения, внесенные в этой транзакции не будут видны пока она будет зафиксирована. Если вы хотите получить доступ к этим изменениям в хуках, вы можете принять текущую транзакцию в качестве аргумента в ваших хуках, например:

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
    tx.Model(u).Update("role", "admin")
    return
}
```

### Обновление объекта

Доступные хуки для обновления

```go
// начало транзакции
BeforeSave
BeforeUpdate
// сохранение перед связями
// обновление unixtime времени `UpdatedAt`
// сохранение себя
// сохранение после связей
AfterUpdate
AfterSave
// фиксация или откат транзакции
```

Примеры кода:

```go
func (u *User) BeforeUpdate() (err error) {
    if u.readonly() {
        err = errors.New("read only user")
    }
    return
}

// Обновление данных с этой же транзакции
func (u *User) AfterUpdate(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("verfied", true)
  }
    return
}
```

### Удаление объекта

Доступные хуки для удаления

```go
// начало транзакции
BeforeDelete
// удаление себя
AfterDelete
// фиксирование или откат транзакции
```

Примеры кода:

```go
// Updating data in same transaction
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
    return
}
```

### Querying an object

Available hooks for querying

```go
// load data from database
// Preloading (eager loading)
AfterFind
```

Code Example:

```go
func (u *User) AfterFind() (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
    return
}
```