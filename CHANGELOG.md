# Changelog

## 0.1.1 (sin publicar)

- **Errores propios guardados** (Pergamino 5): un error de Lua en un handler ya no llega al jugador como popup; queda en `CentinelaDB.errors` (los últimos 10), se avisa una vez en el chat y `/centinela errores` abre una tarjeta para copiarlo en un issue de GitHub.

## 0.1.0

- Primera versión. Revisa con `issecurevariable` 38 funciones del juego que mueven oro y objetos (correo, comercio, vendedor, bolsas, misiones, bancos, subasta, chat, ajustes, confirmaciones) y dice cuál reemplazó cada addon; nunca acusa.
- Revisión a los 5 s de entrar y cada 10 min; en el chat, solo lo nuevo desde la última vez (hasta tres líneas y "y N más").
- Aviso de oro en correo y comercio por encima de un tope (`/centinela tope N`, 50 por defecto, 0 lo apaga); "No" borra el monto. Un correo con oro mandado sin la ventana se anota en el chat.
- Página de pergamino (piel Pergamino 2), botón de minimapa propio, compartimento de addons, atajo de teclado, idioma elegible (`/centinela idioma es|en|auto`).
- 35 tests en Lua 5.1.
