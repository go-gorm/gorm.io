---
title: Declarando Modelos
layout: page
---

## Declaring Models

Los modelos generalmente son estructuras normales de Golang, tipos de Go básicos o punteros de ellos. Las interfaces sql.Scanner y driver.Valuer también son compatibles.

Ejemplo de Modelo:

```go
type User struct {
  gorm.Model
  Name         string
  Age          sql.NullInt64
  Birthday     *time.Time
  Email        string  `gorm:"type:varchar(100);unique_index"`
  Role         string  `gorm:"size:255"` // set field size to 255
  MemberNumber *string `gorm:"unique;not null"` // set member number to unique and not null
  Num          int     `gorm:"AUTO_INCREMENT"` // set num to auto incrementable
  Address      string  `gorm:"index:addr"` // create index with name `addr` for address
  IgnoreMe     int     `gorm:"-"` // ignore this field
}
```

## Etiquetas de estructura

Tags are optional to use when declaring models. GORM supports the following tags:

### Etiquetas de Estructuración admitidas

| Etiqueta        | Descripción                                                            |
| --------------- | ---------------------------------------------------------------------- |
| Column          | Especifica el nombre de la columna                                     |
| Type            | Especifica el tipo de dato de la columna                               |
| Size            | Especifica el tamaño de la columna, el predeterminado es 255           |
| PRIMARY_KEY     | Especifica la columna como clave principal                             |
| UNIQUE          | Especifica la columna como única                                       |
| DEFAULT         | Especifica el valor predeterminado de la columna                       |
| PRECISION       | Especifica la precision de la columna                                  |
| NOT NULL        | Especifica la columna como no nula                                     |
| AUTO_INCREMENT  | Especifica la columna como auto incrementable o no                     |
| INDEX           | Crear índice con o sin nombre, el mismo nombre crea índices compuestos |
| UNIQUE_INDEX    | Al igual que `INDEX`, crea un índice único                             |
| EMBEDDED        | Establece la estructura como integrada                                 |
| EMBEDDED_PREFIX | Establece el prefijo del nombre de la estructura integrada             |
| -               | Ignore estos campos                                                    |

### Struct tags for Associations

Check out the Associations section for details

| Tag                                | Description                                    |
| ---------------------------------- | ---------------------------------------------- |
| MANY2MANY                          | Specifies join table name                      |
| FOREIGNKEY                         | Specifies foreign key                          |
| ASSOCIATION_FOREIGNKEY             | Specifies association foreign key              |
| POLYMORPHIC                        | Specifies polymorphic type                     |
| POLYMORPHIC_VALUE                  | Specifies polymorphic value                    |
| JOINTABLE_FOREIGNKEY               | Specifies foreign key of jointable             |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Specifies association foreign key of jointable |
| SAVE_ASSOCIATIONS                  | AutoSave associations or not                   |
| ASSOCIATION_AUTOUPDATE             | AutoUpdate associations or not                 |
| ASSOCIATION_AUTOCREATE             | AutoCreate associations or not                 |
| ASSOCIATION_SAVE_REFERENCE       | AutoSave associations reference or not         |
| PRELOAD                            | Auto Preload associations or not               |
