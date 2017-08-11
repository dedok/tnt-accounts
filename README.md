# Микросервис для банковских выписок
## Структура репозитория
------------------------

* /backend - приложения для СУБД Tarantool
* /t - тесты
* /confs - рекомендуемая конфигурация для NginX

## Установка
------------

### Dev
-------

### Terminal 1
--------------
Запускаем
``` bash
$> docker-compose down
$> docker-compose build
$> docker-docker up
```
### Terminal 2
--------------
Тестируем API.

``` bash
$> ./t/basic_test.py
```
