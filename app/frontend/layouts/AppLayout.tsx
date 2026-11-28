import { useEffect, useRef } from 'react'
import { usePage } from '@inertiajs/react'
import type { ReactNode } from 'react'
import { LogInIcon } from 'lucide-react'
import { toast } from 'sonner'

import { AppSidebar } from '@/components/app-sidebar'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from '@/components/ui/sidebar'
import { Toaster } from '@/components/ui/sonner'
import { TooltipProvider } from '@/components/ui/tooltip'
import { csrfToken } from '@/lib/csrf'
import type { SharedProps } from '@/types'

// The application shell: collapsible icon sidebar (shadcn sidebar-07, adapted
// to Inertia) + inset header with the hamburger trigger and the anonymous
// sign-in door. SidebarProvider carries the collapsed state; TooltipProvider
// is required by the sidebar's icon tooltips. Flash messages surface as
// toasts (sonner) instead of bare paragraphs above the content.
export default function AppLayout({
  children,
  mainClassName = 'max-w-5xl',
}: {
  children: ReactNode
  // Width of the centered content column; pages narrow/widen it as needed.
  mainClassName?: string
}) {
  const { flash, current_user } = usePage<SharedProps>().props
  const { url } = usePage()

  const pageTitle =
    url === '/'
      ? 'Dashboard'
      : url.startsWith('/ticker')
        ? 'Ticker'
        : 'Template'

  // Fire each flash payload once — the ref guard keeps React StrictMode's
  // dev double-mount from doubling the toast.
  const flashKey = flash?.notice
    ? `notice:${flash.notice}`
    : flash?.alert
      ? `alert:${flash.alert}`
      : null
  const firedRef = useRef<string | null>(null)
  useEffect(() => {
    if (!flashKey || firedRef.current === flashKey) return
    firedRef.current = flashKey
    if (flash?.notice) toast.success(flash.notice)
    else if (flash?.alert) toast.error(flash.alert)
  }, [flashKey, flash?.notice, flash?.alert])

  return (
    <TooltipProvider>
      <SidebarProvider>
        <AppSidebar />
        <SidebarInset>
          <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4 transition-[width,height] group-data-[collapsible=icon]/sidebar-wrapper:h-12 md:gap-3">
            <SidebarTrigger className="-ml-1" />
            <Separator orientation="vertical" className="h-4" />
            <div className="ml-1 hidden text-sm font-medium sm:block">
              {pageTitle}
            </div>
            {!current_user && (
              <div className="ml-auto">
                {/* Native full-page POST — NOT Inertia. The OmniAuth request
                    phase requires POST + CSRF, and the browser must follow
                    the cross-origin 302 to the provider (an Inertia XHR
                    cannot). */}
                <form action="/auth/github" method="post">
                  <input
                    type="hidden"
                    name="authenticity_token"
                    value={csrfToken()}
                  />
                  <Button type="submit" size="sm">
                    <LogInIcon /> Sign in with GitHub
                  </Button>
                </form>
              </div>
            )}
          </header>

          <main className={`mx-auto flex-1 ${mainClassName} px-6 py-6`}>
            {children}
          </main>
        </SidebarInset>
      </SidebarProvider>
      <Toaster />
    </TooltipProvider>
  )
}
