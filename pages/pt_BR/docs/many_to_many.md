---
title: Muitos Para Muitos
layout: page
---

## Muitos Para Muitos

Muitos para muitos adiciona uma tabela de união (tabela pivot) entre dois models.

Por exemplo, se sua aplicação inclui usuarios e linguagens, e um usuário pode falar várias linguagens, e uma linguagem pode ser falada por vários usuarios.

```go
// User possui e pertence a várias linguagens, `user_languages` é a tabela de união (tabela pivot)

type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}
```

Ao utilizar o `AutoMigrate` do GORM para criar a tabela para o model `User`, o GORM vair criar a tabela pivot automaticamente

## Referência

### Declare
```go
// User possui e pertence a muitas linguagens,  use `user_languages` como tabela de união (tabela pivot)

type User struct {
  gorm.Model
  Languages []*Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
  Users []*User `gorm:"many2many:user_languages;"`
}
```

### Retrieve
```go
// Retrieve user list with edger loading languages
func GetAllUsers(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("Languages").Find(&users).Error
    return users, err
}

// Retrieve language list with edger loading users
func GetAllLanguages(db *gorm.DB) ([]Language, error) {
    var languages []Language
    err := db.Model(&Language{}).Preload("Users").Find(&languages).Error
    return languages, err
}
```

## Sobrescrevendo Chaves Estrangeiras

Para uma relação `de muitos2many`, a tabela de união é dona da chave estrangeira que faz referência a dois models, por exemplo:

```go
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}

// Tabela de união(Pivot): user_languages
//   Chave estrangeira: user_id, referencia: users.id
//   Chave estrangeira: language_id, referencia: languages.id
```

Para sobrescrever, você pode usar a tag `foreignKey`, `references`, `joinForeignKey`, `joinReferences`, não é necessário usá-las juntas, você pode apenas usar uma delas para sobrescrever algumas chaves/referências estrangeiras

```go
type User struct {
    gorm.Model
    Profiles []Profile `gorm:"many2many:user_profiles;foreignKey:Refer;joinForeignKey:UserReferID;References:UserRefer;joinReferences:ProfileRefer"`
    Refer    uint      `gorm:"index:,unique"`
}

type Profile struct {
    gorm.Model
    Name      string
    UserRefer uint `gorm:"index:,unique"`
}

// Cria a tabela: user_profiles
//   Chave estrangeira: user_refer_id, referencia: users.refer
//   Chave estrangeira: profile_refer, referencia: profiles.user_refer
```

{% note warn %}
**NOTA:** Alguns bancos de dados só permitem criar chaves estrangeiras de banco de dados que referenciam um campo com índice exclusivo, então você precisa especificar a tag de `unique index` se você estiver criando chaves estrangeiras de banco de dados quando migrar
{% endnote %}

## Muitos para Muitos Auto-Referenciáveis

Auto-referenciando relacionamentos muitos para muitos

```go
type User struct {
  gorm.Model
    Friends []*User `gorm:"many2many:user_friends"`
}

// Which creates join table: user_friends
//   foreign key: user_id, reference: users.id
//   foreign key: friend_id, reference: users.id
```

## Eager Loading

GORM allows eager loading has many associations with `Preload`, refer [Preloading (Eager loading)](preload.html) for details

## CRUD with Many2Many

Please checkout [Association Mode](associations.html#Association-Mode) for working with many2many relations

## Customize JoinTable

`JoinTable` can be a full-featured model, like having `Soft Delete`，`Hooks` supports and more fields, you can setup it with `SetupJoinTable`, for example:

{% note warn %}
**NOTE:** Customized join table's foreign keys required to be composited primary keys or composited unique index
{% endnote %}

```go
type Person struct {
  ID        int
  Name      string
  Addresses []Address `gorm:"many2many:person_addresses;"`
}

type Address struct {
  ID   uint
  Name string
}

type PersonAddress struct {
  PersonID  int `gorm:"primaryKey"`
  AddressID int `gorm:"primaryKey"`
  CreatedAt time.Time
  DeletedAt gorm.DeletedAt
}

func (PersonAddress) BeforeCreate(db *gorm.DB) error {
  // ...
}

// Change model Person's field Addresses' join table to PersonAddress
// PersonAddress must defined all required foreign keys or it will raise error
err := db.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

```go
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_speaks;"`
}

type Language struct {
  Code string `gorm:"primarykey"`
  Name string
}

// CREATE TABLE `user_speaks` (`user_id` integer,`language_code` text,PRIMARY KEY (`user_id`,`language_code`),CONSTRAINT `fk_user_speaks_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,CONSTRAINT `fk_user_speaks_language` FOREIGN KEY (`language_code`) REFERENCES `languages`(`code`) ON DELETE SET NULL ON UPDATE CASCADE);
```

You are also allowed to delete selected many2many relations with `Select` when deleting, checkout [Delete with Select](associations.html#delete_with_select) for details

## Composite Foreign Keys

If you are using [Composite Primary Keys](composite_primary_key.html) for your models, GORM will enable composite foreign keys by default

You are allowed to override the default foreign keys, to specify multiple foreign keys, just separate those keys' name by commas, for example:

```go
type Tag struct {
  ID     uint   `gorm:"primaryKey"`
  Locale string `gorm:"primaryKey"`
  Value  string
}

type Blog struct {
  ID         uint   `gorm:"primaryKey"`
  Locale     string `gorm:"primaryKey"`
  Subject    string
  Body       string
  Tags       []Tag `gorm:"many2many:blog_tags;"`
  LocaleTags []Tag `gorm:"many2many:locale_blog_tags;ForeignKey:id,locale;References:id"`
  SharedTags []Tag `gorm:"many2many:shared_blog_tags;ForeignKey:id;References:id"`
}

// Join Table: blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id
//   foreign key: tag_locale, reference: tags.locale

// Join Table: locale_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id

// Join Table: shared_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: tag_id, reference: tags.id
```

Also check out [Composite Primary Keys](composite_primary_key.html)
