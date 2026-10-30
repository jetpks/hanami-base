// Shared inertia props (config/providers/inertia.rb): the auth identity carried
// by the session and the flash bucket. Page-local props live with their pages.
export type FlashData = {
  notice?: string
  alert?: string
}

export type User = {
  id: number
  username: string
  avatar_url: string | null
}

export type SharedProps = {
  current_user: User | null
  flash: FlashData
}
