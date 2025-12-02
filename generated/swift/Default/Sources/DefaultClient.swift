
import Foundation

import FirebaseCore
import FirebaseDataConnect
public extension DataConnect {

  static let defaultConnector: DefaultConnector = {
    let dc = DataConnect.dataConnect(connectorConfig: DefaultConnector.connectorConfig, callerSDKType: .generated)
    return DefaultConnector(dataConnect: dc)
  }()

}

public class DefaultConnector {

  let dataConnect: DataConnect

  public static let connectorConfig = ConnectorConfig(serviceId: "hourglass4-main-service", location: "europe-west9", connector: "default")

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect

    // init operations 
    self.createUserMutation = CreateUserMutation(dataConnect: dataConnect)
    self.sendFriendRequestMutation = SendFriendRequestMutation(dataConnect: dataConnect)
    self.acceptFriendRequestMutation = AcceptFriendRequestMutation(dataConnect: dataConnect)
    self.rejectFriendRequestMutation = RejectFriendRequestMutation(dataConnect: dataConnect)
    self.deleteUserByUsernameMutation = DeleteUserByUsernameMutation(dataConnect: dataConnect)
    self.searchUserByUsernameQuery = SearchUserByUsernameQuery(dataConnect: dataConnect)
    self.getPendingFriendRequestsQuery = GetPendingFriendRequestsQuery(dataConnect: dataConnect)
    self.getFriendsQuery = GetFriendsQuery(dataConnect: dataConnect)
    self.listAllUsersQuery = ListAllUsersQuery(dataConnect: dataConnect)
    self.getUserByEmailQuery = GetUserByEmailQuery(dataConnect: dataConnect)
    
  }

  public func useEmulator(host: String = DataConnect.EmulatorDefaults.host, port: Int = DataConnect.EmulatorDefaults.port) {
    self.dataConnect.useEmulator(host: host, port: port)
  }

  // MARK: Operations
public let createUserMutation: CreateUserMutation
public let sendFriendRequestMutation: SendFriendRequestMutation
public let acceptFriendRequestMutation: AcceptFriendRequestMutation
public let rejectFriendRequestMutation: RejectFriendRequestMutation
public let deleteUserByUsernameMutation: DeleteUserByUsernameMutation
public let searchUserByUsernameQuery: SearchUserByUsernameQuery
public let getPendingFriendRequestsQuery: GetPendingFriendRequestsQuery
public let getFriendsQuery: GetFriendsQuery
public let listAllUsersQuery: ListAllUsersQuery
public let getUserByEmailQuery: GetUserByEmailQuery


}
