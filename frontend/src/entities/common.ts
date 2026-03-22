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

export const RoleLabel: Record<string, string> = {
  ADMIN: 'Администратор',
  EMPLOYEE: 'Сотрудник',
  CLIENT: 'Клиент',
  USER: 'Пользователь',
}

export const CurrencyLabel: Record<string, string> = {
  USD: 'Доллар США',
  EUR: 'Евро',
  RUB: 'Рубль',
  GBP: 'Фунт стерлингов',
}

export const AccountTypeLabel: Record<string, string> = {
  PERSONAL: 'Личный',
  MASTER: 'Мастер-счёт',
}

export const CreditStatusLabel: Record<string, string> = {
  ACTIVE: 'Активный',
  CLOSED: 'Закрыт',
  OVERDUE: 'Просрочен',
}

export const PaymentStatusLabel: Record<string, string> = {
  PENDING: 'Ожидает',
  PAID: 'Оплачен',
  OVERDUE: 'Просрочен',
}

export const OperationTypeLabel: Record<string, string> = {
  DEPOSIT: 'Пополнение',
  WITHDRAWAL: 'Снятие',
  TRANSFER_IN: 'Входящий перевод',
  TRANSFER_OUT: 'Исходящий перевод',
}

export const CreditGradeLabel: Record<string, string> = {
  EXCELLENT: 'Отличный',
  GOOD: 'Хороший',
  FAIR: 'Средний',
  POOR: 'Низкий',
  BAD: 'Плохой',
  NO_HISTORY: 'Нет истории',
}

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
  WITHDRAWAL: 'WITHDRAWAL',
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
