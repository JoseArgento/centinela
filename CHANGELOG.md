# Changelog

## 0.3.0 (2026-11-16)

- **El botón ya no queda afuera del botón único de la familia** (Pergamino 8). Con "un solo botón para la familia" elegido en otro addon, uno que mostraba su botón después quedaba afuera (pasó con Taller). La elección ahora se guarda en todos los addons de la familia, así se mantiene con cualquiera que tengas activado (`/centinela minimapa juntar on|off` desde cualquiera), y el botón único recuerda adónde lo arrastraste.

## 0.2.0 (2026-11-07)

- **Botón de minimapa como los del juego** (Pergamino 7): aro dorado biselado, disco oscuro, sombra, ícono crema; `/centinela minimapa juntar on|off` junta todos los addons de la familia en un solo botón con menú. Los errores del botón del minimapa y del compartimento también quedan guardados (`/centinela errores`).
- **Errores propios guardados** (Pergamino 5): un error de Lua en un handler ya no llega al jugador como popup; queda en `CentinelaDB.errors` (los últimos 10), se avisa una vez en el chat y `/centinela errores` abre una tarjeta para copiarlo en un issue de GitHub.

## 0.1.0

- Primera versión. Revisa con `issecurevariable` 38 funciones del juego que mueven oro y objetos (correo, comercio, vendedor, bolsas, misiones, bancos, subasta, chat, ajustes, confirmaciones) y dice cuál reemplazó cada addon; nunca acusa.
- Revisión a los 5 s de entrar y cada 10 min; en el chat, solo lo nuevo desde la última vez (hasta tres líneas y "y N más").
- Aviso de oro en correo y comercio por encima de un tope (`/centinela tope N`, 50 por defecto, 0 lo apaga); "No" borra el monto. Un correo con oro mandado sin la ventana se anota en el chat.
- Página de pergamino (piel Pergamino 2), botón de minimapa propio, compartimento de addons, atajo de teclado, idioma elegible (`/centinela idioma es|en|auto`).
- 35 tests en Lua 5.1.
