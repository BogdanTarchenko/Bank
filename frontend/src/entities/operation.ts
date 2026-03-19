import type { Currency, OperationType } from './common'

export interface OperationResponse {
  id: number
  accountId: number
  type: OperationType
  amount: number
  currency: Currency
  relatedAccountId: number | null
  exchangeRate: number | null
  description: string | null
  createdAt: string
}
