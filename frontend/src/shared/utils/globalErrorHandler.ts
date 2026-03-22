/**
 * Глобальные обработчики ошибок
 * Перехватывает необработанные JS-ошибки и промисы.
 * Гарантирует: ни одна ошибка не пропадёт «тихо».
 */

type ErrorListener = (message: string) => void

let listener: ErrorListener | null = null

/** Регистрирует слушатель для глобальных ошибок (вызывается из App) */
export function setGlobalErrorListener(fn: ErrorListener): void {
  listener = fn
}

/** Инициализирует глобальные обработчики. Вызывать один раз при старте приложения. */
export function initGlobalErrorHandlers(): void {
  window.addEventListener('error', (event: ErrorEvent) => {
    // Игнорируем ошибки загрузки ресурсов (скрипты, стили)
    if (event.target && (event.target as HTMLElement).tagName) return

    console.error('[GlobalError]', event.message, event.error)
    listener?.(`Непредвиденная ошибка: ${event.message}`)
  })

  window.addEventListener('unhandledrejection', (event: PromiseRejectionEvent) => {
    const reason = event.reason

    // ApiError уже обработан в перехватчиках — пропускаем 401 редиректы
    if (reason?.name === 'ApiError' && reason?.status === 401) return

    const message = reason instanceof Error ? reason.message : String(reason)
    console.error('[UnhandledRejection]', reason)
    listener?.(message || 'Произошла непредвиденная ошибка')
  })
}
