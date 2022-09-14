---
title: Fields
layout: page
---

### Field Expression

| Field Type | Detail Type           | Create Function               | Supported Query Method                                       |
| ---------- | --------------------- | ------------------------------ | ------------------------------------------------------------ |
| generic    | field                 | NewField                       | IsNull/IsNotNull/Count/Eq/Neq/Gt/Gte/Lt/Lte/Like/Value/Sum/IfNull |
| int        | int/int8/.../int64    | NewInt/NewInt8/.../NewInt64    | Eq/Neq/Gt/Gte/Lt/Lte/In/NotIn/Between/NotBetween/Like/NotLike/Add/Sub/Mul/Div/Mod/FloorDiv/RightShift/LeftShift/BitXor/BitAnd/BitOr/BitFlip/Value/Zero/Sum/IfNull |
| uint       | uint/uint8/.../uint64 | NewUint/NewUint8/.../NewUint64 | same with int                                                |
| float      | float32/float64       | NewFloat32/NewFloat64          | Eq/Neq/Gt/Gte/Lt/Lte/In/NotIn/Between/NotBetween/Like/NotLike/Add/Sub/Mul/Div/FloorDiv/Floor/Value/Zero/Sum/IfNull |
| string     | string/[]byte         | NewString/NewBytes             | Eq/Neq/Gt/Gte/Lt/Lte/Between/NotBetween/In/NotIn/Like/NotLike/Regexp/NotRegxp/FindInSet/FindInSetWith/Value/Zero/IfNull |
| bool       | bool                  | NewBool                        | Not/Is/And/Or/Xor/BitXor/BitAnd/BitOr/Value/Zero |
| time       | time.Time             | NewTime                        | Eq/Neq/Gt/Gte/Lt/Lte/Between/NotBetween/In/NotIn/Add/Sub/Date/DateDiff/DateFormat/Now/CurDate/CurTime/DayName/MonthName/Month/Day/Hour/Minute/Second/MicroSecond/DayOfWeek/DayOfMonth/FromDays/FromUnixtime/Value/Zero/Sum/IfNull |

#### Create Field

Actually, you're not supposed to create a new field variable, cause it will be accomplished in generated code.

Create field examples:

```golang
import "gorm.io/gen/field"

// create a new generic field map to `generic_a`
a := field.NewField("table_name", "generic_a")

// create a field map to `id`
id := field.NewInt("user", "id")

// create a field map to `address`
address := field.NewString("user", "address")

// create a field map to `create_time`
createTime := field.NewTime("user", "create_time")
```

#### Expression

Every field expression has methods suitable for it's type in database as shown in above table. And it can be used like a stream.

##### general field expression

```golang
id := field.NewInt("user", "id")

// `user`.`id` IS NULL
id.IsNull()
// `user`.`id` IS NOT NULL
id.IsNotNull()

// `user`.`id` DESC
id.Desc()

// `user`.`id` AS `user_id`
id.As("user_id")
```

###### int field expression

```golang
id := field.NewInt("user", "id")

// `user`.`id` = 123
id.Eq(123)

// `user`.`id` >= 123
id.Gte(123)

// COUNT(`user`.`id`)
id.Count()

// SUM(`user`.`id`)
id.Sum()

// SUM(`user`.`id`) > 123
id.Sum().Gt(123)

// `user`.`id` <<< 3
id.LeftShift(3)
```

stream call expression

```golang
// ((`user`.`age`+1)*2)/3
u.Age.Add(1).Mul(2).Div(3),
```

###### string field expression

```golang
name := field.NewStirng("user", "name")

// `user`.`name` = "modi"
name.Eq("modi")

// `user`.`name` LIKE %modi%
name.Like("%modi%")

// `user`.`name` REGEXP .*
name.Regexp(".*")

// `user`.`name` FIND_IN_SET(`name`,"modi,jinzhu,zhangqiang")
name.FindInSet("modi,jinzhu,zhangqiang")

// `uesr`.`name` CONCAT("[",name,"]")
name.Concat("[", "]")
```

###### time field expression

```golang
birth := field.NewStirng("user", "birth")

// `user`.`birth` = ? (now)
birth.Eq(time.Now())

// DATE_ADD(`user`.`birth`, INTERVAL ? MICROSECOND)
birth.Add(time.Duration(time.Hour).Microseconds())

// DATE_FORMAT(`user`.`birth`, "%W %M %Y")
birth.DateFormat("%W %M %Y")
```

###### bool field expression

```golang
active := field.NewBool("user", "active")

// `user`.`active` = TRUE
active.Is(true)

// NOT `user`.`active`
active.Not()

// `user`.`active` AND TRUE
active.And(true)
```

#### Column Compare

```golang
id := field.NewInt("user", "id")

// `user`.`id` = `another`.`id`
id.EqCol(anotherID)
```
