---
title: Change Log
layout: page
---
## v2.0

WIP

## v1.0 - 27.04.2016

Ultime modifiche

* `gorm.Open` restituisce il type `*gorm.DB` invece di `gorm.DB`

* L'aggiornamento aggiornerà solo i campi modificati

* L'eliminazione soft controllerà solo `deleted_at è vuoto`

* Nuova logica per ToDBName
    
    When GORM convert struct, field name to db name, only common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` were handled, so `HTTP`'s db name is `http`, but not `h_t_t_p`.
    
    But for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it.

* L'errore `RecordNotFound` è stato rinominato in `ErrRecordNotFound`

* Il dialetto `mssql` è stato rinominato in "github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` è stato spostato nel pacchetto "github.com/jinzhu/gorm/dialects/postgres"