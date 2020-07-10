---
title: Список изменений
layout: страница
---

## v2.0 - 2020.07

GORM 2.0 переписан с нуля на основе обратной связи, полученной в последние несколько лет, это представляет некоторые несовместимые изменения API и много улучшений

* Улучшение производительности
* Модульность
* Context, Batch Insert, Prepared Statment, DryRun Mode, Join Preload, Find To Map, FindInBatches
* SavePoint/RollbackTo/Вложенные транзакции
* Улучшение связей (при удалении/обновлении), изменение таблицы связей для Many2Many, режим связи для пакетных данных
* Конструктор SQL, Upsert, Блокировка, Оптимизатор/Индексирование/Комментарий поддержка подсказок
* Поддержка нескольких полей для времени авто-создания/обновления, также поддерживает UNIX (nano) секунды
* Поддержка прав доступа полей: только для чтения, только для записи, только для создания, только для обновления, игнорируется
* Полностью новые Migrator, Logger
* Стратегия именования (Unified table name, field name, join table name, foreign key, checker, index name rule)
* Улучшенная поддержка настраиваемых типов данных (например, JSON)
* Полностью новая система плагинов, Hooks API

## v1.0 - 2016.04

[GORM V1 Документация](https://v1.gorm.io)

Критические изменения

* `gorm.Open` return type `*gorm.DB` instead of `gorm.DB`

* Updating will only update changed fields

* Soft Delete's will only check `deleted_at IS NULL`

* New ToDBName logic

  When GORM convert struct, field name to db name, only common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` were handled, so `HTTP`'s db name is `http`, but not `h_t_t_p`.

  But for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it.

* Error `RecordNotFound` has been renamed to `ErrRecordNotFound`

* `mssql` dialect has been renamed to "github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` has been moved to package "github.com/jinzhu/gorm/dialects/postgres"
