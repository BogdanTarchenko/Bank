/**
 * API Layer — barrel export
 * Все импорты из API слоя должны идти через этот файл.
 * UI-слой НЕ должен импортировать напрямую из network/.
 */
export { ApiError } from '@/network/httpClient'
export { accountApi } from './accountApi'
export { authApi } from './authApi'
export { creditApi } from './creditApi'
export { operationApi } from './operationApi'
export { settingsApi } from './settingsApi'
export { transferApi } from './transferApi'
export { userApi } from './userApi'
