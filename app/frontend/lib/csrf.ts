// The XSRF-TOKEN cookie is set by the inertia middleware from the session CSRF
// token (JS-readable on purpose, never HttpOnly). Plain fetch/form POSTs that
// can't carry Inertia's own CSRF plumbing bridge it back as the X-XSRF-TOKEN
// header, which the same middleware maps onto Hanami's CSRF check before the
// app runs.
export function csrfToken(): string {
  const match = document.cookie.match(/(?:^|;\s*)XSRF-TOKEN=([^;]*)/)
  return match ? decodeURIComponent(match[1]) : ''
}
