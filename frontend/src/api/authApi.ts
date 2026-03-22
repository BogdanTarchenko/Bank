import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { RegisterRequest, TokenResponse, UserInfo } from '@/entities/auth'

function generateCodeVerifier(): string {
  const array = new Uint8Array(32)
  crypto.getRandomValues(array)
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(verifier)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

function parseJwt(token: string): Record<string, unknown> {
  const base64Url = token.split('.')[1]
  const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
  const jsonPayload = decodeURIComponent(
    atob(base64)
      .split('')
      .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
      .join(''),
  )
  return JSON.parse(jsonPayload) as Record<string, unknown>
}

function normalizeRoles(roles: string[]): string[] {
  return roles.map((r) => (r === 'USER' ? 'CLIENT' : r))
}

function extractUserInfo(accessToken: string): UserInfo {
  const claims = parseJwt(accessToken)
  const rawRoles = (claims.roles as string[]) ?? (claims.authorities as string[]) ?? []
  return {
    sub: (claims.sub as string) ?? '',
    email: (claims.sub as string) ?? (claims.email as string) ?? '',
    roles: normalizeRoles(rawRoles),
    userId: (claims.userId as number) ?? 0,
  }
}

const CLIENT_ID = 'client-bff'
const CLIENT_SECRET = 'client-bff-secret'
const REDIRECT_URI = `${window.location.origin}/callback`
const SCOPES = 'openid profile accounts.read accounts.write credits.read credits.write'

export const authApi = {
  async register(request: RegisterRequest): Promise<{ message: string }> {
    const { data } = await httpClient.post<{ message: string }>(endpoints.auth.register, request)
    return data
  },

  async startAuthFlow(): Promise<void> {
    const codeVerifier = generateCodeVerifier()
    const codeChallenge = await generateCodeChallenge(codeVerifier)
    const state = crypto.randomUUID()

    sessionStorage.setItem('pkce_code_verifier', codeVerifier)
    sessionStorage.setItem('oauth_state', state)

    const params = new URLSearchParams({
      response_type: 'code',
      client_id: CLIENT_ID,
      redirect_uri: REDIRECT_URI,
      scope: SCOPES,
      state,
      code_challenge: codeChallenge,
      code_challenge_method: 'S256',
    })

    window.location.href = `http://localhost:8081/oauth2/authorize?${params.toString()}`
  },

  async exchangeCode(code: string, state: string): Promise<{ tokenResponse: TokenResponse; userInfo: UserInfo }> {
    const savedState = sessionStorage.getItem('oauth_state')
    if (state !== savedState) {
      throw new Error('Invalid OAuth state')
    }

    const codeVerifier = sessionStorage.getItem('pkce_code_verifier')
    if (!codeVerifier) {
      throw new Error('Missing PKCE code verifier')
    }

    const params = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: REDIRECT_URI,
      client_id: CLIENT_ID,
      code_verifier: codeVerifier,
    })

    const basicAuth = btoa(`${CLIENT_ID}:${CLIENT_SECRET}`)

    const { data } = await httpClient.post<TokenResponse>(endpoints.auth.token, params.toString(), {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${basicAuth}`,
      },
    })

    sessionStorage.removeItem('pkce_code_verifier')
    sessionStorage.removeItem('oauth_state')

    const userInfo = extractUserInfo(data.access_token)

    return { tokenResponse: data, userInfo }
  },
}
