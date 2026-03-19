import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import type { OperationResponse } from '@/entities/operation'
import type { PageResponse } from '@/entities/common'

export const operationApi = {
  async getOperations(
    accountId: number,
    page: number = 0,
    size: number = 20,
    portal: 'client' | 'employee' = 'client',
  ): Promise<PageResponse<OperationResponse>> {
    const { data } = await httpClient.get<PageResponse<OperationResponse>>(
      endpoints[portal].operations(accountId),
      { params: { page, size } },
    )
    return data
  },
}
