# Главная программа

В MBR, за вычетом сигнатуры, доступно 510 байт под код и данные.
Программа большего размера должна быть загружена из следующих за MBR секторов с
помощью программы, размещаемой в MBR.

Номер устройства, с которого загружена MBR, помещается BIOS в регистр `%dl`.

## Функция BIOS для загрузки с диска

Доступ к функционалу BIOS для работы с дисками осуществляется через функции
прерывания `int $0x13`.

Выбор функции осуществляется через регистр `%ah`.
Для чтения секторов используется функция `$0x02` [[1][int13h.2h-1],
[2][int13h.2h-2]].

[int13h.2h-1]: http://www.ablmcc.edu.hk/~scy/CIT/8086_bios_and_dos_interrupts.htm#int13h_02h
[int13h.2h-2]: https://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)

Считанные данные записываются по адресу `%es:%bx`.

Номер устройства (диска): `%dl`.
Номер читающей головки
(_можно интерпретировать как номер поверхности с данными_): `%dh`,
нумерация с 0.
Номер цилиндра: `N[9:8]` = `%cl[7:6]`, `N[7:0]` = `%ch`, нумерация с 0.
(_т.е. два старших бита `%cl` суть старшие биты номера цилиндра_).
Номера сектора: `%cl[5:0]`, нумерация с 1.
Требуемое количество секторов (вплоть до всех секторов дорожки): `%al`.

Флаг `C` означает ошибку.
Число прочитанных секторов: `%al`.

## Пример

Пример состоит из главной программы `main.asm` и загрузчика `loader.asm`.
Код программы находится в секции `.text`, _условно_ неизменяемые данные:
в секции `.rodata`, а инициализированные изначально данные времени выполнения:
в секции `.data`.

_"Неизменяемые" данные (`.rodata`) технически могут быть изменены программой
после загрузки, т.к. real mode не имеет механизмов защиты._
_Т.ч. в данном примере это только условность._

Распределение адресов секций определено в сценарии связывания `main.ld`.
Фактическое размещение данных в ОЗУ выполняет загрузчик.
Для упрощения кода загрузчика секции выровнены по границе сектора
с помощью опций программы `dd`.
_Т.о. загрузчику не требуется вычленять данные разных секций, впритык
упакованные в один сектор._

Т.к. размеры секций и адрес точки входа (`main`) зависят от текста
главной программы, для автоматизации
корректировки загрузчика в течение разработки в систему разработки была
добавлена автоматическая генерация файла `loader-params.h`.

Главная программа выводит в [текстовой буфер VGA][VGATextMode]
разноцветные названия цветов.

[VGATextMode]: https://en.wikipedia.org/wiki/VGA_text_mode
