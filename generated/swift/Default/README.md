This Swift package contains the generated Swift code for the connector `default`.

You can use this package by adding it as a local Swift package dependency in your project.

# Accessing the connector

Add the necessary imports

```
import FirebaseDataConnect
import Default

```

The connector can be accessed using the following code:

```
let connector = DataConnect.defaultConnector

```


## Connecting to the local Emulator
By default, the connector will connect to the production service.

To connect to the emulator, you can use the following code, which can be called from the `init` function of your SwiftUI app

```
connector.useEmulator()
```

# Queries

## SearchUserByUsernameQuery
### Variables
#### Required
```swift

let usernameLower: String = ...
```




### Using the Query Reference
```
struct MyView: View {
   var searchUserByUsernameQueryRef = DataConnect.defaultConnector.searchUserByUsernameQuery.ref(...)

  var body: some View {
    VStack {
      if let data = searchUserByUsernameQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await searchUserByUsernameQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.defaultConnector.searchUserByUsernameQuery.execute(...)
```


## GetPendingFriendRequestsQuery
### Variables
#### Required
```swift

let addresseeUsername: String = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getPendingFriendRequestsQueryRef = DataConnect.defaultConnector.getPendingFriendRequestsQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getPendingFriendRequestsQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getPendingFriendRequestsQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.defaultConnector.getPendingFriendRequestsQuery.execute(...)
```


## GetFriendsQuery
### Variables
#### Required
```swift

let username: String = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getFriendsQueryRef = DataConnect.defaultConnector.getFriendsQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getFriendsQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getFriendsQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.defaultConnector.getFriendsQuery.execute(...)
```


## ListAllUsersQuery


### Using the Query Reference
```
struct MyView: View {
   var listAllUsersQueryRef = DataConnect.defaultConnector.listAllUsersQuery.ref(...)

  var body: some View {
    VStack {
      if let data = listAllUsersQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await listAllUsersQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.defaultConnector.listAllUsersQuery.execute(...)
```


## GetUserByEmailQuery
### Variables
#### Required
```swift

let email: String = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getUserByEmailQueryRef = DataConnect.defaultConnector.getUserByEmailQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getUserByEmailQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getUserByEmailQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.defaultConnector.getUserByEmailQuery.execute(...)
```


# Mutations
## CreateUserMutation

### Variables

#### Required
```swift

let username: String = ...
let email: String = ...
let gender: String = ...
let birthDate: LocalDate = ...
let usernameLower: String = ...
```
 

#### Optional
```swift

let displayName: String = ...
```

### One-shot execute
```
DataConnect.defaultConnector.createUserMutation.execute(...)
```

## SendFriendRequestMutation

### Variables

#### Required
```swift

let requesterUsername: String = ...
let addresseeUsername: String = ...
```
 

### One-shot execute
```
DataConnect.defaultConnector.sendFriendRequestMutation.execute(...)
```

## AcceptFriendRequestMutation

### Variables

#### Required
```swift

let requesterUsername: String = ...
let addresseeUsername: String = ...
```
 

### One-shot execute
```
DataConnect.defaultConnector.acceptFriendRequestMutation.execute(...)
```

## RejectFriendRequestMutation

### Variables

#### Required
```swift

let requesterUsername: String = ...
let addresseeUsername: String = ...
```
 

### One-shot execute
```
DataConnect.defaultConnector.rejectFriendRequestMutation.execute(...)
```

## DeleteUserByUsernameMutation

### Variables

#### Required
```swift

let username: String = ...
```
 

### One-shot execute
```
DataConnect.defaultConnector.deleteUserByUsernameMutation.execute(...)
```

