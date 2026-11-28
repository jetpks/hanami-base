"use client"

import * as React from "react"

import { Link, usePage } from "@inertiajs/react"
import { ActivityIcon, HomeIcon, LayoutTemplateIcon } from "lucide-react"

import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar"
import type { SharedProps } from "@/types"

// The application shell's primary navigation. Flat links — when a project
// grows collapsible groups, `npx shadcn add sidebar-07` re-vendors
// nav-main.tsx (the collapsible variant) from the registry.
const NAV = [
  { title: "Dashboard", url: "/", icon: HomeIcon, exact: true },
  { title: "Ticker", url: "/ticker", icon: ActivityIcon },
]

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const { current_user } = usePage<SharedProps>().props
  const { url } = usePage()

  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" asChild>
              <Link href="/">
                <div className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                  <LayoutTemplateIcon className="size-4" />
                </div>
                <div className="grid flex-1 text-left text-sm leading-tight">
                  <span className="truncate font-semibold">Template</span>
                  <span className="truncate text-xs text-muted-foreground">
                    hanami-base
                  </span>
                </div>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu>
              {NAV.map((item) => (
                <SidebarMenuItem key={item.url}>
                  <SidebarMenuButton
                    asChild
                    tooltip={item.title}
                    isActive={
                      item.exact ? url === item.url : url.startsWith(item.url)
                    }
                  >
                    <Link href={item.url}>
                      <item.icon />
                      <span>{item.title}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      {current_user && (
        <SidebarFooter>
          <NavUser
            user={{
              username: current_user.username,
              avatar_url: current_user.avatar_url,
            }}
          />
        </SidebarFooter>
      )}
      <SidebarRail />
    </Sidebar>
  )
}
