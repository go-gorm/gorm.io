---
title: Хуки
layout: страница
---

## Жизненный цикл объекта

Хуки(Hooks) - это функции, вызываемые до или после создания/выборки/обновления/удаления.

Если вы определили специальные методы для модели, они будут вызываться автоматически при создании, обновлении, выборке, удалении, и если вызов специального метода возвращает ошибку, GORM остановит выполнение запроса и откатит текущую транзакцию.

Тип метода хука должен быть `func(*gorm.DB) error`

## Хуки

### Создать объект

Доступные хуки для создания

```go
// начало транзакции
BeforeSave
BeforeCreate
// сохранить перед ассоциациями
// добавить в БД
// сохранить после ассоциациями
AfterSave
AfterCreate
// фиксация или откат транзакции
```

Пример кода:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

  if !u.IsValid() {
    err = errors.New("can't save invalid data")
  }
  return
}

func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if u.ID == 1 {
    tx.Model(u).Update("role", "admin")
  }
  return
}
```

{% note warn %}
**ПРИМЕЧАНИЕ** По умолчанию в GORM операции сохранения/удаления выполняются в транзакции, так что изменения, внесенные в эту транзакцию, не будут видны до тех пор, пока она не будет сохранена транзакция, если вы вернете ошибку в хуках, транзакция откатиться
{% endnote %}

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if !u.IsValid() {
    return errors.New("откат, пользователь не найден")
  }
  return nil
}
```

### Обновление объекта

Доступные хуки для обновления

```go
// начинаем транзакцию
BeforeSave
BeforeUpdate
// сохранение перед ассоциациями
// обновление базы данных
// сохранение после ассоциаций
AfterSave
AfterUpdate
// фиксация или откат транзакции
```

Пример кода:

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  if u.readonly() {
    err = errors.New("read only user")
  }
  return
}

// Обновление данных в той же транзакции
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
// начинаем транзакцию
BeforeDelete
// удаляем из базы данных
AfterDelete
// фиксация или откат транзакции
```

Пример кода:

```go
// Обновление данных в той же транзакции
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
  return
}
```

### Запрос объекта

Доступные хуки для выборки

```go
// загрузка данных из базы данных
// Предзагрузка (нетерпеливая загрузка)
AfterFind
```

Пример кода:

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
  return
}
```

## Изменить текущую операцию

```go
func (u *User) BeforeCreate(tx *gorm.DB) error {
  // Modify current operation through tx.Statement, e.g:
  tx.Statement.Select("Name", "Age")
  tx.Statement.AddClause(clause.OnConflict{DoNothing: true})

  // tx is new session mode with the `NewDB` option
  // operations based on it will run inside same transaction but without any current conditions
  var role Role
  err := tx.First(&role, "name = ?", user.Role).Error
  // SELECT * FROM roles WHERE name = "admin"
  // ...
  return err
}
```
