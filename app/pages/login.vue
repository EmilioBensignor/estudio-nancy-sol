<script setup>
// Login compartido de las dos socias. Pantalla limpia, sin masthead.
definePageMeta({ layout: false })

const { login } = useAuth()

const form = reactive({ email: '', password: '' })
const error = ref('')
const entrando = ref(false)

async function entrar() {
  error.value = ''
  if (!form.email.trim() || !form.password) {
    error.value = 'Completá email y contraseña.'
    return
  }
  entrando.value = true
  try {
    await login(form.email.trim(), form.password)
    navigateTo('/')
  } catch (e) {
    error.value = 'Email o contraseña incorrectos.'
    console.error(e)
    entrando.value = false
  }
}
</script>

<template>
  <div class="login">
    <div class="login__card">
      <div class="login__head">
        <span class="login__monogram" aria-hidden="true">NS</span>
        <h1 class="login__title">Gestión de obras</h1>
        <span class="login__names">Nancy Bensignor · Solana Rutenberg</span>
      </div>

      <form class="login__form" @submit.prevent="entrar">
        <div class="field-group">
          <label class="label">Email</label>
          <input v-model="form.email" type="email" class="field" :class="{ 'field--error': error }" placeholder="estudio@ejemplo.com" autocomplete="username" @input="error = ''" />
        </div>
        <div class="field-group">
          <label class="label">Contraseña</label>
          <input v-model="form.password" type="password" class="field" :class="{ 'field--error': error }" placeholder="••••••••" autocomplete="current-password" @input="error = ''" />
        </div>

        <span v-if="error" class="field-error">{{ error }}</span>

        <button type="submit" class="btn btn--primary login__submit" :disabled="entrando">
          {{ entrando ? 'Entrando…' : 'Entrar' }}
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.login {
  min-height: 100dvh;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 24px;
}
.login__card {
  width: 100%;
  max-width: 380px;
  display: flex;
  flex-direction: column;
  gap: 30px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  padding: 40px 34px 34px;
}
.login__head { display: flex; flex-direction: column; align-items: center; gap: 6px; text-align: center; }
.login__monogram {
  display: grid;
  place-items: center;
  width: 52px;
  height: 52px;
  margin-bottom: 8px;
  background: var(--accent);
  color: #fff;
  border-radius: 14px;
  font-family: var(--font-mono);
  font-size: 19px;
  font-weight: 500;
  letter-spacing: 0.04em;
}
.login__title { font-size: 23px; font-weight: 600; letter-spacing: -0.3px; color: var(--ink); }
.login__names {
  font-size: 13px;
  color: var(--ink-muted);
}
.login__form { display: flex; flex-direction: column; gap: 18px; }
.login__submit { width: 100%; height: 46px; margin-top: 4px; }
</style>
