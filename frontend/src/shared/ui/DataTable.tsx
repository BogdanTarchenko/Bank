import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  TablePagination,
  Skeleton,
  Box,
} from '@mui/material'
import type { ReactNode } from 'react'
import { EmptyState } from './EmptyState'

interface Column<T> {
  id: string
  label: string
  render: (row: T) => ReactNode
  align?: 'left' | 'center' | 'right'
  minWidth?: number
}

interface DataTableProps<T> {
  columns: Column<T>[]
  rows: T[]
  loading?: boolean
  emptyMessage?: string
  page?: number
  totalCount?: number
  rowsPerPage?: number
  onPageChange?: (page: number) => void
  onRowClick?: (row: T) => void
  getRowKey: (row: T) => string | number
}

export function DataTable<T>({
  columns,
  rows,
  loading = false,
  emptyMessage = 'Нет данных',
  page,
  totalCount,
  rowsPerPage = 20,
  onPageChange,
  onRowClick,
  getRowKey,
}: DataTableProps<T>) {
  if (loading) {
    return (
      <Box>
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} height={52} sx={{ mb: 0.5 }} />
        ))}
      </Box>
    )
  }

  if (rows.length === 0) {
    return <EmptyState title={emptyMessage} />
  }

  return (
    <Paper variant="outlined">
      <TableContainer>
        <Table>
          <TableHead>
            <TableRow>
              {columns.map((col) => (
                <TableCell key={col.id} align={col.align} sx={{ minWidth: col.minWidth, fontWeight: 600 }}>
                  {col.label}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => (
              <TableRow
                key={getRowKey(row)}
                hover
                sx={onRowClick ? { cursor: 'pointer' } : undefined}
                onClick={() => onRowClick?.(row)}
              >
                {columns.map((col) => (
                  <TableCell key={col.id} align={col.align}>
                    {col.render(row)}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      {page !== undefined && totalCount !== undefined && onPageChange && (
        <TablePagination
          component="div"
          count={totalCount}
          page={page}
          rowsPerPage={rowsPerPage}
          rowsPerPageOptions={[rowsPerPage]}
          onPageChange={(_, newPage) => onPageChange(newPage)}
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} из ${count}`}
        />
      )}
    </Paper>
  )
}
