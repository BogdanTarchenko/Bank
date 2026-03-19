import { Client } from '@stomp/stompjs'
import SockJS from 'sockjs-client'
import type { OperationResponse } from '@/entities/operation'

type OperationCallback = (operation: OperationResponse) => void

let stompClient: Client | null = null
const subscriptions = new Map<string, { unsubscribe: () => void }>()

export function connectWebSocket(bffPort: number = 8084): Client {
  if (stompClient?.connected) {
    return stompClient
  }

  const client = new Client({
    webSocketFactory: () => new SockJS(`http://localhost:${bffPort}/ws/operations`),
    reconnectDelay: 5000,
    heartbeatIncoming: 4000,
    heartbeatOutgoing: 4000,
  })

  stompClient = client
  return client
}

export function subscribeToAccountOperations(
  accountId: number,
  callback: OperationCallback,
): () => void {
  const destination = `/topic/accounts/${accountId}/operations`

  if (!stompClient?.connected) {
    console.warn('WebSocket not connected, subscription will be queued')
    return () => {}
  }

  const existing = subscriptions.get(destination)
  if (existing) {
    existing.unsubscribe()
  }

  const subscription = stompClient.subscribe(destination, (message) => {
    const operation = JSON.parse(message.body) as OperationResponse
    callback(operation)
  })

  subscriptions.set(destination, subscription)

  return () => {
    subscription.unsubscribe()
    subscriptions.delete(destination)
  }
}

export function disconnectWebSocket(): void {
  if (stompClient) {
    subscriptions.forEach((sub) => sub.unsubscribe())
    subscriptions.clear()
    stompClient.deactivate()
    stompClient = null
  }
}

export function getStompClient(): Client | null {
  return stompClient
}
