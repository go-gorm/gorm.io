---
title: Registro de Cambios
layout: page
---

## v2.0 - 2020.08

GORM 2.0 es una reescritura desde cero, introduce algún cambio incompatible-API y muchas mejoras

* Mejoras de rendimiento
* Modularidad
* Contexto, Inserción por Lote, Modo de Declaración Preparada, Modo DryRun, Join en Precarga, Buscar Mapa, Crear desde Mapa, soporta búsqueda en lotes
* Soporte a Transacción Anidadas/Punto de Guardar/Rollback Anidado
* Soporta argumentos nombrados, condiciones de grupo, Upsert, bloqueo, optimizador/índice/Comment Hints, mejoras en subconsulta
* Compatibilidad completa con relaciones autorreferenciadas, mejoras en la tabla, modo de asociación para los datos de los lotes
* Soporte de múltiples campos para el seguimiento de creación/actualización, lo que añade soporte para UNIX (mill/nano) segundos
* Soporte de permisos en campo: solo lectura, solo escritura, solo creación, solo actualización, ignorado
* Nuevo sistema de plugin: múltiples bases de datos, soporte para la división de lectura/escritura con plugin Resolver Base de Datos, integraciones a prometheus...
* Nueva API de Hooks: interfaz unificada con plugins
* Nuevo Migrador: permite crear claves foráneas de base de datos para las relaciones, soporte de restricciones/checker, soporte de índices mejorado
* Nuevo Logger: soporte contextual, extensión mejorada
* Estrategia unificada de nombres: nombre de la tabla, nombre del campo, nombre de la tabla, clave foránea, checker, reglas del índice
* Mejor soporte de tipo de datos personalizado (por ejemplo: JSON)

[Nota de lanzamiento GORM 2.0](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

Cambios importantes:

* `gorm.Open` devuelve `*gorm.DB` instead of `gorm.DB`
* Actualizar solo actualizará los campos modificados
* Soft Delete's solo comprobará `deleted_at IS NULL`
* Nueva lógica de ToDBName Común inicializador de [golint](https://github.com/golang/lint/blob/master/lint.go#L702) como `HTTP`, `URI` se convirtió en minúsculas, por lo que el nombre del db de `HTTP`es `http`, pero no `h_t_t_p`, pero para algunos otros iniciales no en la lista, como `SKU`, su nombre de db era `s_k_u`, este cambio lo arregló a `sku`
* Error `RecordNotFound` ha sido renombrado a `ErrRecordNotFound`
* `mssql` dialect ha sido renombrado a `github.com/jinzhu/gorm/dialects/mssql`
* `Hstore` se ha movido al paquete `github.com/jinzhu/gorm/dialects/postgres`
