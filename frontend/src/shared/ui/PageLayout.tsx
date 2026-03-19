import { Box, Typography, Breadcrumbs, Link as MuiLink } from '@mui/material'
import { Link } from 'react-router-dom'
import type { ReactNode } from 'react'

interface Breadcrumb {
  label: string
  href?: string
}

interface PageLayoutProps {
  title: string
  breadcrumbs?: Breadcrumb[]
  action?: ReactNode
  children: ReactNode
}

export function PageLayout({ title, breadcrumbs, action, children }: PageLayoutProps) {
  return (
    <Box sx={{ p: 3 }}>
      {breadcrumbs && breadcrumbs.length > 0 && (
        <Breadcrumbs sx={{ mb: 1 }}>
          {breadcrumbs.map((bc, i) =>
            bc.href ? (
              <MuiLink key={i} component={Link} to={bc.href} underline="hover" color="inherit">
                {bc.label}
              </MuiLink>
            ) : (
              <Typography key={i} color="text.primary">
                {bc.label}
              </Typography>
            ),
          )}
        </Breadcrumbs>
      )}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          {title}
        </Typography>
        {action}
      </Box>
      {children}
    </Box>
  )
}
