import { transferApi } from '@/api/transferApi'
import type { TransferRequest } from '@/entities/transfer'

export async function executeTransfer(request: TransferRequest): Promise<void> {
  return transferApi.transfer(request)
}
