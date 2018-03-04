---
title: Änderungen
layout: page
---
## v2.0

WIP

## v1.0 - 2016.04.27

Wichtige Änderungen

* `gorm.Open` return type `*gorm.DB` instead of `gorm.DB`

* Aktualisierung wird nur mit geänderten Felder aktualisieren

* Vorläufiges Löschen wird nur `Deleted_at IS NULL` überprüfen

* Neue ToDBName-Logik
    
    Wenn GORM konvertieren Struct, Feldnamen, um Db Name, nur gemeinsame Initialisms aus [Golint](https://github.com/golang/lint/blob/master/lint.go#L702) wie `HTTP` `URI` behandelt wurden, so `HTTP`db Name ist `http-`, aber nicht `H_t_t_p`.
    
    Aber für einige andere Initialisms nicht in der Liste, wie `SKU`Db sein Name war `S_k_u`, diese Änderung behoben.

* Fehler `RecordNotFound` wurde `ErrRecordNotFound` umbenannt

* `Mssql` Dialekt wurde in "github.com/jinzhu/gorm/dialects/mssql" umbenannt

* `Hstore` wurde verschoben, um Paket "github.com/jinzhu/gorm/dialects/postgres"