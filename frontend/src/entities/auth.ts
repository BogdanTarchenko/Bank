export interface RegisterRequest {
  email: string
  password: string
  firstName: string
  lastName: string
  phone?: string
  roles?: string[]
}

export interface TokenResponse {
  access_token: string
  refresh_token: string
  token_type: string
  expires_in: number
  scope: string
}

export interface UserInfo {
  sub: string
  email: string
  roles: string[]
  userId: number
}
