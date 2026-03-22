/**
 * Use-case: Кредиты
 * Содержит бизнес-логику получения кредитов, рейтинга, оформления.
 */
import { creditApi } from '@/api/creditApi'
import type {
  CreditResponse,
  CreateCreditRequest,
  CreateTariffRequest,
  RepayRequest,
  PaymentResponse,
  TariffResponse,
  CreditRatingResponse,
} from '@/entities/credit'

/** Загружает кредиты и рейтинг клиента */
export async function fetchClientCreditsWithRating(
  userId: number | undefined,
): Promise<{ credits: CreditResponse[]; rating: CreditRatingResponse | null }> {
  const [credits, rating] = await Promise.all([
    creditApi.getCredits(),
    userId ? creditApi.getCreditRating(userId).catch(() => null) : Promise.resolve(null),
  ])
  return { credits, rating }
}

/** Загружает кредиты и рейтинг пользователя (employee-портал) */
export async function fetchUserCreditsWithRating(
  userId: number,
): Promise<{ credits: CreditResponse[]; rating: CreditRatingResponse | null }> {
  const [credits, rating] = await Promise.all([
    creditApi.getCredits(userId, 'employee'),
    creditApi.getCreditRating(userId, 'employee').catch(() => null),
  ])
  return { credits, rating }
}

/** Загружает детали кредита с платежами */
export async function fetchCreditDetail(
  creditId: number,
  portal: 'client' | 'employee' = 'client',
): Promise<{ credit: CreditResponse; payments: PaymentResponse[] }> {
  const [credit, payments] = await Promise.all([
    creditApi.getCredit(creditId, portal),
    creditApi.getPayments(creditId, portal),
  ])
  return { credit, payments }
}

/** Оформляет новый кредит */
export async function createCredit(request: CreateCreditRequest): Promise<CreditResponse> {
  return creditApi.createCredit(request)
}

/** Досрочное погашение */
export async function repayCredit(creditId: number, request: RepayRequest): Promise<CreditResponse> {
  return creditApi.repayCredit(creditId, request)
}

/** Загружает доступные тарифы */
export async function fetchTariffs(portal: 'client' | 'employee' = 'client'): Promise<TariffResponse[]> {
  return creditApi.getTariffs(portal)
}

export async function createTariff(request: CreateTariffRequest): Promise<TariffResponse> {
  return creditApi.createTariff(request)
}

export async function fetchCreditPayments(creditId: number, portal: 'client' | 'employee' = 'client'): Promise<PaymentResponse[]> {
  return creditApi.getPayments(creditId, portal)
}
