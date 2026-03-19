export const Currency = {
  USD: 'USD',
  EUR: 'EUR',
  RUB: 'RUB',
  GBP: 'GBP',
} as const
export type Currency = (typeof Currency)[keyof typeof Currency]

export const Role = {
  ADMIN: 'ADMIN',
  EMPLOYEE: 'EMPLOYEE',
  CLIENT: 'CLIENT',
} as const
export type Role = (typeof Role)[keyof typeof Role]

export const Theme = {
  LIGHT: 'LIGHT',
  DARK: 'DARK',
} as const
export type Theme = (typeof Theme)[keyof typeof Theme]

export const AccountType = {
  PERSONAL: 'PERSONAL',
  MASTER: 'MASTER',
} as const
export type AccountType = (typeof AccountType)[keyof typeof AccountType]

export const OperationType = {
  DEPOSIT: 'DEPOSIT',
  WITHDRAW: 'WITHDRAW',
  TRANSFER_IN: 'TRANSFER_IN',
  TRANSFER_OUT: 'TRANSFER_OUT',
} as const
export type OperationType = (typeof OperationType)[keyof typeof OperationType]

export const CreditStatus = {
  ACTIVE: 'ACTIVE',
  CLOSED: 'CLOSED',
  OVERDUE: 'OVERDUE',
} as const
export type CreditStatus = (typeof CreditStatus)[keyof typeof CreditStatus]

export const PaymentStatus = {
  PENDING: 'PENDING',
  PAID: 'PAID',
  OVERDUE: 'OVERDUE',
} as const
export type PaymentStatus = (typeof PaymentStatus)[keyof typeof PaymentStatus]

export interface ErrorResponse {
  status: number
  error: string
  message: string
  timestamp: string
}

export interface PageResponse<T> {
  content: T[]
  totalElements: number
  totalPages: number
  size: number
  number: number
  first: boolean
  last: boolean
}
