---
title: Methods Template
layout: page
---

When generating structs from databae, you can also generate methods for them by the way, for example:

```Go
type CommonMethod struct {
    ID   int32
    Name *string
}

func (m *CommonMethod) IsEmpty() bool {
    if m == nil {
        return true
    }
    return m.ID == 0
}

func (m *CommonMethod) GetName() string {
    if m == nil || m.Name == nil {
        return ""
    }
    return *m.Name
}

// Add IsEmpty method to the generated `People` struct
g.GenerateModel("people", gen.WithMethod(CommonMethod{}.IsEmpty))

// Add all methods defined on `CommonMethod` to the generated `User` struct
g.GenerateModel("user", gen.WithMethod(CommonMethod))
```

The generated code looks like:

```go
// Generated Person struct
type Person struct {
  // ...
}

func (m *Person) IsEmpty() bool {
  if m == nil {
    return true
  }
  return m.ID == 0
}


// Generated User struct
type User struct {
  // ...
}

func (m *User) IsEmpty() bool {
  if m == nil {
    return true
  }
  return m.ID == 0
}

func (m *User) GetName() string {
  if m == nil || m.Name == nil {
    return ""
  }
  return *m.Name
}
```
