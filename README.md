# Estudio Nancy Sol

App interna de gestión de obras para el estudio de Nancy Bensignor y Solana Rutenberg.
Reemplaza el Excel `MODELO PRESUPUESTO.xlsx`: obras, presupuestos, caja en pesos y dólares,
proveedores y retiros de las socias.

Nuxt 4 (SPA) + Supabase, deploy en Vercel.

```bash
pnpm install
cp .env.example .env   # completar URL y anon key de Supabase
pnpm dev               # http://localhost:3002
```

Documentación:

| Archivo | Tema |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Reglas, arquitectura, gotchas y estado |
| [docs/modelo-de-datos.md](docs/modelo-de-datos.md) | Tablas, views, reglas contables, retiros |
| [docs/objetivos.md](docs/objetivos.md) | Qué hace la app y de qué parte del Excel sale cada cosa |
| [docs/deploy.md](docs/deploy.md) | Vercel, Supabase, variables, orden al cambiar schema |
| [docs/testing.md](docs/testing.md) | Cómo probar y qué no correr en producción |
| [PRODUCT.md](PRODUCT.md) · [DESIGN.md](DESIGN.md) | Producto y sistema de diseño |
| [docs/historial/](docs/historial/) | Plan inicial, spec y estado de junio 2026 (referencia, no vigente) |
