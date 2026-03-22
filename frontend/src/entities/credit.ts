import type { CreditStatus, PaymentStatus } from './common'

export interface CreditResponse {
  id: number
  userId: number
  accountId: number
  tariffId: number
  tariffName: string
  principal: number
  remaining: number
  interestRate: number
  termDays: number
  dailyPayment: number
  status: CreditStatus
  createdAt: string
  closedAt: string | null
}

export interface CreateCreditRequest {
  accountId: number
  tariffId: number
  amount: number
  termDays: number
}

export interface RepayRequest {
  amount: number
}

export interface PaymentResponse {
  id: number
  creditId: number
  amount: number
  status: PaymentStatus
  dueDate: string
  paidAt: string | null
}

export interface TariffResponse {
  id: number
  name: string
  interestRate: number
  minAmount: number | null
  maxAmount: number | null
  minTermDays: number
  maxTermDays: number | null
  active: boolean
  createdAt: string
}

export interface CreateTariffRequest {
  name: string
  interestRate: number
  minAmount?: number
  maxAmount?: number
  minTermDays: number
  maxTermDays?: number
}

export interface CreditRatingResponse {
  userId: number
  score: number
  grade: string
  totalCredits: number
  activeCredits: number
  overduePayments: number
  totalPayments: number
}
