import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { AccountResponse, CreateAccountRequest, MoneyOperationRequest } from '@/entities/account'

export const accountApi = {
  async getAccounts(userId?: number, portal: 'client' | 'employee' = 'client'): Promise<AccountResponse[]> {
    const base = endpoints[portal].accounts
    const url = portal === 'employee' && userId ? `${base}?userId=${userId}` : base
    const { data } = await httpClient.get<AccountResponse[]>(url)
    return data
  },

  async getAccount(id: number, portal: 'client' | 'employee' = 'client'): Promise<AccountResponse> {
    const { data } = await httpClient.get<AccountResponse>(endpoints[portal].account(id))
    return data
  },

  async createAccount(request: CreateAccountRequest): Promise<AccountResponse> {
    const { data } = await httpClient.post<AccountResponse>(endpoints.client.accounts, request)
    return data
  },

  async closeAccount(id: number): Promise<void> {
    await httpClient.delete(endpoints.client.account(id))
  },

  async deposit(id: number, request: MoneyOperationRequest): Promise<void> {
    await httpClient.post(endpoints.client.deposit(id), request)
  },

  async withdraw(id: number, request: MoneyOperationRequest): Promise<void> {
    await httpClient.post(endpoints.client.withdraw(id), request)
  },

}
