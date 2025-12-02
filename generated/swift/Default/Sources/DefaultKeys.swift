import Foundation

import FirebaseDataConnect



public struct FriendshipKey {
  
  public private(set) var requesterUsername: String
  
  public private(set) var addresseeUsername: String
  

  enum CodingKeys: String, CodingKey {
    
    case  requesterUsername
    
    case  addresseeUsername
    
  }
}

extension FriendshipKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.requesterUsername = try codecHelper.decode(String.self, forKey: .requesterUsername, container: &container)
    
    self.addresseeUsername = try codecHelper.decode(String.self, forKey: .addresseeUsername, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(requesterUsername, forKey: .requesterUsername, container: &container)
      
      
      
      try codecHelper.encode(addresseeUsername, forKey: .addresseeUsername, container: &container)
      
      
    }
}

extension FriendshipKey : Equatable {
  public static func == (lhs: FriendshipKey, rhs: FriendshipKey) -> Bool {
    
    if lhs.requesterUsername != rhs.requesterUsername {
      return false
    }
    
    if lhs.addresseeUsername != rhs.addresseeUsername {
      return false
    }
    
    return true
  }
}

extension FriendshipKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.requesterUsername)
    
    hasher.combine(self.addresseeUsername)
    
  }
}

extension FriendshipKey : Sendable {}



public struct UserKey {
  
  public private(set) var username: String
  

  enum CodingKeys: String, CodingKey {
    
    case  username
    
  }
}

extension UserKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.username = try codecHelper.decode(String.self, forKey: .username, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(username, forKey: .username, container: &container)
      
      
    }
}

extension UserKey : Equatable {
  public static func == (lhs: UserKey, rhs: UserKey) -> Bool {
    
    if lhs.username != rhs.username {
      return false
    }
    
    return true
  }
}

extension UserKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.username)
    
  }
}

extension UserKey : Sendable {}


