import { createBrowserRouter, Navigate } from 'react-router-dom'
import { Layout } from './Layout'
import { LoginPage } from '@/pages/auth/LoginPage'
import { CallbackPage } from '@/pages/auth/CallbackPage'
import { RegisterPage } from '@/pages/auth/RegisterPage'
import { ClientDashboardPage } from '@/pages/client/DashboardPage'
import { AccountDetailPage } from '@/pages/client/AccountDetailPage'
import { TransferPage } from '@/pages/client/TransferPage'
import { CreditsPage } from '@/pages/client/CreditsPage'
import { CreditDetailPage } from '@/pages/client/CreditDetailPage'
import { NewCreditPage } from '@/pages/client/NewCreditPage'
import { ClientSettingsPage } from '@/pages/client/SettingsPage'
import { EmployeeDashboardPage } from '@/pages/employee/DashboardPage'
import { UsersPage } from '@/pages/employee/UsersPage'
import { UserDetailPage } from '@/pages/employee/UserDetailPage'
import { TariffsPage } from '@/pages/employee/TariffsPage'
import { ClientCreditsPage } from '@/pages/employee/ClientCreditsPage'
import { EmployeeSettingsPage } from '@/pages/employee/SettingsPage'
import { ErrorPage } from '@/pages/ErrorPage'
import { MonitoringPage } from '@/pages/MonitoringPage'
import { ProtectedRoute } from './ProtectedRoute'

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/register',
    element: <RegisterPage />,
  },
  {
    path: '/callback',
    element: <CallbackPage />,
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <Layout />
      </ProtectedRoute>
    ),
    errorElement: <ErrorPage />,
    children: [
      { index: true, element: <Navigate to="/client/dashboard" replace /> },
      {
        path: 'client',
        children: [
          { path: 'dashboard', element: <ClientDashboardPage /> },
          { path: 'accounts/:id', element: <AccountDetailPage /> },
          { path: 'transfers', element: <TransferPage /> },
          { path: 'credits', element: <CreditsPage /> },
          { path: 'credits/new', element: <NewCreditPage /> },
          { path: 'credits/:id', element: <CreditDetailPage /> },
          { path: 'settings', element: <ClientSettingsPage /> },
        ],
      },
      {
        path: 'employee',
        children: [
          { path: 'dashboard', element: <EmployeeDashboardPage /> },
          { path: 'users', element: <UsersPage /> },
          { path: 'users/:id', element: <UserDetailPage /> },
          { path: 'users/:userId/credits', element: <ClientCreditsPage /> },
          { path: 'tariffs', element: <TariffsPage /> },
          { path: 'accounts/:id', element: <AccountDetailPage /> },
          { path: 'settings', element: <EmployeeSettingsPage /> },
        ],
      },
      {
        path: 'monitoring',
        element: <MonitoringPage />,
      },
    ],
  },
  {
    path: '*',
    element: <Navigate to="/" replace />,
  },
])
