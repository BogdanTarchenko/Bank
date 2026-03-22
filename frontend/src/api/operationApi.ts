import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import { connectWebSocket, subscribeToAccountOperations, getStompClient } from '@/network/wsClient'
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

  /** Подписывается на real-time обновления операций по счёту. Возвращает функцию отписки. */
  subscribeToOperations(
    accountId: number,
    onOperation: (operation: OperationResponse) => void,
  ): () => void {
    const client = getStompClient() ?? connectWebSocket()
    let unsubscribe: (() => void) | null = null

    const onConnect = () => {
      unsubscribe = subscribeToAccountOperations(accountId, onOperation)
    }

    if (client.connected) {
      onConnect()
    } else {
      client.onConnect = onConnect
      client.activate()
    }

    return () => {
      unsubscribe?.()
    }
  },
}
