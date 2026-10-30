import { Head, usePage } from '@inertiajs/react'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import AppLayout from '@/layouts/AppLayout'
import type { SharedProps } from '@/types'

// The template's example page: exercises the whole chain — shared props
// (current_user/flash), the vite CSS pipeline, and a components/ui primitive —
// with no domain vocabulary. A minted project starts from here.
export default function Index() {
  const { current_user, flash } = usePage<SharedProps>().props

  return (
    <AppLayout>
      <Head title="Home" />
      <Card className="max-w-md">
        <CardHeader>
          <CardTitle>Hanami Base</CardTitle>
          <CardDescription>Clone-and-go Hanami 3 application template.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-2 text-sm text-muted-foreground">
          {current_user ? (
            <p>
              Signed in as{' '}
              <span className="font-medium text-foreground">{current_user.username}</span>.
            </p>
          ) : (
            <p>Sign in with the GitHub button above to round-trip the auth chain.</p>
          )}
          {flash?.notice && <p className="text-accent-foreground">{flash.notice}</p>}
          {flash?.alert && <p className="text-destructive">{flash.alert}</p>}
        </CardContent>
      </Card>
    </AppLayout>
  )
}
