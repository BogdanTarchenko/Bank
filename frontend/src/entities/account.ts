import type { AccountType, Currency } from './common'

export interface AccountResponse {
  id: number
  userId: number
  currency: Currency
  balance: number
  accountType: AccountType
  isClosed: boolean
  createdAt: string
}

export interface CreateAccountRequest {
  userId: number
  currency: Currency
}

export interface MoneyOperationRequest {
  amount: number
}
