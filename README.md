# Шаблон репозитория лабораторной работы
Данный репозиторий представляет из себя шаблон репозитория лабораторной работы. 
определение лабораторной работы начинается с файла [learn-metadata.json](./learn-metadata.json)

## Формат файла метаданных learn-metadata.json
Файл является конфигурационным json файлом со следующим набором полей:
* `title` - человекочитаемое наименование лабораторной по умолчанию.
* `materialType` - тип учебного материала. для лабораторных работ = "lab"
* `shortName` - короткое наименование. Должно содержать не более 10 символов [a-z_]
* `description` - короткое описание лабораторной
* `markingScheme` - схема оценки лабораторной работы (для компонента LAB-ASSESSMENT)
* `deploy` - список файлов с определением сценария развертки terraform (для компонента LAB-DEPLOY)
* `assets` - список файлов с изображениями и прочими материалами, которые необходимо загрузить в объектное хранилище
* `text` - текст задания в формате Markdown
* `answerSchema` - jsonSchema определяющая список и формат полей для ответа. Каждый item в словаре `properties` - идентификатор поля ответа. В дополенение введены следующие поля:
    * `title` - человекочитаемое наименование поля или текст вопроса
    * `placeholder` - плейсхолдер отображаемый в поле ответа
* `credentialsSchema` - словарь полей, котоыре будут отображаться в учетных данных. Ключ каждого объекта - идентификатор поля. Значние - словарь состоящий из следующих полей:
    * `title` - Человекочитаемое название поля
    * `source` - источник значения поля. Должен соответствовать названию **output** из сценария развертки (см [output.tf](./deploy/output.tf))
    * `value` - статаческое значние поля. Является взаимоисключающим с `source`.
* `duration` - продолжительность лабораторной в формате ISO8601 duration
* `difficulty` - сложность от 1 до 10
* `tags` - теги с коотрыми связана лабораторная работа
* `skills` - словарь с охватываемым доменами знаний. (пока никак не реализован)

## Формат файла схемы оценки marking-scheme.json
Файл является json файлом со следующим набором полей:
Словарь критериев:
* `id` - индентификатор критерия. Набор букв. Словарь полей критерия:
   * `name` - название критерия;
   * `max_mark` - баллы за критерий;
   * `subCriterions` - словарь саб критериев:
      * `id` - индентификатор саб критерия. Набор цифр. Словарь полей саб критерия:
         * `name` - название саб критерия;
         * `max_mark` - баллы за саб критерий;
         * `aspects` - словарь аспектов:
            * `id` - индентификатор аспекта. Набор цифр. Словарь полей аспекта:
               * `name` - название аспекта;
               * `max_mark` - баллы за аспект;
               * `type` - тип аспекта; типы могут быть `jmespath`,`webrequest`. `jmespath` -  проверка начилия ресурса или свойства ресурса c помощью jmespath и rest api azure. `jmespath` должен содержать словарь `actions`, которые содержат поле `filterForReseachInResourse`. `webrequest` - проверка, доступен ли веб-сайт по оставленной ссылке. `webrequest` должен содержать поле `nameAnswer`, `allresource` - проверка начилия ресурса или свойства ресурса c помощью jmespath из всех ресурсов группы. `allresource` должен содержать словарь `actions`, которые содержат поле `filterForReseachInResourse` 
               * `filterForReseachInResourse` - словарь полей для типа jmespath для поиска ресурса для запроса url = `f"https://management.azure.com/subscriptions/{__cloud53AzureSubscription}/resourceGroups/{resourseGroupName}/providers/{provider}/{client}?api-version={api_verion}"`:
                  * `api_verion` - версия api management azure. Например: `2021-07-01`
                  * `provider` - provider. Например: `Microsoft.Compute`
                  * `client` - client. Например: `virtualMachines`.
                  * `query` - строка для поиска в формате jmespath. Например: `value[?name=='myVM']`
               * `nameAnswer` - имя ответа студента.
               *  `filterForReseachInResourse` - словарь полей для типа allresource для поиска ресурса для запроса url = `f"https://management.azure.com/subscriptions/{__cloud53AzureSubscription}/resourceGroups/{resourseGroupName}/resourses?api-version={api_verion}"`:
                  * `api_verion` - версия api management azure. Например: `2021-07-01`
                  * `query` - строка для поиска в формате jmespath. Например: `value[?starts_with(name,'my-hub-group') && type == 'Microsoft.Devices/IotHubs'].name`

## Формат списка файлов
Списки файлов для загрузки в облачное хранилище определяются как словарь в ключе которого относительная ссылка для загрузки в файловое хранилище, а в значении - полная ссылка на файл. Например:

```json
{
  "./deploy/main.tf": "https://github.com/nsalab-tmn/learn-lab-template/tree/deploy/main.tf?ref=master",
  "./deploy/outputs.tf": "https://github.com/nsalab-tmn/learn-lab-template/tree/deploy/outputs.tf?ref=master",
  "./deploy/policies.tf": "https://github.com/nsalab-tmn/learn-lab-template/tree/deploy/policies.tf?ref=master",
  "./deploy/variables.tf": "https://github.com/nsalab-tmn/learn-lab-template/tree/deploy/variables.tf?ref=master",
}
```


## Реферальные ссылки в файле метаданных
Файл поддерживает реферельные ссылки по стандарту JSON Reference. Чтобы указать значение поля через ссылку, необходимо указать объект с полем `$ref` в значении которого указана ссылка на файл, из которого будет взято содержимое. Ссылки могут быть как относительными (`./assessment/marking-scheme.json`), так и полными (`https://example.org/sample.json`). Таким образом можно определять любые JSON-объекты во внешних файлах и ссылаться на них в файле метаданных. В случае, если содержимое файла по ссылке не удалось распознать как JSON, собержимое буддет интерпретироваться как текст.

Можно так же указывать ссылки на папки. В этом случае будет формироваться словарь файлов в ключе которого будет путь до файла, а в значении - полная ссылка на него.

Для использования ссылок на файлы из GitHub необходимо выделить в ссылке имя ветки репозитория и перенести его в параметр запроса `ref`. Например, если полная ссылка на файл `https://github.com/nsalab-tmn/learn-lab-template/blob/master/deploy/main.tf`, то в метаданных ссылка дожлна быть `https://github.com/nsalab-tmn/learn-lab-template/blob/deploy/main.tf?ref=master`
