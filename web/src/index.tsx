import { Elysia, t } from 'elysia'

new Elysia()
    .get('/', () => 'Hello World')
    .listen('6969')