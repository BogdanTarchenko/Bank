/**
 * Use-case: Операции со счетами
 * Содержит бизнес-логику получения счетов, создания, пополнения/снятия.
 */
import { accountApi } from '@/api/accountApi'
import { operationApi } from '@/api/operationApi'
import type { AccountResponse, CreateAccountRequest, MoneyOperationRequest } from '@/entities/account'
import type { OperationResponse } from '@/entities/operation'
import type { PageResponse } from '@/entities/common'

/** Загружает счета клиента (userId берётся BFF из JWT) */
export async function fetchClientAccounts(): Promise<AccountResponse[]> {
  return accountApi.getAccounts()
}

/** Загружает счета пользователя для employee-портала */
export async function fetchUserAccounts(userId: number): Promise<AccountResponse[]> {
  return accountApi.getAccounts(userId, 'employee')
}

/** Загружает все счета для employee-портала */
export async function fetchAllAccounts(): Promise<AccountResponse[]> {
  return accountApi.getAccounts(undefined, 'employee')
}

/** Загружает детали счёта */
export async function fetchAccountDetail(
  accountId: number,
  portal: 'client' | 'employee',
): Promise<{ account: AccountResponse; operations: PageResponse<OperationResponse> }> {
  const [account, operations] = await Promise.all([
    accountApi.getAccount(accountId, portal),
    operationApi.getOperations(accountId, 0, 20, portal),
  ])
  return { account, operations }
}

/** Создаёт новый счёт */
export async function createAccount(request: CreateAccountRequest): Promise<AccountResponse> {
  return accountApi.createAccount(request)
}

/** Пополняет счёт */
export async function depositToAccount(accountId: number, request: MoneyOperationRequest): Promise<void> {
  return accountApi.deposit(accountId, request)
}

/** Снимает со счёта */
export async function withdrawFromAccount(accountId: number, request: MoneyOperationRequest): Promise<void> {
  return accountApi.withdraw(accountId, request)
}

/** Закрывает счёт */
export async function closeAccount(accountId: number): Promise<void> {
  return accountApi.closeAccount(accountId)
}

export async function fetchAccount(
  accountId: number,
  portal: 'client' | 'employee',
): Promise<AccountResponse> {
  return accountApi.getAccount(accountId, portal)
}

export async function fetchOperationsPage(
  accountId: number,
  page: number,
  size: number,
  portal: 'client' | 'employee',
): Promise<PageResponse<OperationResponse>> {
  return operationApi.getOperations(accountId, page, size, portal)
}

export function subscribeToOperations(
  accountId: number,
  onOperation: (operation: OperationResponse) => void,
): () => void {
  return operationApi.subscribeToOperations(accountId, onOperation)
}
