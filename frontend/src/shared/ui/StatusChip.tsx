import { Chip } from '@mui/material'
import type { ChipProps } from '@mui/material'

const statusConfig: Record<string, { label: string; color: ChipProps['color'] }> = {
  ACTIVE: { label: 'Активный', color: 'success' },
  CLOSED: { label: 'Закрыт', color: 'default' },
  OVERDUE: { label: 'Просрочен', color: 'error' },
  PENDING: { label: 'Ожидает', color: 'warning' },
  PAID: { label: 'Оплачен', color: 'success' },
  DEPOSIT: { label: 'Пополнение', color: 'success' },
  WITHDRAW: { label: 'Снятие', color: 'warning' },
  TRANSFER_IN: { label: 'Входящий', color: 'info' },
  TRANSFER_OUT: { label: 'Исходящий', color: 'secondary' },
}

interface StatusChipProps {
  status: string
  size?: 'small' | 'medium'
}

export function StatusChip({ status, size = 'small' }: StatusChipProps) {
  const config = statusConfig[status] ?? { label: status, color: 'default' as const }
  return <Chip label={config.label} color={config.color} size={size} />
}
