import { useState } from 'react'
import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import {
  AppBar,
  Box,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  Divider,
  Avatar,
  Menu,
  MenuItem,
  Chip,
} from '@mui/material'
import MenuIcon from '@mui/icons-material/Menu'
import AccountBalanceIcon from '@mui/icons-material/AccountBalance'
import DashboardIcon from '@mui/icons-material/Dashboard'
import SwapHorizIcon from '@mui/icons-material/SwapHoriz'
import CreditCardIcon from '@mui/icons-material/CreditCard'
import SettingsIcon from '@mui/icons-material/Settings'
import PeopleIcon from '@mui/icons-material/People'
import CategoryIcon from '@mui/icons-material/Category'
import DarkModeIcon from '@mui/icons-material/DarkMode'
import LightModeIcon from '@mui/icons-material/LightMode'
import MonitorHeartIcon from '@mui/icons-material/MonitorHeart'
import { useAuthStore } from '@/store/authStore'
import { useSettingsStore } from '@/store/settingsStore'
import { Theme, Role } from '@/entities/common'
import { performLogout } from '@/usecases/authUseCases'
import { useNotifications } from '@/shared/hooks/useNotifications'

const DRAWER_WIDTH = 260

const clientMenuItems = [
  { label: 'Мои счета', icon: <DashboardIcon />, path: '/client/dashboard' },
  { label: 'Переводы', icon: <SwapHorizIcon />, path: '/client/transfers' },
  { label: 'Кредиты', icon: <CreditCardIcon />, path: '/client/credits' },
  { label: 'Настройки', icon: <SettingsIcon />, path: '/client/settings' },
  { label: 'Мониторинг', icon: <MonitorHeartIcon />, path: '/monitoring' },
]

const employeeMenuItems = [
  { label: 'Все счета', icon: <DashboardIcon />, path: '/employee/dashboard' },
  { label: 'Пользователи', icon: <PeopleIcon />, path: '/employee/users' },
  { label: 'Тарифы', icon: <CategoryIcon />, path: '/employee/tariffs' },
  { label: 'Настройки', icon: <SettingsIcon />, path: '/employee/settings' },
  { label: 'Мониторинг', icon: <MonitorHeartIcon />, path: '/monitoring' },
]

export function Layout() {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null)
  const navigate = useNavigate()
  const location = useLocation()
  const { user, activeRole, setActiveRole, hasRole } = useAuthStore()
  const { theme, setTheme } = useSettingsStore()

  // Initialize push notifications
  useNotifications()

  const menuItems = activeRole === 'employee' ? employeeMenuItems : clientMenuItems
  const canSwitchRole = hasRole(Role.CLIENT) && (hasRole(Role.EMPLOYEE) || hasRole(Role.ADMIN))

  const drawer = (
    <Box>
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
        <AccountBalanceIcon color="primary" sx={{ fontSize: 32 }} />
        <Typography variant="h6" noWrap>
          Банк
        </Typography>
      </Box>
      <Divider />
      <List sx={{ px: 1 }}>
        {menuItems.map((item) => (
          <ListItemButton
            key={item.path}
            selected={location.pathname === item.path}
            onClick={() => {
              navigate(item.path)
              setMobileOpen(false)
            }}
            sx={{ borderRadius: 2, mb: 0.5 }}
          >
            <ListItemIcon>{item.icon}</ListItemIcon>
            <ListItemText primary={item.label} />
          </ListItemButton>
        ))}
      </List>
    </Box>
  )

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
          ml: { sm: `${DRAWER_WIDTH}px` },
          bgcolor: 'background.paper',
          color: 'text.primary',
          boxShadow: 1,
        }}
      >
        <Toolbar>
          <IconButton
            edge="start"
            onClick={() => setMobileOpen(!mobileOpen)}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>

          <Chip
            label={activeRole === 'employee' ? 'Сотрудник' : 'Клиент'}
            color={activeRole === 'employee' ? 'secondary' : 'primary'}
            size="small"
          />

          <Box sx={{ flexGrow: 1 }} />

          <IconButton onClick={() => setTheme(theme === Theme.DARK ? Theme.LIGHT : Theme.DARK)}>
            {theme === Theme.DARK ? <LightModeIcon /> : <DarkModeIcon />}
          </IconButton>

          <IconButton onClick={(e) => setAnchorEl(e.currentTarget)}>
            <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
              {user?.email?.[0]?.toUpperCase() || 'U'}
            </Avatar>
          </IconButton>

          <Menu anchorEl={anchorEl} open={!!anchorEl} onClose={() => setAnchorEl(null)}>
            <MenuItem disabled>
              <Typography variant="body2">{user?.email}</Typography>
            </MenuItem>
            <Divider />
            {canSwitchRole && (
              <MenuItem
                onClick={() => {
                  const newRole = activeRole === 'client' ? 'employee' : 'client'
                  setActiveRole(newRole)
                  navigate(`/${newRole}/dashboard`)
                  setAnchorEl(null)
                }}
              >
                Переключить на {activeRole === 'client' ? 'сотрудника' : 'клиента'}
              </MenuItem>
            )}
            <MenuItem
              onClick={() => {
                setAnchorEl(null)
                performLogout()
              }}
            >
              Выйти
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Box component="nav" sx={{ width: { sm: DRAWER_WIDTH }, flexShrink: { sm: 0 } }}>
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={() => setMobileOpen(false)}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { width: DRAWER_WIDTH },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { width: DRAWER_WIDTH },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
          mt: '64px',
          minHeight: 'calc(100vh - 64px)',
          bgcolor: 'background.default',
        }}
      >
        <Outlet />
      </Box>
    </Box>
  )
}
