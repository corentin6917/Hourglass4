import Foundation

import FirebaseCore
import FirebaseDataConnect




















// MARK: Common Enums

public enum OrderDirection: String, Codable, Sendable {
  case ASC = "ASC"
  case DESC = "DESC"
  }

public enum SearchQueryFormat: String, Codable, Sendable {
  case QUERY = "QUERY"
  case PLAIN = "PLAIN"
  case PHRASE = "PHRASE"
  case ADVANCED = "ADVANCED"
  }


// MARK: Connector Enums

// End enum definitions









public class CreateUserMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "CreateUser"

  public typealias Ref = MutationRef<CreateUserMutation.Data,CreateUserMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
username: String

  
        
        public var
email: String

  
        @OptionalVariable
        public var
displayName: String?

  
        
        public var
gender: String

  
        
        public var
birthDate: LocalDate

  
        
        public var
usernameLower: String


    
    
    
    public init (
        
username: String
,
        
email: String
,
        
gender: String
,
        
birthDate: LocalDate
,
        
usernameLower: String

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.username = username
        self.email = email
        self.gender = gender
        self.birthDate = birthDate
        self.usernameLower = usernameLower
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.username == rhs.username && 
              lhs.email == rhs.email && 
              lhs.displayName == rhs.displayName && 
              lhs.gender == rhs.gender && 
              lhs.birthDate == rhs.birthDate && 
              lhs.usernameLower == rhs.usernameLower
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
  hasher.combine(email)
  
  hasher.combine(displayName)
  
  hasher.combine(gender)
  
  hasher.combine(birthDate)
  
  hasher.combine(usernameLower)
  
}

    enum CodingKeys: String, CodingKey {
      
      case username
      
      case email
      
      case displayName
      
      case gender
      
      case birthDate
      
      case usernameLower
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(username, forKey: .username, container: &container)
      
      
      
      try codecHelper.encode(email, forKey: .email, container: &container)
      
      
      if $displayName.isSet { 
      try codecHelper.encode(displayName, forKey: .displayName, container: &container)
      }
      
      
      try codecHelper.encode(gender, forKey: .gender, container: &container)
      
      
      
      try codecHelper.encode(birthDate, forKey: .birthDate, container: &container)
      
      
      
      try codecHelper.encode(usernameLower, forKey: .usernameLower, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
user_insert: UserKey

  }

  public func ref(
        
username: String
,
email: String
,
gender: String
,
birthDate: LocalDate
,
usernameLower: String

        
        ,
        _ optionalVars: ((inout CreateUserMutation.Variables)->())? = nil
        ) -> MutationRef<CreateUserMutation.Data,CreateUserMutation.Variables>  {
        var variables = CreateUserMutation.Variables(username:username,email:email,gender:gender,birthDate:birthDate,usernameLower:usernameLower)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "CreateUser", variables: variables, resultsDataType:CreateUserMutation.Data.self)
        return ref as MutationRef<CreateUserMutation.Data,CreateUserMutation.Variables>
   }

  @MainActor
   public func execute(
        
username: String
,
email: String
,
gender: String
,
birthDate: LocalDate
,
usernameLower: String

        
        ,
        _ optionalVars: (@MainActor (inout CreateUserMutation.Variables)->())? = nil
        ) async throws -> OperationResult<CreateUserMutation.Data> {
        var variables = CreateUserMutation.Variables(username:username,email:email,gender:gender,birthDate:birthDate,usernameLower:usernameLower)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        
        
        let ref = dataConnect.mutation(name: "CreateUser", variables: variables, resultsDataType:CreateUserMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class SendFriendRequestMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "SendFriendRequest"

  public typealias Ref = MutationRef<SendFriendRequestMutation.Data,SendFriendRequestMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
requesterUsername: String

  
        
        public var
addresseeUsername: String


    
    
    
    public init (
        
requesterUsername: String
,
        
addresseeUsername: String

        
        ) {
        self.requesterUsername = requesterUsername
        self.addresseeUsername = addresseeUsername
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.requesterUsername == rhs.requesterUsername && 
              lhs.addresseeUsername == rhs.addresseeUsername
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(requesterUsername)
  
  hasher.combine(addresseeUsername)
  
}

    enum CodingKeys: String, CodingKey {
      
      case requesterUsername
      
      case addresseeUsername
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(requesterUsername, forKey: .requesterUsername, container: &container)
      
      
      
      try codecHelper.encode(addresseeUsername, forKey: .addresseeUsername, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
friendship_insert: FriendshipKey

  }

  public func ref(
        
requesterUsername: String
,
addresseeUsername: String

        ) -> MutationRef<SendFriendRequestMutation.Data,SendFriendRequestMutation.Variables>  {
        var variables = SendFriendRequestMutation.Variables(requesterUsername:requesterUsername,addresseeUsername:addresseeUsername)
        

        let ref = dataConnect.mutation(name: "SendFriendRequest", variables: variables, resultsDataType:SendFriendRequestMutation.Data.self)
        return ref as MutationRef<SendFriendRequestMutation.Data,SendFriendRequestMutation.Variables>
   }

  @MainActor
   public func execute(
        
requesterUsername: String
,
addresseeUsername: String

        ) async throws -> OperationResult<SendFriendRequestMutation.Data> {
        var variables = SendFriendRequestMutation.Variables(requesterUsername:requesterUsername,addresseeUsername:addresseeUsername)
        
        
        let ref = dataConnect.mutation(name: "SendFriendRequest", variables: variables, resultsDataType:SendFriendRequestMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class AcceptFriendRequestMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "AcceptFriendRequest"

  public typealias Ref = MutationRef<AcceptFriendRequestMutation.Data,AcceptFriendRequestMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
requesterUsername: String

  
        
        public var
addresseeUsername: String


    
    
    
    public init (
        
requesterUsername: String
,
        
addresseeUsername: String

        
        ) {
        self.requesterUsername = requesterUsername
        self.addresseeUsername = addresseeUsername
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.requesterUsername == rhs.requesterUsername && 
              lhs.addresseeUsername == rhs.addresseeUsername
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(requesterUsername)
  
  hasher.combine(addresseeUsername)
  
}

    enum CodingKeys: String, CodingKey {
      
      case requesterUsername
      
      case addresseeUsername
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(requesterUsername, forKey: .requesterUsername, container: &container)
      
      
      
      try codecHelper.encode(addresseeUsername, forKey: .addresseeUsername, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
friendship_update: FriendshipKey?

  }

  public func ref(
        
requesterUsername: String
,
addresseeUsername: String

        ) -> MutationRef<AcceptFriendRequestMutation.Data,AcceptFriendRequestMutation.Variables>  {
        var variables = AcceptFriendRequestMutation.Variables(requesterUsername:requesterUsername,addresseeUsername:addresseeUsername)
        

        let ref = dataConnect.mutation(name: "AcceptFriendRequest", variables: variables, resultsDataType:AcceptFriendRequestMutation.Data.self)
        return ref as MutationRef<AcceptFriendRequestMutation.Data,AcceptFriendRequestMutation.Variables>
   }

  @MainActor
   public func execute(
        
requesterUsername: String
,
addresseeUsername: String

        ) async throws -> OperationResult<AcceptFriendRequestMutation.Data> {
        var variables = AcceptFriendRequestMutation.Variables(requesterUsername:requesterUsername,addresseeUsername:addresseeUsername)
        
        
        let ref = dataConnect.mutation(name: "AcceptFriendRequest", variables: variables, resultsDataType:AcceptFriendRequestMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class RejectFriendRequestMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "RejectFriendRequest"

  public typealias Ref = MutationRef<RejectFriendRequestMutation.Data,RejectFriendRequestMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
requesterUsername: String

  
        
        public var
addresseeUsername: String


    
    
    
    public init (
        
requesterUsername: String
,
        
addresseeUsername: String

        
        ) {
        self.requesterUsername = requesterUsername
        self.addresseeUsername = addresseeUsername
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.requesterUsername == rhs.requesterUsername && 
              lhs.addresseeUsername == rhs.addresseeUsername
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(requesterUsername)
  
  hasher.combine(addresseeUsername)
  
}

    enum CodingKeys: String, CodingKey {
      
      case requesterUsername
      
      case addresseeUsername
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(requesterUsername, forKey: .requesterUsername, container: &container)
      
      
      
      try codecHelper.encode(addresseeUsername, forKey: .addresseeUsername, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
friendship_update: FriendshipKey?

  }

  public func ref(
        
requesterUsername: String
,
addresseeUsername: String

        ) -> MutationRef<RejectFriendRequestMutation.Data,RejectFriendRequestMutation.Variables>  {
        var variables = RejectFriendRequestMutation.Variables(requesterUsername:requesterUsername,addresseeUsername:addresseeUsername)
        

        let ref = dataConnect.mutation(name: "RejectFriendRequest", variables: variables, resultsDataType:RejectFriendRequestMutation.Data.self)
        return ref as MutationRef<RejectFriendRequestMutation.Data,RejectFriendRequestMutation.Variables>
   }

  @MainActor
   public func execute(
        
requesterUsername: String
,
addresseeUsername: String

        ) async throws -> OperationResult<RejectFriendRequestMutation.Data> {
        var variables = RejectFriendRequestMutation.Variables(requesterUsername:requesterUsername,addresseeUsername:addresseeUsername)
        
        
        let ref = dataConnect.mutation(name: "RejectFriendRequest", variables: variables, resultsDataType:RejectFriendRequestMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class DeleteUserByUsernameMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "DeleteUserByUsername"

  public typealias Ref = MutationRef<DeleteUserByUsernameMutation.Data,DeleteUserByUsernameMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
username: String


    
    
    
    public init (
        
username: String

        
        ) {
        self.username = username
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.username == rhs.username
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
}

    enum CodingKeys: String, CodingKey {
      
      case username
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(username, forKey: .username, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
user_delete: UserKey?

  }

  public func ref(
        
username: String

        ) -> MutationRef<DeleteUserByUsernameMutation.Data,DeleteUserByUsernameMutation.Variables>  {
        var variables = DeleteUserByUsernameMutation.Variables(username:username)
        

        let ref = dataConnect.mutation(name: "DeleteUserByUsername", variables: variables, resultsDataType:DeleteUserByUsernameMutation.Data.self)
        return ref as MutationRef<DeleteUserByUsernameMutation.Data,DeleteUserByUsernameMutation.Variables>
   }

  @MainActor
   public func execute(
        
username: String

        ) async throws -> OperationResult<DeleteUserByUsernameMutation.Data> {
        var variables = DeleteUserByUsernameMutation.Variables(username:username)
        
        
        let ref = dataConnect.mutation(name: "DeleteUserByUsername", variables: variables, resultsDataType:DeleteUserByUsernameMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class SearchUserByUsernameQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "SearchUserByUsername"

  public typealias Ref = QueryRefObservation<SearchUserByUsernameQuery.Data,SearchUserByUsernameQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
usernameLower: String


    
    
    
    public init (
        
usernameLower: String

        
        ) {
        self.usernameLower = usernameLower
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.usernameLower == rhs.usernameLower
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(usernameLower)
  
}

    enum CodingKeys: String, CodingKey {
      
      case usernameLower
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(usernameLower, forKey: .usernameLower, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct User: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
username: String



public var 
email: String



public var 
displayName: String?



public var 
gender: String



public var 
birthDate: LocalDate


  
  public var userKey: UserKey {
    return UserKey(
      
      username: username
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
}
public static func == (lhs: User, rhs: User) -> Bool {
    
    return lhs.username == rhs.username 
        
  }

  
  public var id: Self { self }
  

  
  enum CodingKeys: String, CodingKey {
    
    case username
    
    case email
    
    case displayName
    
    case gender
    
    case birthDate
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.username = try codecHelper.decode(String.self, forKey: .username, container: &container)
    
    
    
    self.email = try codecHelper.decode(String.self, forKey: .email, container: &container)
    
    
    
    self.displayName = try codecHelper.decode(String?.self, forKey: .displayName, container: &container)
    
    
    
    self.gender = try codecHelper.decode(String.self, forKey: .gender, container: &container)
    
    
    
    self.birthDate = try codecHelper.decode(LocalDate.self, forKey: .birthDate, container: &container)
    
    
  }
}
public var 
users: [User]

  }

  public func ref(
        
usernameLower: String

        ) -> QueryRefObservation<SearchUserByUsernameQuery.Data,SearchUserByUsernameQuery.Variables>  {
        var variables = SearchUserByUsernameQuery.Variables(usernameLower:usernameLower)
        

        let ref = dataConnect.query(name: "SearchUserByUsername", variables: variables, resultsDataType:SearchUserByUsernameQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<SearchUserByUsernameQuery.Data,SearchUserByUsernameQuery.Variables>
   }

  @MainActor
   public func execute(
        
usernameLower: String

        ) async throws -> OperationResult<SearchUserByUsernameQuery.Data> {
        var variables = SearchUserByUsernameQuery.Variables(usernameLower:usernameLower)
        
        
        let ref = dataConnect.query(name: "SearchUserByUsername", variables: variables, resultsDataType:SearchUserByUsernameQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<SearchUserByUsernameQuery.Data,SearchUserByUsernameQuery.Variables>
        return try await refCast.execute()
        
   }
}






public class GetPendingFriendRequestsQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetPendingFriendRequests"

  public typealias Ref = QueryRefObservation<GetPendingFriendRequestsQuery.Data,GetPendingFriendRequestsQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
addresseeUsername: String


    
    
    
    public init (
        
addresseeUsername: String

        
        ) {
        self.addresseeUsername = addresseeUsername
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.addresseeUsername == rhs.addresseeUsername
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(addresseeUsername)
  
}

    enum CodingKeys: String, CodingKey {
      
      case addresseeUsername
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(addresseeUsername, forKey: .addresseeUsername, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct Friendship: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
requesterUsername: String



public var 
addresseeUsername: String



public var 
status: String



public var 
createdAt: Timestamp





public struct User: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
username: String



public var 
displayName: String?



public var 
email: String


  
  public var userKey: UserKey {
    return UserKey(
      
      username: username
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
}
public static func == (lhs: User, rhs: User) -> Bool {
    
    return lhs.username == rhs.username 
        
  }

  
  public var id: Self { self }
  

  
  enum CodingKeys: String, CodingKey {
    
    case username
    
    case displayName
    
    case email
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.username = try codecHelper.decode(String.self, forKey: .username, container: &container)
    
    
    
    self.displayName = try codecHelper.decode(String?.self, forKey: .displayName, container: &container)
    
    
    
    self.email = try codecHelper.decode(String.self, forKey: .email, container: &container)
    
    
  }
}
public var 
requester: User


  
  public var friendshipKey: FriendshipKey {
    return FriendshipKey(
      
      requesterUsername: requesterUsername,addresseeUsername: addresseeUsername
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(requesterUsername)
  
  hasher.combine(addresseeUsername)
  
}
public static func == (lhs: Friendship, rhs: Friendship) -> Bool {
    
    return lhs.requesterUsername == rhs.requesterUsername  && 
        lhs.addresseeUsername == rhs.addresseeUsername 
        
  }

  
  public var id: Self { self }
  

  
  enum CodingKeys: String, CodingKey {
    
    case requesterUsername
    
    case addresseeUsername
    
    case status
    
    case createdAt
    
    case requester
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.requesterUsername = try codecHelper.decode(String.self, forKey: .requesterUsername, container: &container)
    
    
    
    self.addresseeUsername = try codecHelper.decode(String.self, forKey: .addresseeUsername, container: &container)
    
    
    
    self.status = try codecHelper.decode(String.self, forKey: .status, container: &container)
    
    
    
    self.createdAt = try codecHelper.decode(Timestamp.self, forKey: .createdAt, container: &container)
    
    
    
    self.requester = try codecHelper.decode(User.self, forKey: .requester, container: &container)
    
    
  }
}
public var 
friendships: [Friendship]

  }

  public func ref(
        
addresseeUsername: String

        ) -> QueryRefObservation<GetPendingFriendRequestsQuery.Data,GetPendingFriendRequestsQuery.Variables>  {
        var variables = GetPendingFriendRequestsQuery.Variables(addresseeUsername:addresseeUsername)
        

        let ref = dataConnect.query(name: "GetPendingFriendRequests", variables: variables, resultsDataType:GetPendingFriendRequestsQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetPendingFriendRequestsQuery.Data,GetPendingFriendRequestsQuery.Variables>
   }

  @MainActor
   public func execute(
        
addresseeUsername: String

        ) async throws -> OperationResult<GetPendingFriendRequestsQuery.Data> {
        var variables = GetPendingFriendRequestsQuery.Variables(addresseeUsername:addresseeUsername)
        
        
        let ref = dataConnect.query(name: "GetPendingFriendRequests", variables: variables, resultsDataType:GetPendingFriendRequestsQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetPendingFriendRequestsQuery.Data,GetPendingFriendRequestsQuery.Variables>
        return try await refCast.execute()
        
   }
}






public class GetFriendsQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetFriends"

  public typealias Ref = QueryRefObservation<GetFriendsQuery.Data,GetFriendsQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
username: String


    
    
    
    public init (
        
username: String

        
        ) {
        self.username = username
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.username == rhs.username
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
}

    enum CodingKeys: String, CodingKey {
      
      case username
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(username, forKey: .username, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct Friendship: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
requesterUsername: String



public var 
addresseeUsername: String



public var 
status: String


  
  public var friendshipKey: FriendshipKey {
    return FriendshipKey(
      
      requesterUsername: requesterUsername,addresseeUsername: addresseeUsername
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(requesterUsername)
  
  hasher.combine(addresseeUsername)
  
}
public static func == (lhs: Friendship, rhs: Friendship) -> Bool {
    
    return lhs.requesterUsername == rhs.requesterUsername  && 
        lhs.addresseeUsername == rhs.addresseeUsername 
        
  }

  
  public var id: Self { self }
  

  
  enum CodingKeys: String, CodingKey {
    
    case requesterUsername
    
    case addresseeUsername
    
    case status
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.requesterUsername = try codecHelper.decode(String.self, forKey: .requesterUsername, container: &container)
    
    
    
    self.addresseeUsername = try codecHelper.decode(String.self, forKey: .addresseeUsername, container: &container)
    
    
    
    self.status = try codecHelper.decode(String.self, forKey: .status, container: &container)
    
    
  }
}
public var 
friendships: [Friendship]

  }

  public func ref(
        
username: String

        ) -> QueryRefObservation<GetFriendsQuery.Data,GetFriendsQuery.Variables>  {
        var variables = GetFriendsQuery.Variables(username:username)
        

        let ref = dataConnect.query(name: "GetFriends", variables: variables, resultsDataType:GetFriendsQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetFriendsQuery.Data,GetFriendsQuery.Variables>
   }

  @MainActor
   public func execute(
        
username: String

        ) async throws -> OperationResult<GetFriendsQuery.Data> {
        var variables = GetFriendsQuery.Variables(username:username)
        
        
        let ref = dataConnect.query(name: "GetFriends", variables: variables, resultsDataType:GetFriendsQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetFriendsQuery.Data,GetFriendsQuery.Variables>
        return try await refCast.execute()
        
   }
}






public class ListAllUsersQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "ListAllUsers"

  public typealias Ref = QueryRefObservation<ListAllUsersQuery.Data,ListAllUsersQuery.Variables>

  public struct Variables: OperationVariable {

    
    
  }

  public struct Data: Decodable, Sendable {




public struct User: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
username: String



public var 
usernameLower: String



public var 
email: String


  
  public var userKey: UserKey {
    return UserKey(
      
      username: username
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
}
public static func == (lhs: User, rhs: User) -> Bool {
    
    return lhs.username == rhs.username 
        
  }

  
  public var id: Self { self }
  

  
  enum CodingKeys: String, CodingKey {
    
    case username
    
    case usernameLower
    
    case email
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.username = try codecHelper.decode(String.self, forKey: .username, container: &container)
    
    
    
    self.usernameLower = try codecHelper.decode(String.self, forKey: .usernameLower, container: &container)
    
    
    
    self.email = try codecHelper.decode(String.self, forKey: .email, container: &container)
    
    
  }
}
public var 
users: [User]

  }

  public func ref(
        
        ) -> QueryRefObservation<ListAllUsersQuery.Data,ListAllUsersQuery.Variables>  {
        var variables = ListAllUsersQuery.Variables()
        

        let ref = dataConnect.query(name: "ListAllUsers", variables: variables, resultsDataType:ListAllUsersQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<ListAllUsersQuery.Data,ListAllUsersQuery.Variables>
   }

  @MainActor
   public func execute(
        
        ) async throws -> OperationResult<ListAllUsersQuery.Data> {
        var variables = ListAllUsersQuery.Variables()
        
        
        let ref = dataConnect.query(name: "ListAllUsers", variables: variables, resultsDataType:ListAllUsersQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<ListAllUsersQuery.Data,ListAllUsersQuery.Variables>
        return try await refCast.execute()
        
   }
}






public class GetUserByEmailQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetUserByEmail"

  public typealias Ref = QueryRefObservation<GetUserByEmailQuery.Data,GetUserByEmailQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
email: String


    
    
    
    public init (
        
email: String

        
        ) {
        self.email = email
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.email == rhs.email
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(email)
  
}

    enum CodingKeys: String, CodingKey {
      
      case email
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(email, forKey: .email, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct User: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
username: String



public var 
email: String



public var 
displayName: String?



public var 
gender: String



public var 
birthDate: LocalDate


  
  public var userKey: UserKey {
    return UserKey(
      
      username: username
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(username)
  
}
public static func == (lhs: User, rhs: User) -> Bool {
    
    return lhs.username == rhs.username 
        
  }

  
  public var id: Self { self }
  

  
  enum CodingKeys: String, CodingKey {
    
    case username
    
    case email
    
    case displayName
    
    case gender
    
    case birthDate
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.username = try codecHelper.decode(String.self, forKey: .username, container: &container)
    
    
    
    self.email = try codecHelper.decode(String.self, forKey: .email, container: &container)
    
    
    
    self.displayName = try codecHelper.decode(String?.self, forKey: .displayName, container: &container)
    
    
    
    self.gender = try codecHelper.decode(String.self, forKey: .gender, container: &container)
    
    
    
    self.birthDate = try codecHelper.decode(LocalDate.self, forKey: .birthDate, container: &container)
    
    
  }
}
public var 
users: [User]

  }

  public func ref(
        
email: String

        ) -> QueryRefObservation<GetUserByEmailQuery.Data,GetUserByEmailQuery.Variables>  {
        var variables = GetUserByEmailQuery.Variables(email:email)
        

        let ref = dataConnect.query(name: "GetUserByEmail", variables: variables, resultsDataType:GetUserByEmailQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetUserByEmailQuery.Data,GetUserByEmailQuery.Variables>
   }

  @MainActor
   public func execute(
        
email: String

        ) async throws -> OperationResult<GetUserByEmailQuery.Data> {
        var variables = GetUserByEmailQuery.Variables(email:email)
        
        
        let ref = dataConnect.query(name: "GetUserByEmail", variables: variables, resultsDataType:GetUserByEmailQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetUserByEmailQuery.Data,GetUserByEmailQuery.Variables>
        return try await refCast.execute()
        
   }
}


