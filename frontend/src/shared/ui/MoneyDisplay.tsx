import { Typography } from '@mui/material'
import type { TypographyProps } from '@mui/material'
import type { Currency } from '@/entities/common'
import { formatMoney } from '@/shared/utils/format'

interface MoneyDisplayProps extends Omit<TypographyProps, 'children'> {
  amount: number
  currency: Currency
  showSign?: boolean
}

export function MoneyDisplay({ amount, currency, showSign = false, ...props }: MoneyDisplayProps) {
  const formatted = formatMoney(Math.abs(amount), currency)
  const prefix = showSign ? (amount >= 0 ? '+' : '−') : ''
  const color = showSign ? (amount >= 0 ? 'success.main' : 'error.main') : undefined

  return (
    <Typography color={color} {...props}>
      {prefix}{formatted}
    </Typography>
  )
}
