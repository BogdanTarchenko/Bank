import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { CreditResponse, CreateCreditRequest, RepayRequest, PaymentResponse, TariffResponse, CreateTariffRequest, CreditRatingResponse } from '@/entities/credit'

export const creditApi = {
  async getCredits(userId?: number, portal: 'client' | 'employee' = 'client'): Promise<CreditResponse[]> {
    // Client BFF определяет userId из JWT, employee — нужен query param
    const params = portal === 'employee' && userId ? { userId } : undefined
    const { data } = await httpClient.get<CreditResponse[]>(endpoints[portal].credits, { params })
    return data
  },

  async getCredit(id: number, portal: 'client' | 'employee' = 'client'): Promise<CreditResponse> {
    const { data } = await httpClient.get<CreditResponse>(endpoints[portal].credit(id))
    return data
  },

  async createCredit(request: CreateCreditRequest): Promise<CreditResponse> {
    const { data } = await httpClient.post<CreditResponse>(endpoints.client.credits, request)
    return data
  },

  async repayCredit(id: number, request: RepayRequest): Promise<CreditResponse> {
    const { data } = await httpClient.post<CreditResponse>(endpoints.client.creditRepay(id), request)
    return data
  },

  async getPayments(creditId: number, portal: 'client' | 'employee' = 'client'): Promise<PaymentResponse[]> {
    const { data } = await httpClient.get<PaymentResponse[]>(endpoints[portal].creditPayments(creditId))
    return data
  },

  async getTariffs(portal: 'client' | 'employee' = 'client'): Promise<TariffResponse[]> {
    const { data } = await httpClient.get<TariffResponse[]>(endpoints[portal].tariffs)
    return data
  },

  async createTariff(request: CreateTariffRequest): Promise<TariffResponse> {
    const { data } = await httpClient.post<TariffResponse>(endpoints.employee.tariffs, request)
    return data
  },

  async getCreditRating(userId: number, portal: 'client' | 'employee' = 'client'): Promise<CreditRatingResponse> {
    const { data } = await httpClient.get<CreditRatingResponse>(endpoints[portal].creditRating(userId))
    return data
  },
}
