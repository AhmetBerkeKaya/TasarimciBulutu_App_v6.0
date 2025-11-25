import React from 'react'
import ReactDOM from 'react-dom/client'
import { MantineProvider } from '@mantine/core'
import { Notifications } from '@mantine/notifications'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom' // <--- BU SATIR ÖNEMLİ
import App from './App'

// CSS Dosyaları
import '@mantine/core/styles.css';
import '@mantine/notifications/styles.css';
import './index.css'

const queryClient = new QueryClient()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <MantineProvider>
        <Notifications />
        {/* Router Context'i burada başlıyor */}
        <BrowserRouter>
          <App />
        </BrowserRouter>
        {/* Router Context'i burada bitiyor */}
      </MantineProvider>
    </QueryClientProvider>
  </React.StrictMode>,
)