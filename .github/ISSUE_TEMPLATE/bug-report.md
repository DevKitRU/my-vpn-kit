---
name: Баг / не работает
about: Что-то сломалось, инструкция не прошла, приложение не соединяется
labels: bug
---

## Что не работает

<!-- Кратко опиши симптом. Пример: «Discord Desktop висит на Starting» -->

## На какой платформе

- [ ] Windows 10
- [ ] Windows 11
- [ ] macOS (Intel)
- [ ] macOS (Apple Silicon)
- [ ] iOS (Shadowrocket)

Версия ОС: <!-- winver на Windows / sw_vers на Mac / Настройки→Основные→Об устройстве на iOS -->

## Что пробовал

1. …
2. …

## Логи

<details><summary>Вывод диагностики</summary>

```
# Windows: tools\check-vpn.bat
# или
# Get-Service sing-box
# Get-Content C:\ProgramData\sing-box\logs\sing-box.err.log -Tail 30

# macOS:
# launchctl list | grep singbox
# tail /tmp/singbox.err.log

# сюда вывод
```
</details>

## Какой пресет использовал

- [ ] default (базовый template)
- [ ] dev
- [ ] gaming
- [ ] minimalist
- [ ] свой модифицированный

## Другие VPN-клиенты на системе

<!-- Например: Hiddify, v2rayN, Kaspersky VPN, Cloudflare WARP — они могут конфликтовать. -->
