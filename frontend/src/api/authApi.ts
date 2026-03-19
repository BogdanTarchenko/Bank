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

const CLIENT_ID = 'client-bff'
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

    window.location.href = `${endpoints.auth.authorize}?${params.toString()}`
  },

  async exchangeCode(code: string, state: string): Promise<TokenResponse> {
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

    const { data } = await httpClient.post<TokenResponse>(endpoints.auth.token, params.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    })

    sessionStorage.removeItem('pkce_code_verifier')
    sessionStorage.removeItem('oauth_state')

    return data
  },

  async getUserInfo(): Promise<UserInfo> {
    const { data } = await httpClient.get<UserInfo>(endpoints.auth.userinfo)
    return data
  },
}
