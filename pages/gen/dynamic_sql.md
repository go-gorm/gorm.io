---
title: Gen Dynamic SQL
layout: page
---

### DIY method

#### Method interface

The DIY method needs to be defined through the interface. In the method, the specific SQL query logic is described in the way of comments. Simple WHERE queries can be wrapped in `where()`. When using complex queries, you need to write complete SQL. You can directly wrap them in `sql()` or write SQL directly. If there are some comments on the method, just add a blank line comment in the middle.

```go
type Method interface {
    // where("name=@name and age=@age")
    SimpleFindByNameAndAge(name string, age int) (gen.T, error)

    // FindUserToMap query by id and return id->instance
    // 
    // sql(select * from users where id=@id)
    FindUserToMap(id int) (gen.M, error)
    
    // InsertValue insert into users (name,age) values (@name,@age)
    InsertValue(age int, name string) error
}
```
Method input parameters and return values support basic types (`int`, `string`, `bool`...), struct and placeholders (`gen.T`/`gen.M`/`gen.RowsAffected`), and types support pointers and arrays. The return value is at most a value and an error.

Usage(complete case on [Quick start](#quick-start)):
```go
// implement model.Method on table "user" and "comany"
g.ApplyInterface(func(method model.Method) {}, model.User{}, g.GenerateModel("company"))
```

##### Syntax of template

###### placeholder

- `gen.T` represents specified `struct` or `table`
- `gen.M` represents `map[string]interface`
- `gen.RowsAffected` represents SQL executed `rowsAffected` (type:int64)
- `@@table`  represents table's name (if method's parameter doesn't contains variable `table`, GEN will generate `table` from model struct)
- `@@<columnName>` represents column's name or table's name
- `@<name>` represents normal query variable

###### template

Logical operations must be wrapped in `{{}}`,and end must used `{{end}}`, All templates support nesting

- `if`/`else if`/`else` the condition accept a bool parameter or operation expression which conforms to Golang syntax.
- `where` The `where` clause will be inserted only if the child elements return something. The key word  `and` or `or`  in front of clause will be removed. And `and` will be added automatically when there is no junction keyword between query condition clause.
- `Set` The  `set` clause will be inserted only if the child elements return something. The `,` in front of columns array will be removed.And `,` will be added automatically when there is no junction keyword between query coulmns.
- `for` The  `for` clause traverses an array according to golang syntax and inserts its contents into SQL,supports array of struct.
- `...` Coming soon

###### `If` clause

```
{{if cond1}}
    // do something here
{{else if cond2}}
    // do something here
{{else}}
    // do something here
{{end}}
```

Use case in raw SQL:

```go
// select * from users where 
//  {{if name !=""}} 
//      name=@name
//  {{end}}
methond(name string) (gen.T,error)
```

Use case in raw SQL template:

```
select * from @@table where
{{if age>60}}
    status="older"
{{else if age>30}}
    status="middle-ager"
{{else if age>18}}
    status="younger"
{{else}}
    {{if sex=="male"}}
        status="boys"
    {{else}}
        status="girls"
    {{end}}
{{end}}
```

###### `Where` clause

```
{{where}}
    // do something here
{{end}}
```

Use case in raw SQL

```go
// select * from 
//  {{where}}
//      id=@id
//  {{end}}
methond(id int) error
```

Use case in raw SQL template

```
select * from @@table 
{{where}}
    {{if cond}} id=@id, {{end}}
    {{if name != ""}} @@key=@value, {{end}}
{{end}}
```

###### `Set` clause

```
{{set}}
    // sepecify update expression here
{{end}}
```

Use case in raw SQL

```go
// update users 
//  {{set}}
//      name=@name
//  {{end}}
// where id=@id
methond(name string,id int) error
```

Use case in raw SQL template

```
update @@table 
{{set}}
    {{if name!=""}} name=@name {{end}}
    {{if age>0}} age=@age {{end}}
{{end}}
where id=@id
```
###### `For` clause

```
{{for _,name:=range names}}
    // do something here
{{end}}
```

Use case in raw SQL:

```go
// select * from users where id>0 
//  {{for _,name:=range names}} 
//      and name=@name
//  {{end}}
methond(names []string) (gen.T,error) 
```

Use case in raw SQL template:

```
select * from @@table where
  {{for index,name:=range names}}
     {{if index >0}} 
        OR
     {{end}}
     name=@name
  {{end}}
```

##### Method interface example

```go
type Method interface {
    // Where("name=@name and age=@age")
    SimpleFindByNameAndAge(name string, age int) (gen.T, error)
    
    // select * from users where id=@id
    FindUserToMap(id int) (gen.M, error)
    
    // sql(insert into @@table (name,age) values (@name,@age) )
    InsertValue(age int, name string) error
    
    // select name from @@table where id=@id
    FindNameByID(id int) string
    
    // select * from @@table
    //  {{where}}
    //      id>0
    //      {{if cond}}id=@id {{end}}
    //      {{if key!="" && value != ""}} or @@key=@value{{end}}
    //  {{end}}
    FindByIDOrCustom(cond bool, id int, key, value string) ([]gen.T, error)
    
    // update @@table
    //  {{set}}
    //      update_time=now()
    //      {{if name != ""}}
    //          name=@name
    //      {{end}}
    //  {{end}}
    //  {{where}}
    //      id=@id
    //  {{end}}
    UpdateName(name string, id int) (gen.RowsAffected,error)

    // select * from @@table
    //  {{where}}
    //      {{for _,user:=range users}}
    //          {{if user.Age >18}
    //              OR name=@user.Name 
    //         {{end}}
    //      {{end}}
    //  {{end}}
    FindByOrList(users []gen.T) ([]gen.T, error)
}
```

#### Unit Test

Unit test file will be generated if `WithUnitTest` is set, which will generate unit test for general query function.

Unit test for DIY method need diy testcase, which should place in the same package with test file.

A testcase contains input and expectation result, input should match the method arguments, expectation should match method return values, which will be asserted **Equal** in test.

```go
package query

type Input struct {
  Args []interface{}
}

type Expectation struct {
  Ret []interface{}
}

type TestCase struct {
  Input
  Expectation
}

/* Table student */

var StudentFindByIdTestCase = []TestCase {
  {
    Input{[]interface{}{1}},
    Expectation{[]interface{}{nil, nil}},
  },
}
```

Corresponding test

```go
//FindById select * from @@table where id = @id
func (s studentDo) FindById(id int64) (result *model.Student, err error) {
    ///
}

func Test_student_FindById(t *testing.T) {
    student := newStudent(db)
    do := student.WithContext(context.Background()).Debug()

    for i, tt := range StudentFindByIdTestCase {
        t.Run("FindById_"+strconv.Itoa(i), func(t *testing.T) {
            res1, res2 := do.FindById(tt.Input.Args[0].(int64))
            assert(t, "FindById", res1, tt.Expectation.Ret[0])
            assert(t, "FindById", res2, tt.Expectation.Ret[1])
        })
    }
}
```

#### Smart select fields

GEN allows select specific fields with `Select`, if you often use this in your application, maybe you want to define a smaller struct for API usage which can select specific fields automatically, for example:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // hundreds of fields
}

type APIUser struct {
  ID   uint
  Name string
}

type Method interface{
    // select * from user
    FindSome() ([]APIUser, error)
}

apiusers, err := u.WithContext(ctx).Limit(10).FindSome()
// SELECT `id`, `name` FROM `users` LIMIT 10
```

