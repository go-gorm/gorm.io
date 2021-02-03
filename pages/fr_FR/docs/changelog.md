---
title: Journal des changements de version
layout: page
---

## v2.0 - 2020.08

GORM 2.0 a été réécrit de zéro, introduisant des changements majeurs de l'API et de nombreuses améliorations

* Amélioration des performances
* Modularité
* Context, Batch Insert, Prepared Statement Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches supports
* Nested Transaction/SavePoint/RollbackTo SavePoint supports
* Named Argument, Group Conditions, Upsert, Locking, Optimizer/Index/Comment Hints supports, SubQuery improvements
* Full self-reference relationships supports, Join Table improvements, Association Mode for batch data
* Multiple fields support for tracking create/update time, which adds support for UNIX (milli/nano) seconds
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* New plugin system: multiple databases, read/write splitting support with plugin Database Resolver, prometheus integrations...
* New Hooks API: unified interface with plugins
* New Migrator: allows to create database foreign keys for relationships, constraints/checker support, enhanced index support
* New Logger: context support, improved extensibility
* Unified Naming strategy: table name, field name, join table name, foreign key, checker, index name rules
* Meilleure prise en charge de type de données personnalisé (par ex. JSON)

[Notes de version de GORM 2.0](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

Modifications importantes :

* `gorm.Open` retourne `*gorm.DB` au lieu de `gorm.DB`
* La mise à jour ne met à jour que les champs modifiés
* Le *Soft Delete* vérifie seulement `deleted_at IS NULL`
* New ToDBName logic Common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` was converted to lowercase, so `HTTP`'s db name is `http`, but not `h_t_t_p`, but for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it to `sku`
* L'erreur `RecordNotFound` a été renommé en `ErrRecordNotFound`
* Le dialecte `mssql` a été renommé en `github.com/jinzhu/gorm/dialects/mssql`
* `Hstore` a été déplacé vers le paquet `github.com/jinzhu/gorm/dialects/postgres`
