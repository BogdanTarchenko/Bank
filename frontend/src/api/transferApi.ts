import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { TransferRequest } from '@/entities/transfer'

export const transferApi = {
  async transfer(request: TransferRequest): Promise<void> {
    await httpClient.post(endpoints.client.transfers, request)
  },
}
