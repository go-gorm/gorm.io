---
title: Gen Dynamic SQL
layout: page
---

##### Syntax of template
Method input parameters and return values support basic types (`int`, `string`, `bool`...), struct and placeholders (`gen.T`/`gen.M`/`gen.RowsAffected`), and types support pointers and arrays. The return value is at most a value and an error.

###### placeholder

- `gen.T` represents specified `struct` or `table`
- `gen.M` represents `map[string]interface`
- `gen.RowsAffected` represents SQL executed `rowsAffected` (type:int64)
- `@@table`  represents table's name (if method's parameter doesn't contains variable `table`, GEN will generate `table` from model struct)
- `@@<columnName>` represents column's name or table's name
- `@<name>` represents normal query variable

######  template

Dynamic template logical operations must be wrapped in `{{}}`,and end must used `{{end}}`, All templates support nesting

- `if` Clause
- `where` Clause
- `set` Clause
- `for` Clause
- `...` Coming soon

###### `if` Clause

The `if` clause support `if`/`else if`/`else`,the condition accept a bool parameter or operation expression which conforms to Golang syntax.

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
//      username=@name and
//  {{end}}
//  role="admin"
Method(name string) (gen.T,error)
```

Use case in SQL with complex logic:

```go
// select * from users  
//  {{if user != nil}}
//      {{if user.ID > 0}}
//          where  id=@user.ID
//      {{else if user.Name != ""}}
//          where username=@user.Name
//      {{end}}
//  {{end}}
Method(user *gen.T) (gen.T, error)
```

###### `where` Clause

The `where` clause will be inserted only if the child elements return something. The key word  `and` or `or`  on both sides of clause will be removed.

```
{{where}}
    // do something here
{{end}}
```

Use case in raw SQL

```go
// select * from @@table
//  {{where}}
//      id=@id
//  {{end}}
Method(id int) gen.T
```

Use case in SQL with complex logic:

```go
// select * from @@table
//  {{where}}
//      {{if !start.IsZero()}}
//          created_time > start
//      {{end}}
//      {{if !end.IsZero()}}
//         and created_time < end
//      {{end}} 
//  {{end}}
Method(start,end time.Time) ([]gen.T, error)
```


###### `set` Clause

The `set` clause is used to dynamically update data,it will be inserted only if the child elements return something. The `,` on both sides of columns array will be removed.

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
method(name string,id int) error
```

Use case in SQL with complex logic:

```go
// update @@table 
//  {{set}}
//      {{if user.Name != ""}} username=@user.Name, {{end}}
//      {{if user.Age > 0}} age=@user.Age, {{end}}
//      {{if user.Age >= 18}} is_adult=1 {{else}} is_adult=0 {{end}}
//  {{end}}
// where id=@id
method(user gen.T,id int) (gen.RowsAffected, error)

```
###### `for` Clause

The `for` clause traverses an array according to golang syntax and inserts its contents into SQL,supports array of struct.

```
{{for _,name:=range names}}
    // do something here
{{end}}
```

Use case in raw SQL:

```go
//select * from @@table
//{{where}}
//	{{for _,name:=range names}}
//		name like concat("%",@name,"%") or
//	{{end}}
//{{end}}
Method(names []string) ([]gen.T, error) 
```

Use case in SQL with complex logic:

```go
// select * from @@table 
// {{where}}
//      {{for _,user:=range user}} 
//          {{if user.Name !="" && user.Age >0}}
//              (username = @user.Name AND age=@user.Age) OR
//          {{end}}
//      {{end}}
//  {{end}}
Method(users []model.User) ([]gen.T, error) 
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

