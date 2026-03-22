import Foundation
import BankShared

final class UserManagementUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getAllUsers() async throws -> [User] {
        try await client.request(EmployeeUserEndpoint.getAll)
    }

    func getUser(id: Int64) async throws -> User {
        try await client.request(EmployeeUserEndpoint.getById(id))
    }

    func blockUser(id: Int64) async throws -> User {
        try await client.request(EmployeeUserEndpoint.block(id))
    }

    func unblockUser(id: Int64) async throws -> User {
        try await client.request(EmployeeUserEndpoint.unblock(id))
    }

    func updateRoles(id: Int64, roles: Set<UserRole>) async throws -> User {
        let req = UpdateRolesRequest(roles: roles.map(\.rawValue))
        return try await client.request(EmployeeUserEndpoint.updateRoles(id, req))
    }
}
