import { useEffect, useState } from 'react'
import { Head } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import AppLayout from '@/layouts/AppLayout'
import { csrfToken } from '@/lib/csrf'

type Tick = { id: string; n: number }

// The SSE transport's example page, no props needed: a native EventSource
// tails GET /ticker (public feed), and the publish button POSTs via a plain
// fetch — NOT inertia's router: an Inertia POST re-renders the page component,
// which would tear down the EventSource on every publish. The fetch carries
// X-XSRF-TOKEN (the inertia middleware bridges it onto Hanami's CSRF check).
const MAX_TICKS = 50

export default function Index() {
  const [ticks, setTicks] = useState<Tick[]>([])
  const [status, setStatus] = useState('connecting')

  useEffect(() => {
    const source = new EventSource('/ticker')
    // EventSource auto-reconnects on transport errors; onopen flips the line
    // back to live after a reconnect.
    source.onopen = () => setStatus('live')
    source.onerror = () => setStatus('connection lost — retrying')
    source.onmessage = (event) => {
      const data = JSON.parse(event.data) as { n: number }
      setTicks((prev) => [{ id: event.lastEventId, n: data.n }, ...prev].slice(0, MAX_TICKS))
    }
    return () => source.close()
  }, [])

  function sendTick() {
    fetch('/ticker/publish', {
      method: 'POST',
      headers: { 'X-XSRF-TOKEN': csrfToken() },
    }).catch(() => {})
  }

  return (
    <AppLayout>
      <Head title="Ticker" />
      <Card className="max-w-md">
        <CardHeader>
          <CardTitle>Ticker</CardTitle>
          <CardDescription>Live SSE feed from GET /ticker.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-sm text-muted-foreground">
            status: <span className="font-medium text-foreground">{status}</span>
          </p>
          <Button type="button" size="sm" onClick={sendTick}>
            Send tick
          </Button>
          {ticks.length === 0 ? (
            <p className="text-sm text-muted-foreground">No ticks yet — send one.</p>
          ) : (
            <ul className="space-y-1 font-mono text-sm">
              {ticks.map((tick) => (
                <li key={`${tick.id}:${tick.n}`} className="flex items-center justify-between">
                  <span>#{tick.n}</span>
                  <span className="text-xs text-muted-foreground">{tick.id}</span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </AppLayout>
  )
}
